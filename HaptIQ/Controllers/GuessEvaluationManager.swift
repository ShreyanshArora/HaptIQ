
//  GuessEvaluationManager.swift
//  HaptIQ
//
//  Handles all game evaluation logic after the TapGuess phase:
//  - Host: listens for all guesses, evaluates, writes gameState to Firebase
//  - Non-Host: listens for gameState from host
//  - Both: navigates to the correct next screen

import UIKit
import FirebaseFirestore

// MARK: - Evaluation Result
struct EvaluationResult {
    let screen: String
    let round: Int
    let rumbleCount: Int
    let survivingPlayerIDs: [String]
    let eliminatedPlayerIDs: [String]
    let crewmatesWon: Bool?
}

// MARK: - Navigation Delegate
protocol GuessEvaluationDelegate: AnyObject {
    func evaluationDidNavigate()
}

// MARK: - GuessEvaluationManager
final class GuessEvaluationManager {
    
    // MARK: - Properties
    private let roomCode: String
    private let rumbleCount: Int
    private let players: [RoomManager.Player]
    private let currentRound: Int
    private let myRole: HapticsRoomViewController.PlayerRole
    private let selectedAvatar: AvatarPage?
    
    private let db = Firestore.firestore()
    private var guessListener: ListenerRegistration?
    private var gameStateListener: ListenerRegistration?
    private var hasProcessedResults = false
    private var hasNavigated = false
    private var waitingForResultsSince: TimeInterval = 0
    private var guessTimeoutTask: DispatchWorkItem?
    
    weak var delegate: GuessEvaluationDelegate?
    private weak var navigationController: UINavigationController?
    
    // MARK: - Init
    init(roomCode: String,
         rumbleCount: Int,
         players: [RoomManager.Player],
         currentRound: Int,
         myRole: HapticsRoomViewController.PlayerRole,
         selectedAvatar: AvatarPage?,
         navigationController: UINavigationController?) {
        self.roomCode = roomCode
        self.rumbleCount = rumbleCount
        self.players = players
        self.currentRound = currentRound
        self.myRole = myRole
        self.selectedAvatar = selectedAvatar
        self.navigationController = navigationController
    }
    
    deinit {
        cleanup()
        print("🗑️ GuessEvaluationManager deallocated")
    }
    
    // MARK: - Public API
    
    /// Call this after successfully writing the guess to Firestore
    func startListening(waitingSince: TimeInterval) {
        self.waitingForResultsSince = waitingSince
        
        if RoomManager.shared.isHost {
            hostListenForAllGuesses()
        } else {
            nonHostListenForGameState()
        }
    }
    
    func cleanup() {
        guessListener?.remove()
        guessListener = nil
        gameStateListener?.remove()
        gameStateListener = nil
        guessTimeoutTask?.cancel()
        guessTimeoutTask = nil
    }
    
    // MARK: - Game Rules
    private func getMaxRounds() -> Int {
        if players.count >= 5 { return 3 }
        else if players.count >= 3 { return 2 }
        else { return 2 }
    }
    
    // ════════════════════════════════════════════════════════════════════
    // MARK: - HOST: Listen for all guesses and evaluate
    // ════════════════════════════════════════════════════════════════════
    
