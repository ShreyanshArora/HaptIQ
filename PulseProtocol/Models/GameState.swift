import Foundation

// MARK: - Game Phase
enum GamePhase: Equatable {
    case menu
    case instructions
    case playingPattern    // Device is vibrating
    case waitingForInput   // User's turn to tap
    case correct           // User got it right
    case bonusUnlocked     // Bonus round unlocked!
    case gameOver          // User failed
}

// MARK: - Score Popup
struct ScorePopup: Identifiable {
    let id         = UUID()
    let text       : String   // "+10" or "-5"
    let isPositive : Bool
}

// MARK: - Game Session
class GameSession: ObservableObject {
    @Published var phase           : GamePhase      = .menu {
        didSet { print("🔄 Phase changed from \(oldValue) to \(phase)") }
    }
    @Published var currentScore    : Int            = 0
    @Published var highScore       : Int            = 0
    @Published var currentRound    : Int            = 0
    @Published var currentSequence : HapticSequence? = nil
    @Published var userInputs      : [UserInput]    = []
    @Published var activePopup     : ScorePopup?    = nil

    /// True the moment any tap this round is wrong.
    var hadWrongTap : Bool = false

    // Timing
    var patternStartTime : Date? = nil
    var lastInputTime    : Date? = nil

    // MARK: - Constants
    static let pointsCorrect =  10
    static let pointsWrong   =  -5

    // MARK: - Reset
    func reset() {
        phase             = .menu
        currentScore      = 0
        currentRound      = 0
        currentSequence   = nil
        userInputs        = []
        activePopup       = nil
        patternStartTime  = nil
        lastInputTime     = nil
    }

    // MARK: - New Round
    func startNewRound() {
        currentRound    += 1
        currentSequence  = HapticSequence.generate(difficulty: currentRound)
        userInputs       = []
        hadWrongTap      = false
        phase            = .playingPattern
        print("🎵 Round \(currentRound)\(currentSequence!.isBonus ? " 🎁 BONUS" : ""): \(currentSequence!.patterns.map { $0.rawValue })")
    }

    // MARK: - Input
    func recordInput(type: HapticType, duration: TimeInterval) {
        userInputs.append(UserInput(
            type:      type,
            timestamp: Date().timeIntervalSince1970,
            duration:  duration
        ))
        lastInputTime = Date()
    }

    // MARK: - Validation (checks the LAST input recorded)
    func validateLastInput() -> Bool {
        guard let seq = currentSequence else { return false }
        let index = userInputs.count - 1
        guard index >= 0, index < seq.patterns.count else { return false }

        let expected = seq.patterns[index]
        let input    = userInputs[index]

        return PatternMatcher.matches(
            userInput: input.type,
            expected:  expected,
            duration:  input.duration
        )
    }

    func isRoundComplete() -> Bool {
        guard let seq = currentSequence else { return false }
        return userInputs.count == seq.patterns.count
    }
    
    // Check if this round unlocks a bonus
    func shouldUnlockBonus() -> Bool {
        // Bonus unlocks at round 5, and every round after if perfect
        return currentRound == 5 || (currentRound >= 6 && currentSequence?.isBonus == true)
    }

    // MARK: - Score
    func applyCorrect() {
        currentScore = max(0, currentScore + GameSession.pointsCorrect)
        if currentScore > highScore { highScore = currentScore }
        triggerPopup(GameSession.pointsCorrect)
    }

    func applyWrong() {
        currentScore = max(0, currentScore - 5)
        triggerPopup(-5)
    }

    func applyPoints(_ points: Int) {
        currentScore = max(0, currentScore + points)
        if currentScore > highScore {
            highScore = currentScore
        }
        triggerPopup(points)
    }

    private func triggerPopup(_ delta: Int) {
        let text = delta >= 0 ? "+\(delta)" : "\(delta)"
        activePopup = ScorePopup(text: text, isPositive: delta >= 0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.activePopup = nil
        }
    }
}
