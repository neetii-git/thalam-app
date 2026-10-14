import Foundation
import WatchKit

/// The Watch's beat engine. It runs the beat clock locally and taps the wrist.
///
/// The iPhone only tells it "start Adi at 80 BPM, beat 0 at <startAt>".
/// After that every tap is produced right here on the Watch, so Bluetooth
/// delays can never make a tap late.
final class BeatEngine: ObservableObject {
    static let shared = BeatEngine()

    @Published private(set) var tala: Tala = .adi
    @Published private(set) var bpm: Int = Tempo.defaultBPM
    @Published private(set) var isPlaying = false
    /// Running beat number of the latest tap (0, 1, 2, ...), nil until beat 0.
    @Published private(set) var currentBeat: Int?

    private let scheduler = BeatScheduler()
    private let workout = WorkoutKeeper()

    private init() {
        scheduler.onBeat = { [weak self] beat in
            self?.tap(beat)
        }
    }

    /// Asks for HealthKit permission (needed for the workout session).
    func requestHealthAuthorization() {
        workout.requestAuthorization()
    }

    // MARK: - Buttons on the Watch

    /// Standalone mode: Adi Talam at 80 BPM without the iPhone, in case the
    /// phone link fails. If the phone is listening it follows along.
    func startStandalone() {
        let command = ThalamCommand.start(
            talaID: Tala.adi.id,
            bpm: Tempo.defaultBPM,
            startAt: Date().addingTimeInterval(1.5)
        )
        apply(command)
        WatchConnector.shared.send(command)
    }

    /// Stop pressed on the Watch: stop here and tell the iPhone to stop too.
    func stopFromWatch() {
        apply(.stop)
        WatchConnector.shared.send(.stop)
    }

    /// The iPhone woke this app up to start playing (HKHealthStore.startWatchApp).
    /// Start the workout straight away so watchOS keeps us running while the
    /// start command arrives. If no start comes, end it again after a while.
    func wakeForPhoneStart() {
        workout.begin()
        DispatchQueue.main.asyncAfter(deadline: .now() + 15) { [weak self] in
            guard let self, !self.isPlaying else { return }
            self.workout.end()
        }
    }

    // MARK: - Commands

    /// Applies a start or stop command. Returns true if anything changed.
    /// (Used for buttons on this Watch and for commands from the iPhone.)
    @discardableResult
    func apply(_ command: ThalamCommand) -> Bool {
        switch command {
        case let .start(talaID, bpm, startAt):
            guard !command.isStale, let newTala = Tala.with(id: talaID) else { return false }
            let clock = BeatClock(startAt: startAt, bpm: Tempo.clamped(bpm))

            // The same start can arrive twice (as a message and as the
            // application context). If we are already playing it, carry on.
            if isPlaying && scheduler.clock == clock && tala == newTala { return false }

            tala = newTala
            self.bpm = clock.bpm
            currentBeat = nil
            isPlaying = true
            workout.begin()          // keeps us tapping with the screen off
            scheduler.start(clock)   // taps start at startAt
            return true

        case .stop:
            // A stop while idle (e.g. an old one left in the mailbox) must do
            // nothing, or it would end the workout the phone just woke us with.
            guard isPlaying else { return false }
            scheduler.stop()
            workout.end()
            isPlaying = false
            currentBeat = nil
            return true
        }
    }

    // MARK: - Haptics

    /// Called by the scheduler exactly on each beat.
    private func tap(_ beat: Int) {
        // Haptic first, so nothing (not even a UI update) can delay it.
        WKInterfaceDevice.current().play(tala.kind(ofBeat: beat).haptic)
        currentBeat = beat
    }
}

extension BeatKind {
    /// Each kind of beat feels different on the wrist.
    var haptic: WKHapticType {
        switch self {
        case .sam: return .notification    // strongest
        case .clap: return .directionUp    // medium
        case .count, .wave: return .click  // light
        }
    }
}
