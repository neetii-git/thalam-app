import SwiftUI

/// Shows the idle screen or the playing screen.
struct WatchRootView: View {
    @EnvironmentObject private var engine: BeatEngine

    var body: some View {
        ZStack {
            Color.maroon.ignoresSafeArea()
            if engine.isPlaying {
                WatchPlayingView()
            } else {
                WatchIdleView()
            }
        }
        #if DEBUG
        .task {
            // Used by the CI screenshot job: launching with -autostart starts Adi at 80.
            if ProcessInfo.processInfo.arguments.contains("-autostart") { engine.startStandalone() }
        }
        #endif
    }
}

// MARK: - Idle

struct WatchIdleView: View {
    @EnvironmentObject private var engine: BeatEngine

    var body: some View {
        VStack(spacing: 6) {
            Text("Thalam")
                .font(.system(size: 30, weight: .regular, design: .serif))
                .foregroundStyle(Color.turmeric)
            Text("Start from your iPhone")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.ivory.opacity(0.85))

            Spacer(minLength: 6)

            // Standalone mode, in case the phone link fails during the demo.
            Button {
                engine.startStandalone()
            } label: {
                Label("Adi · 80 BPM", systemImage: "play.fill")
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.kumkum)

            Text("Practise without phone")
                .font(.caption2)
                .foregroundStyle(Color.ivory.opacity(0.6))
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Playing

struct WatchPlayingView: View {
    @EnvironmentObject private var engine: BeatEngine
    /// Opacity of the gold flash that fills the screen on sam.
    @State private var flash = 0.0

    var body: some View {
        let tala = engine.tala
        let position = engine.currentBeat.map { tala.positionInCycle(ofBeat: $0) }
        let kind = position.map { tala.pattern[$0] }

        ZStack {
            // Big gold flash on sam.
            Color.turmeric
                .opacity(flash)
                .ignoresSafeArea()

            VStack(spacing: 4) {
                ZStack {
                    BeatRingView(tala: tala, currentPosition: position, samDotSize: 16, showNumbers: false)

                    VStack(spacing: 0) {
                        // Beat number within the cycle, e.g. "5"
                        Text(position.map { "\($0 + 1)" } ?? "·")
                            .font(.system(size: 40, weight: .semibold, design: .serif))
                            .monospacedDigit()
                            .foregroundStyle(kind?.color ?? Color.ivory)
                        Text(kind?.label ?? "Ready")
                            .font(.system(.footnote, design: .serif))
                            .foregroundStyle(Color.ivory)
                    }
                }
                .frame(width: 112, height: 112)

                Text("\(tala.name) · \(engine.bpm)")
                    .font(.caption2)
                    .foregroundStyle(Color.ivory.opacity(0.7))

                Button("Stop", role: .destructive) {
                    engine.stopFromWatch()
                }
                .buttonStyle(.bordered)
            }
        }
        .onChange(of: engine.currentBeat) { _, newBeat in
            guard let newBeat, tala.kind(ofBeat: newBeat) == .sam else { return }
            // Show the flash instantly, then fade it out a moment later.
            flash = 0.85
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation(.easeOut(duration: 0.45)) {
                    flash = 0
                }
            }
        }
    }
}
