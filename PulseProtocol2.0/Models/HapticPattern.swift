import Foundation
import UIKit

// MARK: - Haptic Pattern Types
enum HapticType: String, CaseIterable {
    case short
    case medium
    case long

    // What the player FEELS
    var duration: TimeInterval {
        switch self {
        case .short:  return 0.4
        case .medium: return 0.6
        case .long:   return 0.8
        }
    }

    // What the player must MATCH
    var targetPressDuration: TimeInterval {
        duration
    }

    // Precision windows
    var tolerance: TimeInterval {
        switch self {
        case .short:  return 0.10   // 0.30 – 0.50
        case .medium: return 0.10   // 0.50 – 0.70
        case .long:   return 0.10   // 0.70 – 0.90
        }
    }

    var intensity: CGFloat {
        switch self {
        case .short:  return 0.5
        case .medium: return 0.7
        case .long:   return 1.0
        }
    }
}

// MARK: - Pattern Sequence
struct HapticSequence {
    let patterns   : [HapticType]
    let difficulty : Int
    let isBonus    : Bool

    // Progressive difficulty: Round 1→2, R2-4→3, R5→4, R6→5, R7→6, etc.
    static func generate(difficulty: Int) -> HapticSequence {
        let length: Int
        let isBonus: Bool
        
        switch difficulty {
        case 1:
            length = 2
            isBonus = false
        case 2...4:
            length = 3
            isBonus = false
        case 5:
            length = 4
            isBonus = false
        case 6...10:
            // Bonus rounds: 5, 6, 7, 8, 9, 10 haptics
            length = difficulty - 1
            isBonus = true
        default:
            length = min(difficulty + 1, 25)
            isBonus = true
        }
        
        let patterns = (0..<length).map { _ in HapticType.allCases.randomElement()! }
        return HapticSequence(patterns: patterns, difficulty: difficulty, isBonus: isBonus)
    }

    var totalDuration: TimeInterval {
        patterns.reduce(0.0) { $0 + $1.duration + 0.35 }
    }
}

// MARK: - User Input
struct UserInput {
    let type      : HapticType
    let timestamp : TimeInterval
    let duration  : TimeInterval
}

// MARK: - Pattern Matching
struct PatternMatcher {

    static func matches(userInput: HapticType,
                        expected:  HapticType,
                        duration:  TimeInterval) -> Bool {
        // Must be the correct button
        guard userInput == expected else { return false }
        // Must be held for roughly the right duration
        let target    = expected.targetPressDuration
        let tolerance = expected.tolerance
        return abs(duration - target) <= tolerance
    }
    static func score(userDuration: TimeInterval,
                      expected: HapticType) -> Int? {

        switch expected {

        case .short:
            if (0.38...0.42).contains(userDuration) { return 10 }
            if (0.35...0.45).contains(userDuration) { return 8 }
            if (0.30...0.50).contains(userDuration) { return 5 }
            return nil

        case .medium:
            if (0.58...0.62).contains(userDuration) { return 10 }
            if (0.55...0.65).contains(userDuration) { return 8 }
            if (0.50...0.70).contains(userDuration) { return 5 }
            return nil

        case .long:
            if (0.78...0.82).contains(userDuration) { return 10 }
            if (0.75...0.85).contains(userDuration) { return 8 }
            if (0.70...0.90).contains(userDuration) { return 5 }
            return nil
        }
    }

    static func accuracy(userDuration: TimeInterval, expected: HapticType) -> Double {
        let diff    = abs(userDuration - expected.targetPressDuration)
        let maxDiff = expected.tolerance
        guard maxDiff > 0 else { return 1.0 }
        return max(0.0, 1.0 - (diff / maxDiff))
    }
}
