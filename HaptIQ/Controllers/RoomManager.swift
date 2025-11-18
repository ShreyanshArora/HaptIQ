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
    // persisted for lifetime of app run — updated when user creates or joins
    var currentUserID: String = UUID().uuidString

    // Cached roles from Firestore
    var cachedRoles: [String: String] = [:]

    // CREATE ROOM (creates room doc + adds host player)
    func createRoom(hostName: String? = nil,
                    completion: @escaping (Result<String, RoomError>) -> Void) {

        let code = String(format: "%06d", Int.random(in: 0...999999))

        let roomRef = db.collection("rooms").document(code)

        var data: [String: Any] = [
            "createdAt": Timestamp(date: Date()),
            "expiresAt": Timestamp(date: Date().addingTimeInterval(1800))
        ]

        // hostName OPTIONAL
        if let hostName = hostName {
            data["hostName"] = hostName
        }

        roomRef.setData(data) { err in
            if let err = err {
                completion(.failure(.message(err.localizedDescription)))
                return
            }

            completion(.success(code))
        }
    }

    // JOIN ROOM (checks room exists)
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

    // ADD PLAYER (sets currentUserID)
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

    // OBSERVE PLAYERS (realtime)
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

    // ONE-TIME fetch players
    func fetchPlayersOnce(inRoom code: String, completion: @escaping ([Player]) -> Void) {
        db.collection("rooms")
            .document(code)
            .collection("players")
            .getDocuments { snap, _ in
                guard let docs = snap?.documents else { completion([]); return }
                let players = docs.compactMap { doc -> Player? in
                    let d = doc.data()
                    guard let name = d["name"] as? String,
                          let host = d["isHost"] as? Bool else { return nil }
                    return Player(id: doc.documentID, name: name, isHost: host)
                }
                completion(players)
            }
    }

    // Observe room state (round, rumbleCount) that host writes
    func observeState(inRoom code: String, onChange: @escaping (_ round: Int?, _ rumbleCount: Int?) -> Void) -> ListenerRegistration {
        return db.collection("rooms").document(code)
            .addSnapshotListener { snap, _ in
                guard let data = snap?.data() else {
                    onChange(nil, nil)
                    return
                }
                if let state = data["state"] as? [String: Any] {
                    let round = state["round"] as? Int
                    let rumble = state["rumbleCount"] as? Int
                    onChange(round, rumble)
                } else {
                    onChange(nil, nil)
                }
            }
    }

    // Host starts a new round: assigns roles and sets rumbleCount in state
    func hostAssignRolesAndStartRound(roomCode: String, players: [Player], completion: ((Error?) -> Void)? = nil) {
        guard players.count >= 2 else {
            completion?(RoomError.message("Need at least 2 players") as? Error)
            return
        }

        // choose imposter
        guard let imp = players.randomElement() else {
            completion?(RoomError.message("No players") as? Error)
            return
        }

        var roleDict: [String: String] = [:]
        for p in players {
            roleDict[p.id] = (p.id == imp.id) ? "imposter" : "crewmate"
        }

        // choose rumbleCount for round
        let rumble = Int.random(in: 2...5)

        let roomRef = db.collection("rooms").document(roomCode)
        let batch = db.batch()
        // update roles
        batch.updateData(["roles": roleDict], forDocument: roomRef)
        // update state
        let newState: [String: Any] = [
            "state.round": FieldValue.increment(Int64(1)),
            "state.rumbleCount": rumble
        ]
        // Firestore can't update nested keys with batch.updateData same way - we'll just call update twice
        roomRef.updateData(["roles": roleDict]) { err in
            if let err = err {
                completion?(err)
                return
            }
            roomRef.setData(["state": ["round": FieldValue.increment(Int64(1)), "rumbleCount": rumble]], merge: true) { err in
                completion?(err)
            }
        }
    }
}
