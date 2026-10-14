import SwiftUI

/// A circle of dots, one per beat of the tala, with beat 1 (sam) at the top.
/// The current beat lights up in its colour: turmeric for sam, coral for a
/// clap, ivory for counts and waves. Used on both the iPhone and the Watch.
struct BeatRingView: View {
    let tala: Tala
    /// Position of the current beat inside the cycle (0 = sam), or nil.
    let currentPosition: Int?
    /// Diameter of the biggest (sam) dot. Clap and count dots are smaller.
    var samDotSize: CGFloat = 40
    /// Show the beat number inside each dot (too small to read on the Watch).
    var showNumbers = true

    var body: some View {
        GeometryReader { geometry in
            let side = min(geometry.size.width, geometry.size.height)
            let radius = (side - samDotSize) / 2

            ZStack {
                // Thin dashed guide circle, like a temple drawing.
                Circle()
                    .stroke(Color.templeGold.opacity(0.6), style: StrokeStyle(lineWidth: 1, dash: [3, 5]))
                    .frame(width: radius * 2, height: radius * 2)

                ForEach(0..<tala.beatCount, id: \.self) { index in
                    dot(at: index)
                        .offset(x: radius * cos(angle(of: index)), y: radius * sin(angle(of: index)))
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .animation(.easeOut(duration: 0.12), value: currentPosition)
    }

    private func dot(at index: Int) -> some View {
        let kind = tala.pattern[index]
        let isCurrent = index == currentPosition
        let size = samDotSize * kind.dotScale

        return ZStack {
            Circle()
                .fill(isCurrent ? kind.color : Color.maroon)
            Circle()
                .strokeBorder(kind.color.opacity(isCurrent ? 1 : 0.55), lineWidth: 1.5)
            if showNumbers {
                Text("\(index + 1)")
                    .font(.system(size: max(size * 0.42, 8), weight: .semibold, design: .rounded))
                    .foregroundStyle(isCurrent ? Color.maroon : kind.color)
            }
        }
        .frame(width: size, height: size)
        .scaleEffect(isCurrent ? 1.3 : 1)
        .shadow(color: isCurrent ? kind.color.opacity(0.8) : .clear, radius: isCurrent ? 8 : 0)
    }

    /// Angle of a dot: beat 1 at 12 o'clock, then clockwise.
    private func angle(of index: Int) -> CGFloat {
        CGFloat(index) / CGFloat(tala.beatCount) * 2 * .pi - .pi / 2
    }
}
