//
//  HapticEngine.swift
//  PulseProtocol2.0
//
//  Created by Shreyansh on 22/12/25.
//

import UIKit
import CoreHaptics

// MARK: - Haptic Engine Controller
class HapticEngine {
    static let shared = HapticEngine()
    
    private var engine: CHHapticEngine?
    private var impactGenerator: UIImpactFeedbackGenerator?
    
    private init() {
        setupHaptics()
    }
    
    // MARK: - Setup
    private func setupHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            print("Device doesn't support haptics")
            return
        }
        
        do {
            engine = try CHHapticEngine()
            try engine?.start()
            
            // Fallback impact generator
            impactGenerator = UIImpactFeedbackGenerator(style: .medium)
            impactGenerator?.prepare()
            
        } catch {
            print("Haptic engine failed to start: \(error)")
        }
    }
    
    // MARK: - Play Single Pattern
    func playPattern(_ type: HapticType) {
        guard let engine = engine else {
            // Fallback to basic haptic
            impactGenerator?.impactOccurred(intensity: type.intensity)
            return
        }
        
        do {
            let intensity = CHHapticEventParameter(
                parameterID: .hapticIntensity,
                value: Float(type.intensity)
            )
            
            // Fixed: Use proper sharpness value based on type
            let sharpnessValue: Float = {
                switch type {
                case .short: return 1.0
                case .medium: return 0.7
                case .long: return 0.5
                }
            }()
            
            let sharpness = CHHapticEventParameter(
                parameterID: .hapticSharpness,
                value: sharpnessValue
            )
            
            let event = CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [intensity, sharpness],
                relativeTime: 0,
                duration: type.duration
            )
            
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
            
        } catch {
            print("Failed to play haptic: \(error)")
            impactGenerator?.impactOccurred(intensity: type.intensity)
        }
    }
    
    // MARK: - Play Sequence
    func playSequence(_ sequence: HapticSequence, completion: @escaping () -> Void) {
        var delay: TimeInterval = 0

        for pattern in sequence.patterns {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.playPattern(pattern)
            }
            delay += pattern.duration + 0.2
        }

        // ✅ GUARANTEED completion
        DispatchQueue.main.asyncAfter(deadline: .now() + delay + 0.05) {
            print("✅ HAPTIC SEQUENCE FINISHED")
            completion()
        }
    }

    
    // MARK: - Feedback Haptics
    func playSuccess() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    func playError() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
    
    func playWarning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
    
    // MARK: - Stop Engine
    func stop() {
        engine?.stop()
    }
}
