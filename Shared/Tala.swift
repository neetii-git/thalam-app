import Foundation

// MARK: - Beat kinds

/// One beat inside a tala cycle. Each kind is felt differently on the wrist.
///
///   sam   -> beat 1 of the cycle, the strongest tap
///   clap  -> medium tap
///   count -> light tap (finger counts)
///   wave  -> light tap (hand wave)
enum BeatKind: String {
    case sam
    case clap
    case count
    case wave

    /// The word shown on screen for this beat.
    var label: String {
        switch self {
        case .sam: return "Sam"
        case .clap: return "Clap"
        case .count: return "count"
        case .wave: return "wave"
        }
    }

    /// Parses one letter of a pattern string: S = sam, C = clap, c = count, w = wave.
    init?(letter: Character) {
        switch letter {
        case "S": self = .sam
        case "C": self = .clap
        case "c": self = .count
        case "w": self = .wave
        default: return nil
        }
    }
}

// MARK: - Talas

/// A tala (rhythmic cycle): a name plus the pattern of beat kinds that repeats.
struct Tala: Identifiable, Hashable {
    /// Short stable key that is sent between iPhone and Watch, e.g. "adi".
    let id: String
    /// Name shown in the UI, e.g. "Adi Talam".
    let name: String
    /// One BeatKind per beat of the cycle.
    let pattern: [BeatKind]

    /// Number of beats in one cycle.
    var beatCount: Int { pattern.count }

    /// Beat numbers count up forever (0, 1, 2, ...). These helpers fold
    /// such a running beat number back into the cycle.
    func positionInCycle(ofBeat beatNumber: Int) -> Int {
        beatNumber % beatCount
    }

    func kind(ofBeat beatNumber: Int) -> BeatKind {
        pattern[positionInCycle(ofBeat: beatNumber)]
    }

    /// Builds a tala from a readable pattern like "S c c c C w C w".
    init(id: String, name: String, pattern: String) {
        self.id = id
        self.name = name
        self.pattern = pattern.compactMap { BeatKind(letter: $0) }
    }

    // The four talas the app offers (S = sam, C = clap, c = count, w = wave).
    static let adi = Tala(id: "adi", name: "Adi Talam", pattern: "S c c c C w C w")
    static let rupaka = Tala(id: "rupaka", name: "Rupaka Talam", pattern: "S C c")
    static let misraChapu = Tala(id: "misra", name: "Misra Chapu", pattern: "S c c C c C c")
    static let khandaChapu = Tala(id: "khanda", name: "Khanda Chapu", pattern: "S c C C c")

    static let all: [Tala] = [.adi, .rupaka, .misraChapu, .khandaChapu]

    /// Looks a tala up by the id that travels over WatchConnectivity.
    static func with(id: String) -> Tala? {
        all.first { $0.id == id }
    }
}

// MARK: - Tempo

/// Tempo limits shared by both apps.
enum Tempo {
    static let minBPM = 40
    static let maxBPM = 160
    static let defaultBPM = 80
    /// How much one tap on - or + changes the tempo.
    static let step = 4

    /// Keeps a tempo inside the allowed range.
    static func clamped(_ bpm: Int) -> Int {
        min(max(bpm, minBPM), maxBPM)
    }
}
