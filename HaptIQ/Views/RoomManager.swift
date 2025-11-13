import Foundation
import FirebaseFirestore

class RoomManager {  // this is room manager
    static let shared = RoomManager()

    private init() {}
    private let db = Firestore.firestore()
    
    enum RoomError: Error {
        case message(String)
    }

    func createRoom(completion: @escaping (Result<String, RoomError>) -> Void) {
        let code = String(format: "%06d", Int.random(in: 0...999999))
        let expiresAt = Date().addingTimeInterval(30 * 60) // 30 minutes
        
        let data: [String: Any] = [
            "createdAt": Timestamp(date: Date()),
            "expiresAt": Timestamp(date: expiresAt)
        ]
        
        db.collection("rooms").document(code).setData(data) { error in
            if let error = error {
                completion(.failure(.message("❌ Failed to create room: \(error.localizedDescription)")))
            } else {
                print("✅ Room created with code: \(code)")
                completion(.success(code))
            }
        }
    }

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
            
            print("✅ Joined room: \(code)")
            completion(.success(()))
        }
    }
}
