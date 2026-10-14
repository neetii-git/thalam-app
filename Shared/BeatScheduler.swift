import Foundation

/// Calls `onBeat` exactly on every beat of a `BeatClock`.
///
/// Why not a repeating Timer? A repeating timer is a little late every time
/// and those small errors add up, so after a few minutes the taps would drift.
/// Instead, before each beat we compute that beat's exact time from `startAt`
/// (see BeatClock) and set a one-shot timer for that moment. Every beat is
/// measured from the same starting point, so errors never pile up.
///
/// The Watch uses this to fire haptics; the iPhone uses it to move the ring.
final class BeatScheduler {
    /// Called on the main thread with the running beat number (0, 1, 2, ...).
    var onBeat: ((Int) -> Void)?

    private(set) var clock: BeatClock?
    private var nextBeat = 0
    private var timer: DispatchSourceTimer?

    /// A beat we notice more than this late is skipped instead of played
    /// (for example if the app was paused for a moment). For a dancer a
    /// late tap is worse than a missing one.
    private let maxLateness: TimeInterval = 0.1

    var isRunning: Bool { clock != nil }

    func start(_ clock: BeatClock) {
        stop()
        self.clock = clock
        // Normally this is beat 0. If we join after startAt (e.g. the watch app
        // opened late) we skip ahead to the next beat and are instantly in step.
        nextBeat = clock.nextBeatNumber(after: Date())

        // A GCD timer on the main queue. `.strict` asks the system not to
        // bunch it together with other timers to save power.
        let timer = DispatchSource.makeTimerSource(flags: .strict, queue: .main)
        timer.setEventHandler { [weak self] in
            self?.timerFired()
        }
        self.timer = timer
        scheduleTimerForNextBeat()
        timer.resume()
    }

    func stop() {
        timer?.cancel()
        timer = nil
        clock = nil
    }

    deinit {
        timer?.cancel()
    }

    // MARK: - Private

    /// Arms the one-shot timer for the absolute time of `nextBeat`.
    private func scheduleTimerForNextBeat() {
        guard let clock, let timer else { return }
        let secondsFromNow = max(0, clock.time(ofBeat: nextBeat).timeIntervalSinceNow)
        // Wall-clock deadline, because BeatClock works in wall-clock `Date`s.
        timer.schedule(wallDeadline: .now() + secondsFromNow, leeway: .milliseconds(1))
    }

    private func timerFired() {
        guard let clock else { return }
        let now = Date()
        let lateness = now.timeIntervalSince(clock.time(ofBeat: nextBeat))

        if lateness < -0.002 {
            // Woke up a little early: wait again for the same beat.
            scheduleTimerForNextBeat()
            return
        }

        if lateness <= maxLateness {
            onBeat?(nextBeat)
        }

        // Move on to the next beat that is still ahead of us.
        nextBeat = max(nextBeat + 1, clock.nextBeatNumber(after: now))
        scheduleTimerForNextBeat()
    }
}
