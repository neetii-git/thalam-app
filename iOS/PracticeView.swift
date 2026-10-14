import SwiftUI

/// Root screen: the practice setup, or the beat ring while playing.
struct PracticeView: View {
    @EnvironmentObject private var model: PracticeModel

    var body: some View {
        ZStack {
            if model.isPlaying {
                PlayingView()
                    .transition(.opacity)
            } else {
                SetupView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: model.isPlaying)
        .task {
            model.requestHealthAuthorization()
            #if DEBUG
            // Used by the CI screenshot job: launching with -autostart presses Start.
            if ProcessInfo.processInfo.arguments.contains("-autostart") { model.start() }
            #endif
        }
    }
}

// MARK: - Setup ("Set the tala")

struct SetupView: View {
    @EnvironmentObject private var model: PracticeModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("THALAM")
                        .font(.caption.weight(.bold))
                        .tracking(3)
                        .foregroundStyle(Color.kumkum)
                    Text("Set the tala")
                        .font(.system(size: 36, weight: .regular, design: .serif))
                        .foregroundStyle(Color.maroon)
                    Text("Feel the rhythm on your wrist.")
                        .font(.subheadline)
                        .foregroundStyle(Color.maroon.opacity(0.7))
                }
                .padding(.bottom, 4)

                SectionLabel(text: "Choose tala")
                VStack(spacing: 10) {
                    ForEach(Tala.all) { tala in
                        TalaCard(tala: tala, isSelected: tala == model.selectedTala) {
                            model.selectedTala = tala
                        }
                    }
                }

                SectionLabel(text: "Speed")
                TempoControl(bpm: model.bpm, onSlower: model.slower, onFaster: model.faster)

                WatchStatusRow(onDark: false)

                Toggle(isOn: $model.tapsOnPhone) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Also tap on this iPhone")
                            .font(.subheadline.weight(.semibold))
                        Text("Armband mode, or a backup if the watch isn't with you")
                            .font(.caption)
                            .foregroundStyle(Color.maroon.opacity(0.65))
                    }
                }
                .tint(Color.kumkum)
                .foregroundStyle(Color.maroon)
                .padding(.horizontal, 4)
            }
            .padding(20)
        }
        .safeAreaInset(edge: .bottom) {
            BigButton(title: "Start feeling the beat", systemImage: "play.fill", action: model.start)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
                .background(Color.ivory.opacity(0.95).ignoresSafeArea())
        }
        .background(Color.ivory.ignoresSafeArea())
    }
}

// MARK: - Playing (beat ring)

struct PlayingView: View {
    @EnvironmentObject private var model: PracticeModel

    var body: some View {
        let tala = model.playingTala
        let position = model.currentBeat.map { tala.positionInCycle(ofBeat: $0) }
        let kind = position.map { tala.pattern[$0] }

        VStack(spacing: 20) {
            VStack(spacing: 4) {
                Text("FEEL EVERY BEAT")
                    .font(.caption.weight(.bold))
                    .tracking(3)
                    .foregroundStyle(Color.turmeric)
                Text(tala.name)
                    .font(.system(size: 30, weight: .regular, design: .serif))
                    .foregroundStyle(Color.ivory)
                Text("\(model.playingBPM) beats per minute")
                    .font(.subheadline)
                    .foregroundStyle(Color.ivory.opacity(0.7))
            }

            Spacer(minLength: 0)

            ZStack {
                // Soft glow behind the ring.
                Circle()
                    .fill(Color.kumkum.opacity(0.25))
                    .padding(36)

                BeatRingView(tala: tala, currentPosition: position, samDotSize: 46, showNumbers: true)

                // Centre label: "Sam" / "Clap" / "count"
                VStack(spacing: 4) {
                    Text(kind?.label ?? "Ready")
                        .font(.system(size: 42, weight: .regular, design: .serif))
                        .foregroundStyle(kind?.color ?? Color.ivory)
                    Text(position.map { "beat \($0 + 1) of \(tala.beatCount)" } ?? "starting…")
                        .font(.footnote)
                        .monospacedDigit()
                        .foregroundStyle(Color.ivory.opacity(0.75))
                }
                .frame(width: 150, height: 150)
                .background(Circle().fill(Color.maroon))
                .overlay(Circle().strokeBorder(Color.templeGold, lineWidth: 1))
            }
            .frame(maxWidth: 330, maxHeight: 330)
            .aspectRatio(1, contentMode: .fit)

            Spacer(minLength: 0)

            WatchStatusRow(onDark: true)
            BigButton(title: "Stop", systemImage: "stop.fill", action: model.stop)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.maroon.ignoresSafeArea())
    }
}
