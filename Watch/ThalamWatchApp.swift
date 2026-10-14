import SwiftUI
import WatchKit
import HealthKit

@main
struct ThalamWatchApp: App {
    @WKApplicationDelegateAdaptor(WatchAppDelegate.self) private var appDelegate
    @StateObject private var engine = BeatEngine.shared

    var body: some Scene {
        WindowGroup {
            WatchRootView()
                .environmentObject(engine)
        }
    }
}

/// App lifecycle hooks: wire the iPhone link to the beat engine.
final class WatchAppDelegate: NSObject, WKApplicationDelegate {
    func applicationDidFinishLaunching() {
        let engine = BeatEngine.shared
        let connector = WatchConnector.shared

        // A command from the iPhone: apply it, and if it changed anything
        // update our own mailbox too, so both devices agree on the state.
        connector.onCommand = { command in
            if engine.apply(command) {
                connector.remember(command)
            }
        }
        connector.activate()

        // First launch: ask for permission to run a workout session.
        engine.requestHealthAuthorization()
    }

    /// Called when the iPhone pressed Start while this app wasn't running
    /// (the phone calls HKHealthStore.startWatchApp to wake us up).
    func handle(_ workoutConfiguration: HKWorkoutConfiguration) {
        BeatEngine.shared.wakeForPhoneStart()
        WatchConnector.shared.applyLatestContext()
    }
}
