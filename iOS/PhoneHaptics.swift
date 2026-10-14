import CoreHaptics
import Foundation

/// "Armband mode": the iPhone taps the beat itself, for a dancer who wears
/// the phone in an armband, or as a backup if the Watch isn't available.
/// Same three feelings as the Watch: strong sam, medium clap, light count.
final class PhoneHaptics {
    private var engine: CHHapticEngine?
    private var needsStart = true

    /// Gets the haptic engine ready (call before the first beat).
    func prepare() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        if engine == nil {
            do {
                let newEngine = try CHHapticEngine()
                // The system can stop the engine (e.g. app in background);
                // remember to start it again before the next tap.
                newEngine.stoppedHandler = { [weak self] _ in
                    self?.needsStart = true
                }
                newEngine.resetHandler = { [weak self] in
                    self?.needsStart = true
                }
                engine = newEngine
            } catch {
                print("Could not create haptic engine: \(error.localizedDescription)")
                return
            }
        }
        if needsStart {
            do {
                try engine?.start()
                needsStart = false
            } catch {
                print("Could not start haptic engine: \(error.localizedDescription)")
            }
        }
    }

    /// Plays one tap for a beat.
    func play(_ kind: BeatKind) {
        prepare()
        guard let engine else { return }

        let feel = Self.feel(for: kind)
        let parameters = [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: feel.intensity),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: feel.sharpness),
        ]
        var events = [CHHapticEvent(eventType: .hapticTransient, parameters: parameters, relativeTime: 0)]
        if feel.buzz > 0 {
            events.append(CHHapticEvent(eventType: .hapticContinuous, parameters: parameters,
                                        relativeTime: 0, duration: feel.buzz))
        }

        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("Could not play haptic: \(error.localizedDescription)")
        }
    }

    func stop() {
        engine?.stop(completionHandler: nil)
        needsStart = true
    }

    /// How strong each kind of beat feels. `buzz` is how long the tap rings
    /// on after the initial hit (0 = a single short tap).
    private static func feel(for kind: BeatKind) -> (intensity: Float, sharpness: Float, buzz: TimeInterval) {
        switch kind {
        case .sam: return (1.0, 0.7, 0.20)
        case .clap: return (0.75, 0.5, 0.08)
        case .count, .wave: return (0.45, 0.4, 0)
        }
    }
}
