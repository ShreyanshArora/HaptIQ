import Foundation
import FirebaseFirestore

final class RoomManager {
    
    static let shared = RoomManager()
    private init() {}
    
    var currentUserID: String = UUID().uuidString
    var cachedRoles: [String: String] = [:]
    
    // MARK: - Player Model
    struct Player {
        let id: String
        let name: String
        let isHost: Bool
        let avatarImage: String?
        let avatarTitle: String?
    }
    
    // MARK: - Create Room
    func createRoom(completion: @escaping (Result<String, Error>) -> Void) {
        let code = generateRoomCode()
        let hostID = currentUserID
        
        let roomData: [String: Any] = [
            "code": code,
            "hostID": hostID,
            "createdAt": FieldValue.serverTimestamp(),
            "state": "lobby",
            "currentRound": 0
        ]
        
        let db = Firestore.firestore()
        
        // Create room document
        db.collection("rooms").document(code).setData(roomData) { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            // Create host player document (without name/avatar yet - will be set in EnterNameViewController)
            db.collection("rooms")
                .document(code)
                .collection("players")
                .document(hostID)
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
        
        // Check if room exists
        db.collection("rooms").document(code).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let snapshot = snapshot, snapshot.exists else {
                let error = NSError(domain: "RoomManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "Room not found"])
                completion(.failure(error))
                return
            }
            
            // Room exists
            completion(.success(true))
        }
    }
    
    // MARK: - Add Player
    func addPlayer(id: String, name: String, isHost: Bool, to roomCode: String, completion: @escaping (Error?) -> Void) {
        // Get avatar data from UserDefaults
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
                    guard let name = data["name"] as? String else { return nil }
                    let isHost = data["isHost"] as? Bool ?? false
                    let avatarImage = data["avatarImage"] as? String
                    let avatarTitle = data["avatarTitle"] as? String
                    
                    return Player(
                        id: doc.documentID,
                        name: name,
                        isHost: isHost,
                        avatarImage: avatarImage,
                        avatarTitle: avatarTitle
                    )
                }
                
                completion(players)
            }
    }
    
    // MARK: - Observe Room State
    func observeState(inRoom roomCode: String, completion: @escaping (Int, Int?) -> Void) -> ListenerRegistration {
        return Firestore.firestore()
            .collection("rooms")
            .document(roomCode)
            .addSnapshotListener { snapshot, error in
                guard let data = snapshot?.data() else { return }
                
                let round = data["currentRound"] as? Int ?? 0
                let rumble = data["rumbleCount"] as? Int
                
                completion(round, rumble)
            }
    }
    
    // MARK: - Host Assign Roles and Start Round
    func hostAssignRolesAndStartRound(roomCode: String, players: [Player], completion: @escaping (Error?) -> Void) {
        guard players.count >= 3 else {
            let error = NSError(domain: "RoomManager", code: 400, userInfo: [NSLocalizedDescriptionKey: "Need at least 3 players"])
            completion(error)
            return
        }
        
        // Randomly assign one imposter
        let shuffled = players.shuffled()
        let imposterID = shuffled[0].id
        
        var roles: [String: String] = [:]
        for player in players {
            roles[player.id] = (player.id == imposterID) ? "imposter" : "crewmate"
        }
        
        // Generate random rumble count (e.g., 3-6)
        let rumbleCount = Int.random(in: 3...6)
        
        let updateData: [String: Any] = [
            "currentRound": 1,
            "state": "playing",
            "roles": roles,
            "rumbleCount": rumbleCount,
            "startedAt": FieldValue.serverTimestamp()
        ]
        
        Firestore.firestore()
            .collection("rooms")
            .document(roomCode)
            .setData(updateData, merge: true, completion: completion)
    }
    
    // MARK: - Submit Vote
    func submitVote(roomCode: String, voterID: String, suspectID: String, completion: @escaping (Error?) -> Void) {
        let voteData: [String: Any] = [
            "voterID": voterID,
            "suspectID": suspectID,
            "timestamp": FieldValue.serverTimestamp()
        ]
        
        Firestore.firestore()
            .collection("rooms")
            .document(roomCode)
            .collection("votes")
            .document(voterID)
            .setData(voteData, completion: completion)
    }
    
    // MARK: - Observe Votes
    func observeVotes(inRoom roomCode: String, completion: @escaping ([String: String]) -> Void) -> ListenerRegistration {
        return Firestore.firestore()
            .collection("rooms")
            .document(roomCode)
            .collection("votes")
            .addSnapshotListener { snapshot, error in
                guard let docs = snapshot?.documents else {
                    completion([:])
                    return
                }
                
                var votes: [String: String] = [:]
                for doc in docs {
                    if let voterID = doc.data()["voterID"] as? String,
                       let suspectID = doc.data()["suspectID"] as? String {
                        votes[voterID] = suspectID
                    }
                }
                
                completion(votes)
            }
    }
    
    // MARK: - Calculate Vote Results
    func calculateVoteResults(votes: [String: String]) -> (mostVotedID: String?, voteCount: Int) {
        guard !votes.isEmpty else { return (nil, 0) }
        
        // Count votes for each suspect
        var voteCounts: [String: Int] = [:]
        for (_, suspectID) in votes {
            voteCounts[suspectID, default: 0] += 1
        }
        
        // Find the suspect with most votes
        let sorted = voteCounts.sorted { $0.value > $1.value }
        guard let top = sorted.first else { return (nil, 0) }
        
        return (top.key, top.value)
    }
    
    // MARK: - End Round
    func endRound(roomCode: String, completion: @escaping (Error?) -> Void) {
        let updateData: [String: Any] = [
            "state": "ended",
            "endedAt": FieldValue.serverTimestamp()
        ]
        
        Firestore.firestore()
            .collection("rooms")
            .document(roomCode)
            .setData(updateData, merge: true, completion: completion)
    }
    
    // MARK: - Clear Votes
    func clearVotes(roomCode: String, completion: @escaping (Error?) -> Void) {
        let db = Firestore.firestore()
        let votesRef = db.collection("rooms").document(roomCode).collection("votes")
        
        votesRef.getDocuments { snapshot, error in
            if let error = error {
                completion(error)
                return
            }
            
            guard let docs = snapshot?.documents else {
                completion(nil)
                return
            }
            
            let batch = db.batch()
            for doc in docs {
                batch.deleteDocument(doc.reference)
            }
            
            batch.commit(completion: completion)
        }
    }
    
    // MARK: - Delete Room
    func deleteRoom(code: String, completion: @escaping (Error?) -> Void) {
        let db = Firestore.firestore()
        let roomRef = db.collection("rooms").document(code)
        
        // Delete all players
        roomRef.collection("players").getDocuments { snapshot, error in
            if let error = error {
                completion(error)
                return
            }
            
            let batch = db.batch()
            
            // Delete all player documents
            snapshot?.documents.forEach { batch.deleteDocument($0.reference) }
            
            // Delete all votes
            roomRef.collection("votes").getDocuments { voteSnapshot, _ in
                voteSnapshot?.documents.forEach { batch.deleteDocument($0.reference) }
                
                // Delete the room itself
                batch.deleteDocument(roomRef)
                
                batch.commit(completion: completion)
            }
        }
    }
    
    // MARK: - Leave Room
    func leaveRoom(roomCode: String, playerID: String, completion: @escaping (Error?) -> Void) {
        Firestore.firestore()
            .collection("rooms")
            .document(roomCode)
            .collection("players")
            .document(playerID)
            .delete(completion: completion)
    }
    
    // MARK: - Helper: Generate Room Code
    private func generateRoomCode() -> String {
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<6).map { _ in letters.randomElement()! })
    }
    
    // MARK: - Get Room Info
    func getRoomInfo(code: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        Firestore.firestore()
            .collection("rooms")
            .document(code)
            .getDocument { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let data = snapshot?.data() else {
                    let error = NSError(domain: "RoomManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "Room not found"])
                    completion(.failure(error))
                    return
                }
                
                completion(.success(data))
            }
    }
    
    // MARK: - Update Player Status
    func updatePlayerStatus(roomCode: String, playerID: String, status: [String: Any], completion: @escaping (Error?) -> Void) {
        Firestore.firestore()
            .collection("rooms")
            .document(roomCode)
            .collection("players")
            .document(playerID)
            .setData(status, merge: true, completion: completion)
    }
}
