import Foundation

/// The heart of "schedule, don't stream".
///
/// The iPhone sends the watch ONE message: which tala, how fast, and the
/// moment beat 0 happens (`startAt`). From then on both devices work out
/// every beat on their own with the same maths:
///
///     time of beat n = startAt + n * (60 / bpm)
///
/// Nothing is sent per beat, so a slow Bluetooth message can never make a
/// tap late. (iPhone and Watch clocks are kept in sync by the system.)
struct BeatClock: Equatable {
    /// When beat 0 (the first sam) happens.
    let startAt: Date
    /// Beats per minute.
    let bpm: Int

    /// Two clocks are "the same" if their start times agree to within 1 ms.
    /// (A date sent over WatchConnectivity can come back a few nanoseconds off.)
    static func == (a: BeatClock, b: BeatClock) -> Bool {
        a.bpm == b.bpm && abs(a.startAt.timeIntervalSince(b.startAt)) < 0.001
    }

    /// Seconds between two beats. 80 BPM -> 0.75 s.
    var secondsPerBeat: TimeInterval { 60.0 / Double(bpm) }

    /// The exact moment of beat number `n`.
    func time(ofBeat n: Int) -> Date {
        startAt.addingTimeInterval(Double(n) * secondsPerBeat)
    }

    /// The most recent beat at `date`, or nil if the first beat hasn't happened yet.
    func beatNumber(at date: Date) -> Int? {
        let elapsed = date.timeIntervalSince(startAt)
        guard elapsed >= 0 else { return nil }
        return Int(elapsed / secondsPerBeat)
    }

    /// The first beat that is still in the future at `date`.
    /// Lets a device that joins late fall straight into step.
    func nextBeatNumber(after date: Date) -> Int {
        guard let current = beatNumber(at: date) else { return 0 }
        return current + 1
    }
}
