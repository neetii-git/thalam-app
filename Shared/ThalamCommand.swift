import Foundation

/// The only two things the iPhone and the Watch ever say to each other.
///
///   start -> { command: "start", tala: "adi", bpm: 80, startAt: <time> }
///   stop  -> { command: "stop" }
///
/// Either device can send either command, which is how Stop on either
/// device stops both. Note there is no "beat" message: see BeatClock.
enum ThalamCommand: Equatable {
    case start(talaID: String, bpm: Int, startAt: Date)
    case stop

    /// Dictionary keys. WatchConnectivity only carries property-list types
    /// (String, Int, Double, ...), so dates travel as seconds since 1970.
    enum Key {
        static let command = "command"
        static let tala = "tala"
        static let bpm = "bpm"
        static let startAt = "startAt"
        /// Makes every dictionary unique, so updateApplicationContext never
        /// skips a command because it looks the same as the previous one.
        static let sentAt = "sentAt"
    }

    /// Converts the command into a dictionary for WatchConnectivity.
    var dictionary: [String: Any] {
        let sentAt = Date().timeIntervalSince1970
        switch self {
        case let .start(talaID, bpm, startAt):
            return [
                Key.command: "start",
                Key.tala: talaID,
                Key.bpm: bpm,
                Key.startAt: startAt.timeIntervalSince1970,
                Key.sentAt: sentAt,
            ]
        case .stop:
            return [Key.command: "stop", Key.sentAt: sentAt]
        }
    }

    /// Reads a command back out of a received dictionary.
    init?(dictionary: [String: Any]) {
        switch dictionary[Key.command] as? String {
        case "start":
            guard let talaID = dictionary[Key.tala] as? String,
                  let bpm = dictionary[Key.bpm] as? Int,
                  let startAt = dictionary[Key.startAt] as? Double
            else { return nil }
            self = .start(talaID: talaID, bpm: bpm, startAt: Date(timeIntervalSince1970: startAt))
        case "stop":
            self = .stop
        default:
            return nil
        }
    }

    /// A start command from long ago (e.g. an old application context left
    /// behind after the phone app was closed) should not start the taps again.
    var isStale: Bool {
        guard case let .start(_, _, startAt) = self else { return false }
        return Date().timeIntervalSince(startAt) > 60 * 60
    }
}
