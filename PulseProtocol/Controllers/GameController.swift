import Foundation
import Combine

// MARK: - Game Controller
class GameController: ObservableObject {
    @Published var session = GameSession()

    private let hapticEngine = HapticEngine.shared
    private let storage      = UserDefaultsManager.shared

    /// Single source of truth for when the finger went down
    private var tapStartTime: Date?
    
    /// Track if current round was perfect (all taps correct)
    private var roundPerfect: Bool = true

    init() {
        session.highScore = storage.getHighScore()
    }

    // MARK: - Game Flow

    func startGame() {
        print("🎮 startGame()")
        session.reset()
        session.highScore = storage.getHighScore()
        startNewRound()
    }

    func startNewRound() {
        roundPerfect = true  // Reset perfect tracker
        session.startNewRound()

        guard let sequence = session.currentSequence else { return }

        // Trigger UI so "playingPattern" view shows immediately
        DispatchQueue.main.async { [weak self] in
            self?.objectWillChange.send()
        }

        // Play the haptic sequence, then hand control to the user
        hapticEngine.playSequence(sequence) { [weak self] in
            DispatchQueue.main.async {
                self?.session.phase            = .waitingForInput
                self?.session.patternStartTime = Date()
                self?.objectWillChange.send()
            }
        }
    }

    // MARK: - Tap Handling

    func onTapDown(type: HapticType) {
        guard session.phase == .waitingForInput else { return }
        tapStartTime = Date()
        hapticEngine.playPattern(type)   // immediate vibration feedback
    }

    func onTapUp(type: HapticType) {
        guard session.phase == .waitingForInput,
              let start = tapStartTime else { return }

        let held = Date().timeIntervalSince(start)
        tapStartTime = nil

        print("👆 \(type.rawValue) held \(String(format: "%.3f", held))s")

        // Record what the user did
        session.recordInput(type: type, duration: held)

        // Score this single tap
        let index = session.userInputs.count - 1
        let expected = session.currentSequence!.patterns[index]
        let input = session.userInputs[index]

        if let points = PatternMatcher.score(
                userDuration: input.duration,
                expected: expected
        ) {
            session.applyPoints(points)
        } else {
            roundPerfect = false
            hapticEngine.playError()
            session.applyWrong()
        }

        // After every tap, check if the round is now finished
        if session.isRoundComplete() {
            handleRoundComplete()
        }

        // else: more taps still needed this round, stay in waitingForInput
    }
    
    // MARK: - Round Completion Logic
    private func handleRoundComplete() {
        // Round finished
        hapticEngine.playSuccess()
        session.phase = .correct
        
        // Check if we should unlock bonus
        if roundPerfect && session.shouldUnlockBonus() {
            // Show bonus unlock animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
                self?.session.phase = .bonusUnlocked
                
                // Then proceed to next round after showing bonus message
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                    self?.startNewRound()
                }
            }
        } else if roundPerfect && session.currentRound >= 6 {
            // Continue bonus rounds if perfect
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.startNewRound()
            }
        } else if !roundPerfect && session.currentRound >= 6 {
            // Failed during bonus rounds - game over
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
                self?.persistHighScore()
                self?.session.phase = .gameOver
            }
        } else {
            // Normal progression
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.startNewRound()
            }
        }
    }

    // MARK: - Persist high score

    private func persistHighScore() {
        if session.currentScore > storage.getHighScore() {
            storage.saveHighScore(session.currentScore)
        }
        session.highScore = storage.getHighScore()
    }

    // MARK: - Navigation

    func restartGame() {
        startGame()
    }

    func returnToMenu() {
        session.reset()
        session.phase = .menu
    }
}
