//
//  HapticsEngineManager.swift
//  HaptIQ
//
//  Created by Shreyansh on 15/11/25.
//


import CoreHaptics
import Foundation

final class HapticsEngineManager {
    static let shared = HapticsEngineManager()
    
    private var engine: CHHapticEngine?
    
    private init() {
        createEngine()
    }
    
    private func createEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            print("Device does not support haptics")
            return
        }
        
        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            print("Failed to start haptic engine: \(error)")
        }
    }
    
    // MARK: - Load JSON Pattern
    private func loadPattern(from filename: String) -> CHHapticPattern? {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
            print("HAPTICS: Couldn't find \(filename).json")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]
            
            let typedDict: [CHHapticPattern.Key: Any] =
                Dictionary(uniqueKeysWithValues:
                    dict.map { (CHHapticPattern.Key(rawValue: $0.key), $0.value) }
                )
            
            return try CHHapticPattern(dictionary: typedDict)
            
        } catch {
            print("HAPTICS: Failed to load pattern: \(error)")
            return nil
        }
    }

    
    // MARK: - Play Pattern
    func playPattern(_ name: String) {
        guard let pattern = loadPattern(from: name) else { return }
        
        do {
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("HAPTICS: Could not play pattern \(name): \(error)")
        }
    }
    
    // MARK: - Specific Patterns
    func playRumble() {
        playPattern("rumble")
    }
    
    func playInflate() {
        playPattern("inflate")
    }
}
