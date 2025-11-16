import Foundation
import FirebaseFirestore

class RoomManager {
    static let shared = RoomManager()
    private init() {}

    private let db = Firestore.firestore()

    enum RoomError: Error {
        case message(String)
    }

    struct Player {
        let id: String
        let name: String
        let isHost: Bool
    }

    // Identifies THIS device/user
    var currentUserID: String = UUID().uuidString

    // Cached roles from Firestore
    var cachedRoles: [String: String] = [:]

    // CREATE ROOM
    func createRoom(hostName: String? = nil,
                    completion: @escaping (Result<String, RoomError>) -> Void) {

        let code = String(format: "%06d", Int.random(in: 0...999999))

        // FIX: Create ONE host ID — used everywhere
        let hostID = UUID().uuidString
        self.currentUserID = hostID

        // Room document
        let roomData: [String: Any] = [
            "createdAt": Timestamp(date: Date()),
            "expiresAt": Timestamp(date: Date().addingTimeInterval(1800)),
            "hostID": hostID,
            "hostName": hostName ?? NSNull()
        ]

        let roomRef = db.collection("rooms").document(code)

        roomRef.setData(roomData) { error in
            if let error = error {
                completion(.failure(.message("Room error: \(error.localizedDescription)")))
                return
            }

            // Add host as player
            if let host = hostName {
                self.addPlayer(
                    id: hostID,
                    name: host,
                    isHost: true,
                    to: code
                ) { result in
                    completion(.success(code))
                }
            } else {
                completion(.success(code))
            }
        }
    }


    // JOIN ROOM
    func joinRoom(withCode code: String, completion: @escaping (Result<Void, RoomError>) -> Void) {
        let ref = db.collection("rooms").document(code)

        ref.getDocument { doc, err in

            if let err = err {
                completion(.failure(.message(err.localizedDescription)))
                return
            }

            guard let doc = doc, doc.exists else {
                completion(.failure(.message("Room not found")))
                return
            }

            completion(.success(()))
        }
    }

    // ADD PLAYER
    func addPlayer(id: String = UUID().uuidString,
                   name: String,
                   isHost: Bool = false,
                   to roomCode: String,
                   completion: ((Result<Void, RoomError>) -> Void)? = nil) {

        currentUserID = id

        let data: [String: Any] = [
            "name": name,
            "isHost": isHost
        ]

        db.collection("rooms")
            .document(roomCode)
            .collection("players")
            .document(id)
            .setData(data) { err in
                if let err = err {
                    completion?(.failure(.message(err.localizedDescription)))
                } else {
                    completion?(.success(()))
                }
            }
    }

    // OBSERVE PLAYERS
    func observePlayers(inRoom code: String,
                        onChange: @escaping ([Player]) -> Void) -> ListenerRegistration {

        return db.collection("rooms")
            .document(code)
            .collection("players")
            .addSnapshotListener { snap, err in

                guard let docs = snap?.documents else {
                    onChange([])
                    return
                }

                let players = docs.compactMap { doc -> Player? in
                    let d = doc.data()
                    guard let name = d["name"] as? String,
                          let host = d["isHost"] as? Bool else { return nil }

                    return Player(id: doc.documentID, name: name, isHost: host)
                }

                onChange(players)
            }
    }
}
