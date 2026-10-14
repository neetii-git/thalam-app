import SwiftUI

/// Small red capital label above a section, e.g. "CHOOSE TALA".
struct SectionLabel: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.caption.weight(.bold))
            .tracking(2)
            .foregroundStyle(Color.kumkum)
    }
}

/// One tala option: name, number of beats, and its pattern as dots.
struct TalaCard: View {
    let tala: Tala
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(tala.name)
                        .font(.system(.title3, design: .serif).weight(.semibold))
                    Text("\(tala.beatCount) beats")
                        .font(.footnote)
                        .opacity(0.8)
                }
                Spacer()
                PatternDots(pattern: tala.pattern, onDark: isSelected)
            }
            .foregroundStyle(isSelected ? Color.ivory : Color.maroon)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? Color.kumkum : Color.white.opacity(0.55))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Color.templeGold.opacity(isSelected ? 1 : 0.5), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// A tala's pattern as a row of dots: big = sam, medium = clap, small = count/wave.
struct PatternDots: View {
    let pattern: [BeatKind]
    /// True when drawn on the red (selected) card.
    let onDark: Bool

    var body: some View {
        HStack(spacing: 5) {
            ForEach(Array(pattern.enumerated()), id: \.offset) { _, kind in
                Circle()
                    .fill(color(for: kind))
                    .frame(width: size(for: kind), height: size(for: kind))
            }
        }
        .accessibilityHidden(true)
    }

    private func size(for kind: BeatKind) -> CGFloat {
        switch kind {
        case .sam: return 14
        case .clap: return 10
        case .count, .wave: return 6
        }
    }

    private func color(for kind: BeatKind) -> Color {
        switch kind {
        case .sam: return .turmeric
        case .clap: return .coral
        case .count, .wave: return onDark ? Color.ivory.opacity(0.85) : Color.maroon.opacity(0.4)
        }
    }
}

/// Tempo: big BPM number with - and + buttons (step 4).
struct TempoControl: View {
    let bpm: Int
    let onSlower: () -> Void
    let onFaster: () -> Void

    var body: some View {
        HStack {
            RoundIconButton(systemImage: "minus", label: "Slower", action: onSlower)
                .disabled(bpm <= Tempo.minBPM)
            Spacer()
            VStack(spacing: 0) {
                Text("\(bpm)")
                    .font(.system(size: 56, weight: .regular, design: .serif))
                    .monospacedDigit()
                    .foregroundStyle(Color.maroon)
                Text("beats per minute")
                    .font(.footnote)
                    .foregroundStyle(Color.maroon.opacity(0.7))
            }
            Spacer()
            RoundIconButton(systemImage: "plus", label: "Faster", action: onFaster)
                .disabled(bpm >= Tempo.maxBPM)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.55)))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.templeGold.opacity(0.5), lineWidth: 1))
    }
}

/// Circular button with a thin gold ring.
struct RoundIconButton: View {
    let systemImage: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.kumkum)
                .frame(width: 48, height: 48)
                .background(Circle().fill(Color.ivory))
                .overlay(Circle().strokeBorder(Color.templeGold, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

/// The big red Start / Stop button.
struct BigButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .foregroundStyle(Color.ivory)
                .frame(maxWidth: .infinity, minHeight: 58)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.kumkum))
                .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.turmeric, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
    }
}

/// "Watch connected" / "Open Thalam on your watch".
struct WatchStatusRow: View {
    @ObservedObject private var connector = PhoneConnector.shared
    /// True on the dark (playing) screen.
    let onDark: Bool

    var body: some View {
        let connected = connector.status == .connected
        let tint: Color = connected ? (onDark ? .turmeric : .peacock) : (onDark ? Color.ivory.opacity(0.75) : Color.maroon.opacity(0.7))

        HStack(spacing: 10) {
            Image(systemName: connected ? "applewatch.radiowaves.left.and.right" : "applewatch")
                .font(.body.weight(.semibold))
            Text(connector.status.message)
                .font(.subheadline.weight(.semibold))
            Spacer()
            Circle()
                .fill(connected ? Color.peacock : Color.coral)
                .frame(width: 9, height: 9)
                .overlay(Circle().strokeBorder(Color.ivory.opacity(0.6), lineWidth: connected ? 0 : 1))
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(onDark ? Color.white.opacity(0.06) : Color.peacock.opacity(connected ? 0.08 : 0.0))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.templeGold.opacity(0.45), lineWidth: 1)
        )
    }
}
