import Foundation
import HealthKit

/// Keeps the Watch app running, and tapping, when the dancer's wrist is down.
///
/// watchOS normally pauses an app as soon as the screen turns off. An active
/// workout session is Apple's official way to keep running in the background
/// (it's what running and dance apps use). We don't record anything into the
/// Health app; we only use the session to stay awake while the tala plays.
final class WorkoutKeeper: NSObject, HKWorkoutSessionDelegate {
    private let healthStore = HKHealthStore()
    private var session: HKWorkoutSession?

    /// Asks the user (once, on first launch) to allow workouts.
    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        healthStore.requestAuthorization(toShare: [HKObjectType.workoutType()], read: nil) { _, error in
            if let error {
                print("HealthKit authorisation failed: \(error.localizedDescription)")
            }
        }
    }

    /// Starts the workout session. Safe to call when one is already running.
    func begin() {
        guard session == nil, HKHealthStore.isHealthDataAvailable() else { return }

        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .socialDance  // Apple's current name for the old `.dance`
        configuration.locationType = .indoor

        do {
            let newSession = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            newSession.delegate = self
            newSession.startActivity(with: Date())
            session = newSession
        } catch {
            print("Could not start workout session: \(error.localizedDescription)")
        }
    }

    /// Ends the workout session (if any), letting watchOS sleep the app again.
    func end() {
        session?.end()
        session = nil
    }

    // MARK: - HKWorkoutSessionDelegate

    func workoutSession(_ workoutSession: HKWorkoutSession,
                        didChangeTo toState: HKWorkoutSessionState,
                        from fromState: HKWorkoutSessionState,
                        date: Date) {
        // Nothing to do: we only need the session to be running.
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("Workout session failed: \(error.localizedDescription)")
        DispatchQueue.main.async {
            if self.session === workoutSession {
                self.session = nil
            }
        }
    }
}
