import Foundation
import HealthKit
import UIKit

/// Everything the iPhone screens show and do.
final class PracticeModel: ObservableObject {
    // Choices on the practice screen
    @Published var selectedTala: Tala = .adi
    @Published var bpm: Int = Tempo.defaultBPM
    /// Armband mode: the iPhone also taps the beat itself.
    @Published var tapsOnPhone = false

    // What is playing right now
    @Published private(set) var isPlaying = false
    @Published private(set) var playingTala: Tala = .adi
    @Published private(set) var playingBPM: Int = Tempo.defaultBPM
    /// Running beat number (0, 1, 2, ...), nil until beat 0 arrives.
    @Published private(set) var currentBeat: Int?
    /// Count-in taps left before sam (2, then 1), nil otherwise.
    @Published private(set) var countIn: Int?

    let connector = PhoneConnector.shared
    private let scheduler = BeatScheduler()
    private let phoneHaptics = PhoneHaptics()
    private let healthStore = HKHealthStore()

    init() {
        // The ring uses the SAME startAt maths as the Watch, so it stays in step.
        scheduler.onBeat = { [weak self] beat in
            self?.beat(beat)
        }
        scheduler.onCountIn = { [weak self] left in
            self?.countInTap(left)
        }
        // A command from the Watch (its Stop button, or its standalone Start):
        // apply it, and if it changed anything update our mailbox to match.
        connector.onCommand = { [weak self] command in
            guard let self else { return }
            if self.apply(command) {
                self.connector.remember(command)
            }
        }
        connector.activate()
    }

    // MARK: - Buttons

    func slower() { bpm = Tempo.clamped(bpm - Tempo.step) }
    func faster() { bpm = Tempo.clamped(bpm + Tempo.step) }

    /// Start: the first count-in tap comes 1.5 s from now, giving the message
    /// time to reach the Watch; sam follows two beats later. Both devices
    /// count beats from that same startAt.
    func start() {
        let command = ThalamCommand.start(
            talaID: selectedTala.id,
            bpm: bpm,
            startAt: BeatClock.startAt(forStartPressedAt: Date(), bpm: bpm)
        )
        apply(command)
        connector.send(command)
    }

    func stop() {
        apply(.stop)
        connector.send(.stop)
    }

    /// First launch: ask for HealthKit permission (workouts). The Watch needs
    /// it for its workout session; the iPhone uses it to wake the Watch app.
    func requestHealthAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        healthStore.requestAuthorization(toShare: [HKObjectType.workoutType()], read: nil) { _, error in
            if let error {
                print("HealthKit authorisation failed: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Commands

    /// Applies a start or stop command (from this phone or from the Watch).
    /// Returns true if anything changed.
    @discardableResult
    func apply(_ command: ThalamCommand) -> Bool {
        switch command {
        case let .start(talaID, bpm, startAt):
            guard !command.isStale, let tala = Tala.with(id: talaID) else { return false }
            let clock = BeatClock(startAt: startAt, bpm: Tempo.clamped(bpm))
            if isPlaying && scheduler.clock == clock && playingTala == tala { return false }

            playingTala = tala
            playingBPM = clock.bpm
            selectedTala = tala
            self.bpm = clock.bpm
            currentBeat = nil
            countIn = nil
            isPlaying = true
            UIApplication.shared.isIdleTimerDisabled = true  // keep the ring on screen
            if tapsOnPhone { phoneHaptics.prepare() }
            scheduler.start(clock, countIn: BeatClock.countInBeats)
            return true

        case .stop:
            guard isPlaying else { return false }
            scheduler.stop()
            phoneHaptics.stop()
            isPlaying = false
            currentBeat = nil
            countIn = nil
            UIApplication.shared.isIdleTimerDisabled = false
            return true
        }
    }

    /// Called by the scheduler exactly on each beat.
    private func beat(_ beat: Int) {
        if tapsOnPhone {
            phoneHaptics.play(playingTala.kind(ofBeat: beat))
        }
        countIn = nil
        currentBeat = beat
    }

    /// Called for each "get ready" tap before sam.
    private func countInTap(_ left: Int) {
        if tapsOnPhone {
            phoneHaptics.playCountIn()
        }
        countIn = left
    }
}
