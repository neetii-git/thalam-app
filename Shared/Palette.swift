import SwiftUI

/// Traditional Indian palette used by both apps (instead of default iOS blue).
extension Color {
    /// Ivory - main background on the iPhone.
    static let ivory = Color(hex: 0xFBF3E4)
    /// Kumkum red - primary colour (buttons, selected tala).
    static let kumkum = Color(hex: 0xA3171E)
    /// Turmeric - sam and highlights.
    static let turmeric = Color(hex: 0xE3A21A)
    /// Temple gold - thin borders.
    static let templeGold = Color(hex: 0xC08A2B)
    /// Peacock teal - "connected" status.
    static let peacock = Color(hex: 0x0F5257)
    /// Maroon - text on ivory, background on the Watch.
    static let maroon = Color(hex: 0x3B0A0E)
    /// Coral - clap beats.
    static let coral = Color(hex: 0xF08A7E)

    /// Makes a colour from a hex number like 0xA3171E.
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

extension BeatKind {
    /// Colour of this beat's dot when it is the current beat.
    var color: Color {
        switch self {
        case .sam: return .turmeric
        case .clap: return .coral
        case .count, .wave: return .ivory
        }
    }

    /// Relative dot size: big for sam, medium for clap, small for counts.
    var dotScale: CGFloat {
        switch self {
        case .sam: return 1.0
        case .clap: return 0.75
        case .count, .wave: return 0.5
        }
    }
}
