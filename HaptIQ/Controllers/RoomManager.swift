import Foundation
import FirebaseFirestore

class RoomManager {
    static let shared = RoomManager()
    private init() {}
    
    private let db = Firestore.firestore()
    
    enum RoomError: Error {
        case message(String)
    }
    
    // MARK: - Player Model (FIXED)
    struct Player {
        let id: String        // <-- Firestore documentID
        let name: String
        let isHost: Bool
    }
    
    // MARK: - NEW PROPERTIES (FIX ERRORS)
    var currentUserID: String = UUID().uuidString       // Set when user joins room
    var cachedRoles: [String: String] = [:]             // Stores "imposter"/"crewmate"
    
    
    // MARK: - Create Room
    func createRoom(hostName: String? = nil, completion: @escaping (Result<String, RoomError>) -> Void) {
        let code = String(format: "%06d", Int.random(in: 0...999999))
        let expiresAt = Date().addingTimeInterval(30 * 60) // 30 minutes
        
        let roomData: [String: Any] = [
            "createdAt": Timestamp(date: Date()),
            "expiresAt": Timestamp(date: expiresAt),
            "hostName": hostName ?? NSNull()
        ]
        
        let roomRef = db.collection("rooms").document(code)
        roomRef.setData(roomData) { [weak self] error in
            if let error = error {
                completion(.failure(.message("❌ Failed to create room: \(error.localizedDescription)")))
            } else {
                if let host = hostName {
                    self?.currentUserID = UUID().uuidString
                    self?.addPlayer(id: self!.currentUserID, name: host, isHost: true, to: code) { _ in
                        completion(.success(code))
                    }
                } else {
                    completion(.success(code))
                }
            }
        }
    }
    
    
    // MARK: - Join Room
    func joinRoom(withCode code: String, completion: @escaping (Result<Void, RoomError>) -> Void) {
        let roomRef = db.collection("rooms").document(code)
        roomRef.getDocument { document, error in
            if let error = error {
                completion(.failure(.message("❌ Error checking room: \(error.localizedDescription)")))
                return
            }
            
            guard let document = document, document.exists else {
                completion(.failure(.message("❌ Room not found!")))
                return
            }
            
            guard let expiresAt = document.data()?["expiresAt"] as? Timestamp else {
                completion(.failure(.message("⚠️ Invalid room data.")))
                return
            }
            
            if expiresAt.dateValue() < Date() {
                roomRef.delete { _ in
                    completion(.failure(.message("⏰ Room expired!")))
                }
                return
            }
            
            completion(.success(()))
        }
    }
    
    
    // MARK: - Add Player
    func addPlayer(
        id: String = UUID().uuidString,
        name: String,
        isHost: Bool = false,
        to roomCode: String,
        completion: ((Result<Void, RoomError>) -> Void)? = nil
    ) {
        currentUserID = id
        
        let playerData: [String: Any] = [
            "name": name,
            "isHost": isHost
        ]
        
        db.collection("rooms")
            .document(roomCode)
            .collection("players")
            .document(id)
            .setData(playerData) { error in
                if let err = error {
                    completion?(.failure(.message("❌ Failed to add player: \(err.localizedDescription)")))
                } else {
                    completion?(.success(()))
                }
            }
    }
    
    
    // MARK: - Observe Players
    func observePlayers(inRoom code: String, onChange: @escaping ([Player]) -> Void) -> ListenerRegistration {
        return db.collection("rooms")
            .document(code)
            .collection("players")
            .addSnapshotListener { snapshot, error in
                
                guard let docs = snapshot?.documents, error == nil else {
                    onChange([])
                    return
                }
                
                let players = docs.compactMap { doc -> Player? in
                    let data = doc.data()
                    guard let name = data["name"] as? String,
                          let isHost = data["isHost"] as? Bool else { return nil }
                    
                    return Player(
                        id: doc.documentID,
                        name: name,
                        isHost: isHost
                    )
                }
                
                onChange(players)
            }
    }
}
