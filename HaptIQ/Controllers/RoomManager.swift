import Foundation
import FirebaseFirestore

final class RoomManager {
    
    static let shared = RoomManager()
    private init() {}
    
    var currentUserID: String = UUID().uuidString
    var cachedRoles: [String: String] = [:]
    var hostID: String = ""
    
    // ✅ Check if current user is host
    var isHost: Bool {
        return currentUserID == hostID
    }
    
    // MARK: - Player Model
    struct Player {
        let id: String
        let name: String
        let isHost: Bool
        let avatarImage: String?
        let avatarTitle: String?
    }
    
    // MARK: - Generate Room Code
    private func generateRoomCode() -> String {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<6).map { _ in characters.randomElement()! })
    }
    
    // MARK: - Create Room
    func createRoom(completion: @escaping (Result<String, Error>) -> Void) {
        let code = generateRoomCode()
        let newHostID = currentUserID
        self.hostID = newHostID
        
        let roomData: [String: Any] = [
            "code": code,
            "hostID": newHostID,
            "createdAt": FieldValue.serverTimestamp(),
            "state": "lobby",
            "currentRound": 0
        ]
        
        let db = Firestore.firestore()
        
        db.collection("rooms").document(code).setData(roomData) { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            db.collection("rooms")
                .document(code)
                .collection("players")
                .document(newHostID)
                .setData([
                    "isHost": true,
                    "joinedAt": FieldValue.serverTimestamp()
                ]) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(code))
                    }
                }
        }
    }
    
    // MARK: - Join Room
    func joinRoom(code: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        let db = Firestore.firestore()
        
        db.collection("rooms").document(code).getDocument { [weak self] snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let snapshot = snapshot, snapshot.exists,
                  let data = snapshot.data() else {
                let error = NSError(domain: "RoomManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "Room not found"])
                completion(.failure(error))
                return
            }
            
            // Cache the host ID
            if let hostID = data["hostID"] as? String {
                self?.hostID = hostID
            }
            
            completion(.success(true))
        }
    }
    
    // MARK: - Add Player
    func addPlayer(id: String, name: String, isHost: Bool, to roomCode: String, completion: @escaping (Error?) -> Void) {
        let avatarImage = UserDefaults.standard.string(forKey: "selectedAvatarImage") ?? "char1"
        let avatarTitle = UserDefaults.standard.string(forKey: "selectedAvatarTitle") ?? "Shadow Hacker"
        
        let playerData: [String: Any] = [
            "name": name,
            "isHost": isHost,
            "avatarImage": avatarImage,
            "avatarTitle": avatarTitle,
            "joinedAt": FieldValue.serverTimestamp()
        ]
        
        Firestore.firestore()
            .collection("rooms")
            .document(roomCode)
            .collection("players")
            .document(id)
            .setData(playerData, completion: completion)
    }
    
    // MARK: - Observe Players
    func observePlayers(inRoom roomCode: String, completion: @escaping ([Player]) -> Void) -> ListenerRegistration {
        return Firestore.firestore()
            .collection("rooms")
            .document(roomCode)
            .collection("players")
            .addSnapshotListener { snapshot, error in
                guard let docs = snapshot?.documents else {
                    completion([])
                    return
                }
                
                let players = docs.compactMap { doc -> Player? in
                    let data = doc.data()
                    return Player(
                        id: doc.documentID,
                        name: data["name"] as? String ?? "Unknown",
                        isHost: data["isHost"] as? Bool ?? false,
                        avatarImage: data["avatarImage"] as? String,
                        avatarTitle: data["avatarTitle"] as? String
                    )
                }
                completion(players)
            }
    }
    
    // MARK: - Observe Room State (for lobby → game transition)
    func observeState(inRoom roomCode: String, completion: @escaping (_ round: Int, _ rumbleCount: Int) -> Void) -> ListenerRegistration {
        return Firestore.firestore()
            .collection("rooms")
            .document(roomCode)
            .addSnapshotListener { snapshot, error in
                guard let data = snapshot?.data() else { return }
                
                let state = data["state"] as? String ?? "lobby"
                
                // Only trigger when game has started
                if state == "playing" {
                    let round = data["currentRound"] as? Int ?? 1
                    let rumble = data["rumbleCount"] as? Int ?? 3
                    completion(round, rumble)
                }
            }
    }
    
    // MARK: - HOST ONLY: Assign Roles and Start Round
    func hostAssignRolesAndStartRound(roomCode: String, players: [Player], completion: @escaping (Error?) -> Void) {
        guard isHost || players.first(where: { $0.id == currentUserID })?.isHost == true else {
            print("⚠️ Only host can start the game")
            completion(NSError(domain: "RoomManager", code: 403, userInfo: [NSLocalizedDescriptionKey: "Only host can start"]))
            return
        }
        
        guard players.count >= 2 else {
            print("⚠️ Need at least 2 players")
            completion(NSError(domain: "RoomManager", code: 400, userInfo: [NSLocalizedDescriptionKey: "Need at least 2 players"]))
            return
        }
        
        // Randomly select imposter
        let playerIDs = players.map { $0.id }
        let imposterID = playerIDs.randomElement()!
        
        // Assign roles
        var roles: [String: String] = [:]
        for id in playerIDs {
            roles[id] = (id == imposterID) ? "imposter" : "crewmate"
        }
        
        // Cache roles locally
        cachedRoles = roles
        
        // Generate random rumble count
        let rumbleCount = Int.random(in: 2...5)
        
        print("👑 [HOST] Assigning roles:")
        print("   - Imposter: \(String(imposterID.prefix(8)))")
        print("   - Rumble count: \(rumbleCount)")
        
        // Update Firestore
        let roomData: [String: Any] = [
            "state": "playing",
            "currentRound": 1,
            "rumbleCount": rumbleCount,
            "roles": roles,
            "imposterID": imposterID,
            "startedAt": FieldValue.serverTimestamp()
        ]
        
        Firestore.firestore()
            .collection("rooms")
            .document(roomCode)
            .updateData(roomData, completion: completion)
    }
    
    // MARK: - Update Game State (Host Only)
    func updateGameState(roomCode: String, gameState: [String: Any], completion: ((Error?) -> Void)? = nil) {
        guard isHost else {
            print("⚠️ Only host can update game state")
            completion?(nil)
            return
        }
        
        var stateData = gameState
        stateData["updatedAt"] = FieldValue.serverTimestamp()
        stateData["updatedBy"] = currentUserID
        
        Firestore.firestore()
            .collection("rooms")
            .document(roomCode)
            .updateData(["gameState": stateData], completion: completion)
    }
    
    // MARK: - Observe Game State (All Players)
    func observeGameState(roomCode: String, completion: @escaping ([String: Any]?) -> Void) -> ListenerRegistration {
        return Firestore.firestore()
            .collection("rooms")
            .document(roomCode)
            .addSnapshotListener { snapshot, error in
                guard let data = snapshot?.data(),
                      let gameState = data["gameState"] as? [String: Any] else {
                    completion(nil)
                    return
                }
                completion(gameState)
            }
    }
    
    // MARK: - Clear Game Data
    func clearGameData(roomCode: String, completion: ((Error?) -> Void)? = nil) {
        let db = Firestore.firestore()
        let roomRef = db.collection("rooms").document(roomCode)
        
        // Clear guesses
        roomRef.collection("guesses").getDocuments { snap, _ in
            guard let docs = snap?.documents else { return }
            let batch = db.batch()
            for doc in docs {
                batch.deleteDocument(doc.reference)
            }
            batch.commit(completion: nil)
        }
        
        // Clear votes
        roomRef.collection("votes").getDocuments { snap, _ in
            guard let docs = snap?.documents else { return }
            let batch = db.batch()
            for doc in docs {
                batch.deleteDocument(doc.reference)
            }
            batch.commit(completion: nil)
        }
        
        // Reset room state
        roomRef.updateData([
            "state": "lobby",
            "currentRound": 0,
            "roles": FieldValue.delete(),
            "gameState": FieldValue.delete()
        ], completion: completion)
        
        // Clear cached roles
        cachedRoles = [:]
    }
}
