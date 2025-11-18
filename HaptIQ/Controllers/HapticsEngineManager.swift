import CoreHaptics
import Foundation
import UIKit
final class HapticsEngineManager {
    static let shared = HapticsEngineManager()

    private var engine: CHHapticEngine?

    private init() {
        prepareEngine()
        NotificationCenter.default.addObserver(self,
            selector: #selector(prepareEngine),
            name: UIApplication.didBecomeActiveNotification,
            object: nil)
    }

    @objc private func prepareEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            print("❌ Haptics not supported")
            return
        }

        do {
            engine = try CHHapticEngine()
            try engine?.start()
            print("🔥 Engine started")
        } catch {
            print("❌ Haptics engine fail:", error)
        }
    }

    func playRumble() {
        guard let engine = engine else { return }

        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [],
            relativeTime: 0
        )

        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
            print("🔥 Rumble played")
        } catch {
            print("❌ Rumble error:", error)
        }
    }
}
