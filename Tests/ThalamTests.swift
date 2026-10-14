import XCTest

// Tests for the shared code (compiled straight into this test bundle).
// Run on a Mac with:  xcodebuild test -project Thalam.xcodeproj -scheme Thalam \
//                       -destination 'platform=iOS Simulator,name=<any iPhone>'

final class TalaTests: XCTestCase {
    /// The demo: Adi Talam = strong on beat 1, medium on beats 5 and 7, light on the rest.
    func testAdiTalamMatchesTheDemo() {
        let adi = Tala.adi
        XCTAssertEqual(adi.beatCount, 8)
        // People count beats 1...8; the code counts 0...7.
        XCTAssertEqual(adi.kind(ofBeat: 0), .sam)
        XCTAssertEqual(adi.kind(ofBeat: 4), .clap)
        XCTAssertEqual(adi.kind(ofBeat: 6), .clap)
        for beat in [1, 2, 3, 5, 7] {
            XCTAssertTrue([BeatKind.count, .wave].contains(adi.kind(ofBeat: beat)), "beat \(beat + 1) should be light")
        }
        // The cycle repeats: beat 9 is sam again.
        XCTAssertEqual(adi.kind(ofBeat: 8), .sam)
        XCTAssertEqual(adi.positionInCycle(ofBeat: 13), 5)
    }

    func testAllTalas() {
        XCTAssertEqual(Tala.all.map(\.beatCount), [8, 3, 7, 5])
        for tala in Tala.all {
            XCTAssertEqual(tala.pattern.first, .sam, "\(tala.name) must start on sam")
            XCTAssertEqual(tala.pattern.filter { $0 == .sam }.count, 1)
            XCTAssertEqual(Tala.with(id: tala.id), tala)
        }
        XCTAssertEqual(Tala.rupaka.pattern, [.sam, .clap, .count])
        XCTAssertEqual(Tala.misraChapu.pattern, [.sam, .count, .count, .clap, .count, .clap, .count])
        XCTAssertEqual(Tala.khandaChapu.pattern, [.sam, .count, .clap, .clap, .count])
    }

    func testTempoLimits() {
        XCTAssertEqual(Tempo.clamped(10), 40)
        XCTAssertEqual(Tempo.clamped(200), 160)
        XCTAssertEqual(Tempo.clamped(84), 84)
    }
}

final class BeatClockTests: XCTestCase {
    func testBeatTimes() {
        let start = Date(timeIntervalSince1970: 1_000)
        let clock = BeatClock(startAt: start, bpm: 80)
        XCTAssertEqual(clock.secondsPerBeat, 0.75, accuracy: 1e-12)
        // Beat 400 at 80 BPM is exactly 5 minutes later: no drift by construction.
        XCTAssertEqual(clock.time(ofBeat: 400).timeIntervalSince(start), 300, accuracy: 1e-9)

        XCTAssertNil(clock.beatNumber(at: start.addingTimeInterval(-0.1)))
        XCTAssertEqual(clock.beatNumber(at: start), 0)
        XCTAssertEqual(clock.beatNumber(at: start.addingTimeInterval(0.8)), 1)
        XCTAssertEqual(clock.nextBeatNumber(after: start.addingTimeInterval(-5)), 0)
        XCTAssertEqual(clock.nextBeatNumber(after: start.addingTimeInterval(0.8)), 2)
    }
}

final class ThalamCommandTests: XCTestCase {
    func testStartRoundTrip() {
        let startAt = Date(timeIntervalSince1970: 1_800_000_000.25)
        let command = ThalamCommand.start(talaID: "adi", bpm: 80, startAt: startAt)
        XCTAssertEqual(ThalamCommand(dictionary: command.dictionary), command)
    }

    func testStopRoundTrip() {
        XCTAssertEqual(ThalamCommand(dictionary: ThalamCommand.stop.dictionary), .stop)
    }

    func testGarbageIsIgnored() {
        XCTAssertNil(ThalamCommand(dictionary: [:]))
        XCTAssertNil(ThalamCommand(dictionary: ["command": "start", "tala": "adi"]))
    }

    func testOldStartIsStale() {
        XCTAssertTrue(ThalamCommand.start(talaID: "adi", bpm: 80, startAt: Date().addingTimeInterval(-7_200)).isStale)
        XCTAssertFalse(ThalamCommand.start(talaID: "adi", bpm: 80, startAt: Date().addingTimeInterval(1.5)).isStale)
    }
}

final class BeatSchedulerTests: XCTestCase {
    /// Runs the real scheduler for 15 s at 160 BPM and measures how late each beat fires.
    func testBeatsFireOnTimeWithoutDrift() {
        let scheduler = BeatScheduler()
        let clock = BeatClock(startAt: Date().addingTimeInterval(0.5), bpm: 160)
        let beatsToCheck = 40
        var lateness: [TimeInterval] = []
        var beatNumbers: [Int] = []
        let done = expectation(description: "\(beatsToCheck) beats")

        scheduler.onBeat = { beat in
            lateness.append(Date().timeIntervalSince(clock.time(ofBeat: beat)))
            beatNumbers.append(beat)
            if beat == beatsToCheck - 1 { done.fulfill() }
        }
        scheduler.start(clock)
        wait(for: [done], timeout: 30)
        scheduler.stop()

        XCTAssertEqual(beatNumbers, Array(0..<beatsToCheck), "every beat fires once, in order")

        let ms = lateness.map { $0 * 1000 }
        let worst = ms.map(abs).max() ?? 0
        let firstTen = ms.prefix(10).reduce(0, +) / 10
        let lastTen = ms.suffix(10).reduce(0, +) / 10
        print(String(format: "BEAT TIMING: mean %.2f ms, worst %.2f ms, first-10 avg %.2f ms, last-10 avg %.2f ms",
                     ms.reduce(0, +) / Double(ms.count), worst, firstTen, lastTen))

        XCTAssertLessThan(worst, 50, "no beat should be more than 50 ms off (CI machines are noisy)")
        XCTAssertLessThan(abs(lastTen - firstTen), 10, "beats must not drift later over time")
    }

    /// A device that joins after startAt (e.g. watch app opened late) falls straight into step.
    func testJoiningLateFallsIntoStep() {
        let scheduler = BeatScheduler()
        // Started 1.0 s ago at 120 BPM (0.5 s per beat): beats 0, 1, 2 are past, beat 3 is next.
        let clock = BeatClock(startAt: Date().addingTimeInterval(-1.0), bpm: 120)
        var first: (beat: Int, lateness: TimeInterval)?
        let done = expectation(description: "first beat")

        scheduler.onBeat = { beat in
            if first == nil {
                first = (beat, Date().timeIntervalSince(clock.time(ofBeat: beat)))
                done.fulfill()
            }
        }
        scheduler.start(clock)
        wait(for: [done], timeout: 5)
        scheduler.stop()

        XCTAssertEqual(first?.beat, 3)
        XCTAssertLessThan(abs(first?.lateness ?? 1), 0.05)
    }

    func testStopStopsTheBeats() {
        let scheduler = BeatScheduler()
        var count = 0
        scheduler.onBeat = { _ in count += 1 }
        scheduler.start(BeatClock(startAt: Date().addingTimeInterval(0.2), bpm: 160))
        scheduler.stop()
        let quietSecond = expectation(description: "one quiet second")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { quietSecond.fulfill() }
        wait(for: [quietSecond], timeout: 3)
        XCTAssertEqual(count, 0)
        XCTAssertFalse(scheduler.isRunning)
    }
}
