import Foundation
import HealthKit
import WatchConnectivity

/// The iPhone side of WatchConnectivity.
///
/// On Start the phone sends ONE command: { tala, bpm, startAt }. Never a
/// message per beat. Two ways to deliver it:
///   - sendMessage: instant, used when the Watch app is reachable.
///   - updateApplicationContext: a "mailbox" holding our latest state, which
///     the Watch reads when its app next runs. This is the fallback.
/// We always keep the mailbox up to date and ring the doorbell (sendMessage)
/// when the Watch is reachable.
final class PhoneConnector: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = PhoneConnector()

    enum WatchStatus {
        case notSupported, notPaired, appNotInstalled, notReachable, connected

        var message: String {
            switch self {
            case .notSupported: return "Apple Watch isn't supported here"
            case .notPaired: return "No Apple Watch paired"
            case .appNotInstalled: return "Install Thalam on your watch"
            case .notReachable: return "Open Thalam on your watch"
            case .connected: return "Watch connected"
            }
        }
    }

    @Published private(set) var status: WatchStatus = .notReachable

    /// Called on the main thread for every command that arrives from the Watch.
    var onCommand: ((ThalamCommand) -> Void)?

    private let healthStore = HKHealthStore()

    func activate() {
        guard WCSession.isSupported() else {
            status = .notSupported
            return
        }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    /// Sends a command the user gave on the iPhone (Start / Stop).
    func send(_ command: ThalamCommand) {
        guard WCSession.isSupported(), WCSession.default.activationState == .activated else { return }
        let session = WCSession.default

        remember(command)  // the mailbox always holds the latest state

        if session.isReachable {
            session.sendMessage(command.dictionary, replyHandler: nil) { error in
                print("sendMessage failed (the mailbox still has it): \(error.localizedDescription)")
            }
        } else if case .start = command, session.isWatchAppInstalled {
            // The Watch app isn't running: wake it up. It then reads the
            // start command from the mailbox and joins in, in step.
            wakeWatchApp()
        }
    }

    /// Puts our latest state in the mailbox without sending a message.
    func remember(_ command: ThalamCommand) {
        guard WCSession.isSupported(), WCSession.default.activationState == .activated else { return }
        do {
            try WCSession.default.updateApplicationContext(command.dictionary)
        } catch {
            print("updateApplicationContext failed: \(error.localizedDescription)")
        }
    }

    /// Launches the Watch app in the background. HealthKit offers this for
    /// workout apps; the Watch receives it in `handle(_ workoutConfiguration:)`.
    private func wakeWatchApp() {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .socialDance
        configuration.locationType = .indoor
        healthStore.startWatchApp(with: configuration) { success, error in
            if !success {
                print("Could not wake the watch app: \(error?.localizedDescription ?? "unknown error")")
            }
        }
    }

    private func handle(_ dictionary: [String: Any]) {
        guard let command = ThalamCommand(dictionary: dictionary) else { return }
        DispatchQueue.main.async {
            self.onCommand?(command)
        }
    }

    /// Works out the text for the watch status row.
    private func refreshStatus() {
        let session = WCSession.default
        let newStatus: WatchStatus
        if session.activationState != .activated || !session.isPaired {
            newStatus = .notPaired
        } else if !session.isWatchAppInstalled {
            newStatus = .appNotInstalled
        } else if session.isReachable {
            newStatus = .connected
        } else {
            newStatus = .notReachable
        }
        DispatchQueue.main.async {
            self.status = newStatus
        }
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        refreshStatus()
        // If the Watch started playing on its own while this app was closed,
        // show it here too.
        if activationState == .activated {
            handle(session.receivedApplicationContext)
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        // Happens when the user switches to a different Apple Watch.
        session.activate()
    }

    func sessionWatchStateDidChange(_ session: WCSession) {
        refreshStatus()
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        refreshStatus()
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        handle(message)
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        handle(applicationContext)
    }
}
