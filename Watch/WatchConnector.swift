import Foundation
import WatchConnectivity

/// The Watch side of WatchConnectivity.
///
/// Two ways to talk to the iPhone:
///   - sendMessage: instant, but only works while the other app is reachable.
///   - updateApplicationContext: a "mailbox" holding our latest state. It is
///     delivered whenever the other app next runs, even if it is closed now.
/// We always keep the mailbox up to date and ring the doorbell (sendMessage)
/// when the phone is reachable.
final class WatchConnector: NSObject, WCSessionDelegate {
    static let shared = WatchConnector()

    /// Called on the main thread for every command that arrives from the iPhone.
    var onCommand: ((ThalamCommand) -> Void)?

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    /// Sends a command the user gave on the Watch (Start standalone / Stop).
    func send(_ command: ThalamCommand) {
        guard WCSession.default.activationState == .activated else { return }
        remember(command)
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(command.dictionary, replyHandler: nil) { error in
                print("sendMessage failed (the mailbox still has it): \(error.localizedDescription)")
            }
        }
    }

    /// Puts our latest state in the mailbox without sending a message.
    func remember(_ command: ThalamCommand) {
        guard WCSession.default.activationState == .activated else { return }
        do {
            try WCSession.default.updateApplicationContext(command.dictionary)
        } catch {
            print("updateApplicationContext failed: \(error.localizedDescription)")
        }
    }

    /// Re-reads the last command the iPhone left in the mailbox.
    func applyLatestContext() {
        guard WCSession.default.activationState == .activated else { return }
        handleContext(WCSession.default.receivedApplicationContext)
    }

    /// The mailbox only holds the other device's LATEST state, but that can
    /// still be older than ours (e.g. an old "start" from before we pressed
    /// Stop). Only act on it if it was sent after our own latest state.
    private func handleContext(_ context: [String: Any]) {
        let theirs = context[ThalamCommand.Key.sentAt] as? Double ?? 0
        let mine = WCSession.default.applicationContext[ThalamCommand.Key.sentAt] as? Double ?? 0
        guard theirs > mine else { return }
        handle(context)
    }

    private func handle(_ dictionary: [String: Any]) {
        guard let command = ThalamCommand(dictionary: dictionary) else { return }
        // WatchConnectivity calls us on a background queue; the engine lives on main.
        DispatchQueue.main.async {
            self.onCommand?(command)
        }
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        // If the iPhone pressed Start while this app was closed, the start
        // command is waiting in the mailbox: join in, in step.
        if activationState == .activated {
            handleContext(session.receivedApplicationContext)
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        handle(message)
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        handleContext(applicationContext)
    }
}
