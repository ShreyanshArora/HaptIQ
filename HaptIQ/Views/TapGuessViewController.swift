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
    private var currentRound: Int  // NEW: Track current round

    private var myTapCount = 0
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

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

    deinit { listener?.remove() }

    override func viewDidLoad() {
        super.viewDidLoad()
        layoutUI()
        updateRoundLabel()
        addBackButton()
        setupTapGesture()
        submitButton.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
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

    @objc private func onBack() { navigationController?.popViewController(animated: true) }

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

        listenForResults()
        submitButton.isEnabled = false
        submitButton.alpha = 0.6
    }

    private func listenForResults() {
        listener?.remove()
        listener = db.collection("rooms")
            .document(roomCode)
            .collection("guesses")
            .addSnapshotListener { [weak self] snap, _ in
                guard let self = self else { return }
                guard let docs = snap?.documents else { return }
                if docs.count >= self.players.count {
                    let results = docs.map { $0.data() }
                    self.evaluateResults(results)
                }
            }
    }

    // MARK: Result Evaluation
    private func evaluateResults(_ guesses: [[String: Any]]) {

        var imposterID = ""
        for (id, role) in RoomManager.shared.cachedRoles {
            if role == "imposter" { imposterID = id }
        }

        var imposterWrong = false
        var crewmatesWrong: [String] = []

        for g in guesses {
            let id = g["playerID"] as? String ?? ""
            let tap = g["tapCount"] as? Int ?? 0
            let correct = g["rumbleCount"] as? Int ?? rumbleCount

            if id == imposterID {
                if tap != correct { imposterWrong = true }
            } else {
                if tap != correct { crewmatesWrong.append(id) }
            }
        }

        // Clear guesses for next round
        clearGuesses()

        // 🎯 NEW LOGIC: Handle results based on who was wrong
        
        if imposterWrong {
            // Imposter guessed wrong → Go to voting
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

        if !crewmatesWrong.isEmpty {
            // Crewmate(s) guessed wrong → They're eliminated, go to spectator
            let myID = RoomManager.shared.currentUserID
            if crewmatesWrong.contains(myID) {
                // I was wrong, I'm eliminated
                DispatchQueue.main.async {
                    self.navigationController?.pushViewController(
                        SpectatorViewController(),
                        animated: true
                    )
                }
            } else {
                // Someone else was wrong, continue game
                checkRoundLimitOrContinue()
            }
            return
        }

        // Everyone guessed correctly (including imposter) → Check round limit
        checkRoundLimitOrContinue()
    }
    
    private func checkRoundLimitOrContinue() {
        let maxRounds = getMaxRounds()
        
        if currentRound >= maxRounds {
            // Max rounds reached → Force voting
            DispatchQueue.main.async {
                let vc = VotingViewController(
                    roomCode: self.roomCode,
                    players: self.players,
                    currentRound: self.currentRound
                )
                self.navigationController?.pushViewController(vc, animated: true)
            }
        } else {
            // Continue to next round
            let nextR = Int.random(in: 2...5)
            DispatchQueue.main.async {
                let vc = HapticsRoomViewController(
                    roomCode: self.roomCode,
                    players: self.players,
                    rumbleCount: nextR,
                    role: self.myRole
                )
                // Pass the incremented round number
                vc.currentRound = self.currentRound + 1
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
    private func clearGuesses() {
        // Clear the guesses subcollection for next round
        db.collection("rooms")
            .document(roomCode)
            .collection("guesses")
            .getDocuments { snap, _ in
                guard let docs = snap?.documents else { return }
                let batch = self.db.batch()
                for doc in docs {
                    batch.deleteDocument(doc.reference)
                }
                batch.commit()
            }
    }
}
