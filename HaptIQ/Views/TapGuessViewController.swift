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

    private var myTapCount = 0
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    // UI
    private let bgImage: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "bgHex"))
        iv.contentMode = .scaleAspectFill
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let counterLabel: UILabel = {
        let l = UILabel()
        l.text = "0"
        l.font = UIFont(name: "WinniePERSONALUSE", size: 80)
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
    init(roomCode: String, rumbleCount: Int, myRole: HapticsRoomViewController.PlayerRole, players: [RoomManager.Player]) {
        self.roomCode = roomCode
        self.rumbleCount = rumbleCount
        self.myRole = myRole
        self.players = players
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("not allowed") }

    deinit { listener?.remove() }

    override func viewDidLoad() {
        super.viewDidLoad()
        layoutUI()
        addBackButton()
        setupTapGesture()
        submitButton.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
    }

    // MARK: UI Layout
    private func layoutUI() {
        view.addSubview(bgImage)
        view.addSubview(tapArea)
        view.addSubview(counterLabel)
        view.addSubview(submitButton)

        NSLayoutConstraint.activate([
            bgImage.topAnchor.constraint(equalTo: view.topAnchor),
            bgImage.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bgImage.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bgImage.trailingAnchor.constraint(equalTo: view.trailingAnchor),

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

        if imposterWrong {
            navigationController?.pushViewController(
                VotingViewController(roomCode: roomCode, players: players),
                animated: true
            )
            return
        }

        if !crewmatesWrong.isEmpty {
            navigationController?.pushViewController(
                SpectatorViewController(),
                animated: true
            )
            return
        }

        // everyone correct → next round
        let nextR = Int.random(in: 2...5)
        let vc = HapticsRoomViewController(
            roomCode: roomCode,
            players: players,
            rumbleCount: nextR,
            role: myRole
        )
        navigationController?.pushViewController(vc, animated: true)
    }
}
