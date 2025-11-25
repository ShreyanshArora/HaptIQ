//
//  TapGuessViewController.swift
//  HaptIQ
//

import UIKit
import FirebaseFirestore

final class TapGuessViewController: UIViewController {

    private let roomCode: String
    private let rumbleCount: Int
    private let myRole: HapticsRoomViewController.PlayerRole
    private var players: [RoomManager.Player]
    private var currentRound: Int

    private var myTapCount = 0
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private var hasProcessedResults = false  // 🔧 Prevent duplicate processing

    // UI
    private let bgImage: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "bghex"))
        iv.contentMode = .scaleAspectFill
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let roundLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "Aclonica-Regular", size: 24)
        l.textColor = .white
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let counterLabel: UILabel = {
        let l = UILabel()
        l.text = "0"
        l.font = UIFont(name: "Aclonica-Regular", size: 80)
        l.textColor = .white
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let tapArea: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.white.withAlphaComponent(0.06)
        v.layer.cornerRadius = 25
        v.layer.borderWidth = 2
        v.layer.borderColor = UIColor.white.withAlphaComponent(0.20).cgColor
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let submitButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("SUBMIT", for: .normal)
        b.backgroundColor = UIColor(red: 21/255, green: 174/255, blue: 21/255, alpha: 1)
        b.setTitleColor(.white, for: .normal)
        b.layer.cornerRadius = 20
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    // MARK: - Init
    init(roomCode: String, rumbleCount: Int, myRole: HapticsRoomViewController.PlayerRole, players: [RoomManager.Player], currentRound: Int = 1) {
        self.roomCode = roomCode
        self.rumbleCount = rumbleCount
        self.myRole = myRole
        self.players = players
        self.currentRound = currentRound
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("not allowed") }

    deinit {
        listener?.remove()
        print("🗑️ TapGuessViewController deallocated")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        layoutUI()
        updateRoundLabel()
        addBackButton()
        setupTapGesture()
        submitButton.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
        
        print("📱 TapGuessViewController loaded - Round \(currentRound), Players: \(players.count), Rumbles: \(rumbleCount)")
    }

    // MARK: UI Layout
    private func layoutUI() {
        view.addSubview(bgImage)
        view.addSubview(roundLabel)
        view.addSubview(tapArea)
        view.addSubview(counterLabel)
        view.addSubview(submitButton)

        NSLayoutConstraint.activate([
            bgImage.topAnchor.constraint(equalTo: view.topAnchor),
            bgImage.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bgImage.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bgImage.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            roundLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            roundLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            tapArea.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            tapArea.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            tapArea.widthAnchor.constraint(equalToConstant: 320),
            tapArea.heightAnchor.constraint(equalToConstant: 320),

            counterLabel.centerXAnchor.constraint(equalTo: tapArea.centerXAnchor),
            counterLabel.centerYAnchor.constraint(equalTo: tapArea.centerYAnchor),

            submitButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            submitButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            submitButton.widthAnchor.constraint(equalToConstant: 220),
            submitButton.heightAnchor.constraint(equalToConstant: 55)
        ])
    }
    
    private func updateRoundLabel() {
        let maxRounds = getMaxRounds()
        roundLabel.text = "Round \(currentRound) / \(maxRounds)"
    }
    
    // MARK: - Game Rules
    private func getMaxRounds() -> Int {
        let playerCount = players.count
        if playerCount >= 5 {
            return 3
        } else if playerCount >= 3 {
            return 2
        } else {
            return 1
        }
    }

    @objc private func onBack() {
        navigationController?.popViewController(animated: true)
    }

    // MARK: Tap Logic
    private func setupTapGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tapArea.addGestureRecognizer(tap)
    }

    @objc private func handleTap() {
        myTapCount += 1
        counterLabel.text = "\(myTapCount)"
        HapticsEngineManager.shared.playRumble()
    }

    // MARK: Submit
    @objc private func submitTapped() {
        let uid = RoomManager.shared.currentUserID

        db.collection("rooms")
            .document(roomCode)
            .collection("guesses")
            .document(uid)
            .setData([
                "tapCount": myTapCount,
                "rumbleCount": rumbleCount,
                "playerID": uid
            ], merge: true)

        print("✅ Submitted guess - Taps: \(myTapCount), Expected: \(rumbleCount)")
        listenForResults()
        submitButton.isEnabled = false
        submitButton.alpha = 0.6
    }

    private func listenForResults() {
        guard !hasProcessedResults else {
            print("⚠️ Already processed results, skipping listener")
            return
        }
        
        listener?.remove()
        listener = db.collection("rooms")
            .document(roomCode)
            .collection("guesses")
            .addSnapshotListener { [weak self] snap, error in
                guard let self = self else { return }
                guard !self.hasProcessedResults else {
                    print("⚠️ Listener fired but already processed")
                    return
                }
                
                if let error = error {
                    print("❌ Listener error: \(error)")
                    return
                }
                
                guard let docs = snap?.documents else { return }
                
                print("📊 Guesses received: \(docs.count)/\(self.players.count)")
                
                if docs.count >= self.players.count {
                    self.hasProcessedResults = true
                    self.listener?.remove()
                    let results = docs.map { $0.data() }
                    self.evaluateResults(results)
                }
            }
    }

    // MARK: Result Evaluation
    private func evaluateResults(_ guesses: [[String: Any]]) {
        print("\n🎯 === EVALUATING ROUND \(currentRound) ===")
        
        var imposterID = ""
        for (id, role) in RoomManager.shared.cachedRoles {
            if role == "imposter" {
                imposterID = id
                print("🎭 Imposter ID: \(id)")
            }
        }

        var imposterWrong = false
        var crewmatesWrong: [String] = []

        for g in guesses {
            let id = g["playerID"] as? String ?? ""
            let tap = g["tapCount"] as? Int ?? 0
            let correct = g["rumbleCount"] as? Int ?? rumbleCount

            let isCorrect = tap == correct
            print("👤 Player \(id.prefix(4)): guessed \(tap), correct: \(correct), ✓: \(isCorrect)")

            if id == imposterID {
                if tap != correct { imposterWrong = true }
            } else {
                if tap != correct { crewmatesWrong.append(id) }
            }
        }

        print("📈 Imposter wrong: \(imposterWrong), Crewmates wrong: \(crewmatesWrong.count)")

        clearGuesses()

        // 🎯 FIXED GAME LOGIC - Imposter has advantage when correct
        
        let maxRounds = getMaxRounds()
        let myID = RoomManager.shared.currentUserID
        
        // Case 1: Imposter guessed WRONG → Always go to voting
        if imposterWrong {
            print("🎲 Case 1: Imposter guessed wrong → Voting")
            DispatchQueue.main.async {
                let vc = VotingViewController(
                    roomCode: self.roomCode,
                    players: self.players,
                    currentRound: self.currentRound
                )
                self.navigationController?.pushViewController(vc, animated: true)
            }
            return
        }
        
        // Case 2: Imposter CORRECT + Some crewmates wrong
        if !crewmatesWrong.isEmpty {
            print("🎲 Case 2: Imposter correct, \(crewmatesWrong.count) crewmate(s) wrong")
            
            // 🔧 Filter out eliminated players for next round
            let survivingPlayers = players.filter { player in
                let survived = !crewmatesWrong.contains(player.id)
                if !survived {
                    print("💀 Eliminated: \(player.name) (\(player.id.prefix(4)))")
                }
                return survived
            }
            
            print("✅ Surviving players: \(survivingPlayers.count)")
            
            // Check if this is the last round
            if currentRound >= maxRounds {
                print("🏆 Last round + imposter correct → IMPOSTER WINS")
                DispatchQueue.main.async {
                    let vc = GameResultViewController(
                        crewmatesWon: false,
                        roomCode: self.roomCode
                    )
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            } else {
                // Not last round
                if crewmatesWrong.contains(myID) {
                    print("💀 I was eliminated → Spectator mode")
                    DispatchQueue.main.async {
                        let vc = SpectatorViewController()
                        self.navigationController?.pushViewController(vc, animated: true)
                    }
                } else {
                    print("✅ I survived → Next round")
                    continueToNextRound(with: survivingPlayers)
                }
            }
            return
        }
        
        // Case 3: Everyone correct (including imposter)
        print("🎲 Case 3: Everyone guessed correctly")
        
        if currentRound >= maxRounds {
            print("📊 Last round reached → Forced voting")
            DispatchQueue.main.async {
                let vc = VotingViewController(
                    roomCode: self.roomCode,
                    players: self.players,
                    currentRound: self.currentRound
                )
                self.navigationController?.pushViewController(vc, animated: true)
            }
        } else {
            print("➡️ Continuing to round \(self.currentRound + 1)")
            continueToNextRound(with: players)
        }
        
        print("=== END EVALUATION ===\n")
    }

    // 🔧 Updated to accept filtered player list
    private func continueToNextRound(with activePlayers: [RoomManager.Player]) {
        let nextR = Int.random(in: 2...5)
        print("🎮 Next round: \(currentRound + 1), Rumbles: \(nextR), Active players: \(activePlayers.count)")
        
        DispatchQueue.main.async {
            let vc = HapticsRoomViewController(
                roomCode: self.roomCode,
                players: activePlayers,  // 🔧 Pass only surviving players
                rumbleCount: nextR,
                role: self.myRole
            )
            vc.currentRound = self.currentRound + 1
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    private func clearGuesses() {
        db.collection("rooms")
            .document(roomCode)
            .collection("guesses")
            .getDocuments { snap, _ in
                guard let docs = snap?.documents else { return }
                let batch = self.db.batch()
                for doc in docs {
                    batch.deleteDocument(doc.reference)
                }
                batch.commit { error in
                    if let error = error {
                        print("❌ Error clearing guesses: \(error)")
                    } else {
                        print("🧹 Cleared \(docs.count) guesses")
                    }
                }
            }
    }
}
