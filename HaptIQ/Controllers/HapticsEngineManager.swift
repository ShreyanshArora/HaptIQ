import CoreHaptics
import Foundation
import UIKit

final class HapticsEngineManager {
    static let shared = HapticsEngineManager()

    private var engine: CHHapticEngine?

    private init() {
        prepareEngine()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(prepareEngine),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    @objc private func prepareEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            print("Haptics not supported")
            return
        }

        do {
            engine = try CHHapticEngine()
            try engine?.start()
            print("Hptics Engine started")
        } catch {
            print("Haptics engine fail", error)
        }
    }

    // MARK: - NEW Countable Rumble Pattern
    /// Creates distinct, countable rumble patterns (2-5 rumbles)
    /// Each rumble is strong and separated by a noticeable pause
    /// Players can easily count: "1... 2... 3..."
    func playCountableRumble(count: Int) {
        guard count >= 2 && count <= 5 else {
            print("Count must be 2-5")
            return
        }
        
        //  CRITICAL: Ensure engine is running
        guard let engine = engine else {
            print("Engine not ready")
            prepareEngine() // Try to restart
            return
        }
        
        // Check if engine is running, restart if needed
        do {
            try engine.start()
        } catch {
            print("Engine restart failed:", error)
            return
        }

        var events: [CHHapticEvent] = []
        
        let rumbleDuration: TimeInterval = 0.4
        let pauseBetweenRumbles: TimeInterval = 0.6
        
        for i in 0..<count {
            let startTime = Double(i) * (rumbleDuration + pauseBetweenRumbles)
            
            let intensity = CHHapticEventParameter(
                parameterID: .hapticIntensity,
                value: 1.0
            )
            
            let sharpness = CHHapticEventParameter(
                parameterID: .hapticSharpness,
                value: 0.8
            )
            
            let event = CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [intensity, sharpness],
                relativeTime: startTime,
                duration: rumbleDuration
            )
            
            events.append(event)
        }

        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
            print("Playing \(count) countable rumbles")
            
            // NEW: Verify pattern duration
            let totalDuration = Double(count) * (rumbleDuration + pauseBetweenRumbles)
            print("Pattern duration: \(totalDuration)s for \(count) rumbles")
            
        } catch {
            print(" Countable rumble error:", error)
        }
    }
    // MARK: - Alternative: Faster Pattern (Optional)
    /// Faster version with shorter intervals
    /// Use this if 15 seconds feels too long
    func playFastCountableRumble(count: Int) {
        guard let engine = engine else { return }
        guard count >= 2 && count <= 5 else { return }

        var events: [CHHapticEvent] = []
        
        // Faster timing:
        // - Each rumble: 0.3 seconds
        // - Pause: 0.4 seconds
        // Total for 5 rumbles: 5 × 0.7 = 3.5 seconds
        
        let rumbleDuration: TimeInterval = 0.3
        let pauseBetweenRumbles: TimeInterval = 0.4
        
        for i in 0..<count {
            let startTime = Double(i) * (rumbleDuration + pauseBetweenRumbles)
            
            let intensity = CHHapticEventParameter(
                parameterID: .hapticIntensity,
                value: 1.0
            )
            
            let sharpness = CHHapticEventParameter(
                parameterID: .hapticSharpness,
                value: 0.9  // Even sharper for quick distinction
            )
            
            let event = CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [intensity, sharpness],
                relativeTime: startTime,
                duration: rumbleDuration
            )
            
            events.append(event)
        }

        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
            print("Playing \(count) fast rumbles")
        } catch {
            print("Fast rumble error:", error)
        }
    }

    // MARK: - Legacy Simple Rumble (for UI feedback)
    /// Single simple rumble for button taps, etc.
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
            print("Simple rumble played")
        } catch {
            print("Rumble error:", error)
        }
    }
}