    private func hostListenForAllGuesses() {
        guard RoomManager.shared.isHost else { return }
        
        print("👑 [HOST] Listening for all guesses...")
        
        guessListener?.remove()
        guessListener = db.collection("rooms")
            .document(roomCode)
            .collection("guesses")
            .whereField("round", isEqualTo: currentRound)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                guard RoomManager.shared.isHost else { return }
                guard !self.hasProcessedResults else { return }
                
                if let error = error {
                    print("❌ [HOST] Listener error: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                print("👑 [HOST] Guesses for round \(self.currentRound): \(documents.count)/\(self.players.count)")
                
                if documents.count >= self.players.count {
                    print("👑 [HOST] All players submitted!")
                    
                    self.hasProcessedResults = true
                    self.guessListener?.remove()
                    self.guessListener = nil
                    self.guessTimeoutTask?.cancel()
                    self.guessTimeoutTask = nil
                    
                    let allGuesses = documents.map { $0.data() }
                    self.hostEvaluateAndWriteGameState(allGuesses)
                }
            }
            
        // Start timeout
        guessTimeoutTask?.cancel()
        let task = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            guard !self.hasProcessedResults, RoomManager.shared.isHost else { return }
            print("⏳ [HOST] Guess timeout reached! Evaluating with received guesses.")
            
            self.guessListener?.remove()
            self.guessListener = nil
            self.hasProcessedResults = true
            
            self.db.collection("rooms")
                .document(self.roomCode)
                .collection("guesses")
                .whereField("round", isEqualTo: self.currentRound)
                .getDocuments { snapshot, _ in
                    let docs = snapshot?.documents ?? []
                    let allGuesses = docs.map { $0.data() }
                    self.hostEvaluateAndWriteGameState(allGuesses)
                }
        }
        self.guessTimeoutTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 30.0, execute: task)
    }
    
    private func hostEvaluateAndWriteGameState(_ guesses: [[String: Any]]) {
        guard RoomManager.shared.isHost else { return }
        
        print("\n👑 [HOST] === EVALUATING ROUND \(currentRound) ===")
        
        // Find imposter
        var imposterID = ""
        for (playerID, role) in RoomManager.shared.cachedRoles {
            if role == "imposter" {
                imposterID = playerID
                break
            }
        }
        
        guard !imposterID.isEmpty else {
            print("❌ [HOST] No imposter found")
            return
        }
        
        print("👑 [HOST] Imposter: \(String(imposterID.prefix(8)))")

        var imposterWrong = false
        var wrongCrewmates: [String] = []

        var guessMap: [String: Int] = [:]
        for guess in guesses {
            if let playerID = guess["playerID"] as? String,
               let tapCount = guess["tapCount"] as? Int {
                guessMap[playerID] = tapCount
            }
        }

        for player in players {
            let playerID = player.id
            let isImposter = (playerID == imposterID)
            
            if let tapCount = guessMap[playerID] {
                let isCorrect = tapCount == rumbleCount
                print("👑 [HOST] Player \(String(playerID.prefix(8))): \(tapCount) vs \(rumbleCount) = \(isCorrect ? "✅" : "❌")")
                
                if isImposter {
                    if !isCorrect { imposterWrong = true }
                } else {
                    if !isCorrect { wrongCrewmates.append(playerID) }
                }
            } else {
                print("👑 [HOST] Player \(String(playerID.prefix(8))): Did not submit (marked ❌)")
                if isImposter {
                    imposterWrong = true
                } else {
                    wrongCrewmates.append(playerID)
                }
            }
        }

        print("👑 [HOST] Imposter wrong: \(imposterWrong), Crewmates wrong: \(wrongCrewmates.count)")

        // Determine next state
        let result = evaluateRound(
            imposterWrong: imposterWrong,
            wrongCrewmates: wrongCrewmates,
            imposterID: imposterID
        )
        
        var newHostID = RoomManager.shared.hostID
        if result.eliminatedPlayerIDs.contains(newHostID) {
            if let backupHost = result.survivingPlayerIDs.first(where: { $0 != newHostID }) {
                newHostID = backupHost
                print("👑 [HOST] Host eliminated! Migrating host to \(newHostID)")
            }
        }
        
        // Write game state to Firestore
        let gameStateData: [String: Any] = [
            "screen": result.screen,
            "round": result.round,
            "rumbleCount": result.rumbleCount,
            "survivingPlayerIDs": result.survivingPlayerIDs,
            "eliminatedPlayerIDs": result.eliminatedPlayerIDs,
            "crewmatesWon": result.crewmatesWon as Any,
            "forRound": currentRound,
            "newHostID": newHostID,
            "timestamp": FieldValue.serverTimestamp()
        ]
        
        print("👑 [HOST] Writing gameState: screen=\(result.screen), forRound=\(currentRound)")
        
        let newStateString = (result.screen == "result") ? "result" : ((result.screen == "voting") ? "voting" : "playing")
        
        db.collection("rooms")
            .document(roomCode)
            .updateData([
                "gameState": gameStateData,
                "state": newStateString
            ]) { [weak self] error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ [HOST] Failed to write gameState: \(error)")
                    return
                }
                
                print("✅ [HOST] gameState written successfully")
                
                self.clearGuesses()
                
                if newHostID != RoomManager.shared.hostID {
                    RoomManager.shared.hostID = newHostID
                }
                
                DispatchQueue.main.async {
                    self.navigateToScreen(result: result)
                }
            }
    }
    
    /// Pure game logic — determines the next screen based on guesses
    private func evaluateRound(imposterWrong: Bool,
                                wrongCrewmates: [String],
                                imposterID: String) -> EvaluationResult {
        let maxRounds = getMaxRounds()
        var nextScreen: String
        var nextRound = currentRound
        var nextRumbleCount = rumbleCount
        var survivingPlayerIDs = players.map { $0.id }
        var eliminatedPlayerIDs: [String] = []
        var crewmatesWon: Bool? = nil
        
        // CASE 1: Imposter wrong → Voting
        if imposterWrong {
            print("👑 [HOST] Decision: → VOTING (Imposter wrong)")
            nextScreen = "voting"
        }
        // CASE 2: Imposter correct + crewmates wrong → Eliminate
        else if !wrongCrewmates.isEmpty {
            eliminatedPlayerIDs = wrongCrewmates
            survivingPlayerIDs = players.map { $0.id }.filter { !wrongCrewmates.contains($0) }
            let crewmatesRemaining = survivingPlayerIDs.filter { $0 != imposterID }.count
            
            if crewmatesRemaining < 1 {
                print("👑 [HOST] Decision: → RESULT (Imposter wins - 0 crewmates left)")
                nextScreen = "result"
                crewmatesWon = false
            } else if survivingPlayerIDs.count <= 1 {
                print("👑 [HOST] Decision: → RESULT (Only 1 player left)")
                nextScreen = "result"
                crewmatesWon = false
            } else {
                print("👑 [HOST] Decision: → WRONG ELIMINATION Round \(currentRound + 1)")
                nextScreen = "wrong_elimination"
                nextRound = currentRound + 1
                nextRumbleCount = Int.random(in: 2...5)
            }
        }
        // CASE 3: Everyone correct
        else {
            if currentRound >= maxRounds {
                print("👑 [HOST] Decision: → VOTING (Max rounds)")
                nextScreen = "voting"
            } else {
                print("👑 [HOST] Decision: → HAPTICS Round \(currentRound + 1)")
                nextScreen = "haptics"
                nextRound = currentRound + 1
                nextRumbleCount = Int.random(in: 2...5)
            }
        }
        
        return EvaluationResult(
            screen: nextScreen,
            round: nextRound,
            rumbleCount: nextRumbleCount,
            survivingPlayerIDs: survivingPlayerIDs,
            eliminatedPlayerIDs: eliminatedPlayerIDs,
            crewmatesWon: crewmatesWon
        )
    }
    
    // ════════════════════════════════════════════════════════════════════
    // MARK: - NON-HOST: Listen for game state from host
    // ════════════════════════════════════════════════════════════════════
    
    private func nonHostListenForGameState() {
        guard !RoomManager.shared.isHost else { return }
        
        print("👂 [NON-HOST] Listening for gameState...")
        
        gameStateListener?.remove()
        gameStateListener = db.collection("rooms")
            .document(roomCode)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                guard !self.hasNavigated else { return }
                
                if let error = error {
                    print("❌ [NON-HOST] Listener error: \(error)")
                    return
                }
                
                guard let data = snapshot?.data(),
                      let gameState = data["gameState"] as? [String: Any] else {
                    print("👂 [NON-HOST] No gameState yet")
                    return
                }
                
                // Check if this update is for our current round
                let forRound = gameState["forRound"] as? Int ?? 0
                guard forRound == self.currentRound else {
                    print("👂 [NON-HOST] Ignoring gameState for round \(forRound), we're on \(self.currentRound)")
                    return
                }
                
                // Check timestamp to ensure it's a new update
                if let timestamp = gameState["timestamp"] as? Timestamp {
                    let stateTime = timestamp.dateValue().timeIntervalSince1970
                    guard stateTime > self.waitingForResultsSince else {
                        print("👂 [NON-HOST] Ignoring old gameState (before we submitted)")
                        return
                    }
                }
                
                let result = EvaluationResult(
                    screen: gameState["screen"] as? String ?? "",
                    round: gameState["round"] as? Int ?? 1,
                    rumbleCount: gameState["rumbleCount"] as? Int ?? 3,
                    survivingPlayerIDs: gameState["survivingPlayerIDs"] as? [String] ?? [],
                    eliminatedPlayerIDs: gameState["eliminatedPlayerIDs"] as? [String] ?? [],
                    crewmatesWon: gameState["crewmatesWon"] as? Bool
                )
                
                if let newHostID = gameState["newHostID"] as? String {
                    RoomManager.shared.hostID = newHostID
                }
                
                print("📡 [NON-HOST] Received gameState: screen=\(result.screen), round=\(result.round)")
                
                self.gameStateListener?.remove()
                
                DispatchQueue.main.async {
                    self.navigateToScreen(result: result)
                }
            }
    }
    
    // ════════════════════════════════════════════════════════════════════
    // MARK: - Navigation (Both Host and Non-Host)
    // ════════════════════════════════════════════════════════════════════
    
    private func navigateToScreen(result: EvaluationResult) {
        guard !hasNavigated else {
            print("⚠️ Already navigated, ignoring")
            return
        }
        hasNavigated = true
        cleanup()
        delegate?.evaluationDidNavigate()
        
        let myID = RoomManager.shared.currentUserID
        
        // Check if I was eliminated
        if result.eliminatedPlayerIDs.contains(myID) && result.screen != "result" {
            print("💀 I was eliminated → Spectator")
            let myPlayer = players.first { $0.id == myID }
            let vc = SpectatorViewController(
                playerName: myPlayer?.name,
                playerAvatar: myPlayer?.avatarImage
            )
            navigationController?.pushViewController(vc, animated: true)
            return
        }
        
        print("🔄 Navigating to: \(result.screen)")
        
        switch result.screen {
        case "voting":
            let survivingPlayers = players.filter { result.survivingPlayerIDs.contains($0.id) }
            let vc = VotingViewController(
                roomCode: roomCode,
                players: survivingPlayers,
                currentRound: currentRound,
                selectedAvatar: selectedAvatar
            )
            navigationController?.pushViewController(vc, animated: true)
            
        case "haptics":
            let survivingPlayers = players.filter { result.survivingPlayerIDs.contains($0.id) }
            let vc = HapticsRoomViewController(
                roomCode: roomCode,
                players: survivingPlayers,
                rumbleCount: result.rumbleCount,
                role: myRole
            )
            vc.currentRound = result.round
            vc.selectedAvatar = selectedAvatar
            navigationController?.pushViewController(vc, animated: true)
            
        case "wrong_elimination":
            let survivingPlayers = players.filter { result.survivingPlayerIDs.contains($0.id) }
            let eliminatedPlayer = players.first { result.eliminatedPlayerIDs.contains($0.id) }
            let vc = GameResultViewController(
                crewmatesWon: false,
                roomCode: roomCode,
                eliminatedPlayerName: eliminatedPlayer?.name ?? "",
                eliminatedAvatarImage: eliminatedPlayer?.avatarImage ?? "char1",
                isWrongElimination: true,
                survivingPlayers: survivingPlayers,
                nextRound: result.round,
                nextRumbleCount: result.rumbleCount
            )
            navigationController?.pushViewController(vc, animated: true)
            
        case "result":
            var imposterAvatar = "char1"
            if let imposterID = RoomManager.shared.cachedRoles.first(where: { $0.value == "imposter" })?.key,
               let imposterPlayer = players.first(where: { $0.id == imposterID }) {
                imposterAvatar = imposterPlayer.avatarImage ?? "char1"
            }
            let vc = GameResultViewController(
                crewmatesWon: result.crewmatesWon ?? false,
                roomCode: roomCode,
                eliminatedPlayerName: "",
                eliminatedAvatarImage: imposterAvatar
            )
            navigationController?.pushViewController(vc, animated: true)
            
        default:
            print("⚠️ Unknown screen: \(result.screen)")
        }
    }
    
    // MARK: - Cleanup Helpers
    private func clearGuesses() {
        db.collection("rooms")
            .document(roomCode)
            .collection("guesses")
            .whereField("round", isEqualTo: currentRound)
            .getDocuments { [weak self] snapshot, _ in
                guard let documents = snapshot?.documents, !documents.isEmpty else { return }
                guard let self = self else { return }
                
                let batch = self.db.batch()
                for doc in documents {
                    batch.deleteDocument(doc.reference)
                }
                batch.commit { error in
                    if error == nil {
                        print("🧹 Cleared \(documents.count) guesses for round \(self.currentRound)")
                    }
                }
            }
    }
}
