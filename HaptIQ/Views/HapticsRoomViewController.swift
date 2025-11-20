//
//  HapticsRoomViewController.swift
//  HaptIQ
//

import UIKit
import FirebaseFirestore

final class HapticsRoomViewController: UIViewController {

    // MARK: - Public game inputs
    var roomCode: String
    var rumbleCount: Int = 0            // updated from Firestore
    var players: [RoomManager.Player] = []
    var role: PlayerRole

    enum PlayerRole { case crewmate, imposter }

    // MARK: - Internal state
    private var sentRumbles: Int = 0
    private var timer: Timer?
    private var secondsLeft = 10
    private var inRound = false
    private var stateListener: ListenerRegistration?

    // MARK: UI
    private let bgImage: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "bghex"))
        iv.contentMode = .scaleAspectFill
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let roleCard: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.white.withAlphaComponent(0.10)
        v.layer.cornerRadius = 22
        v.layer.borderWidth = 2
        v.layer.borderColor = UIColor.white.withAlphaComponent(0.18).cgColor
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let roleLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "Aclonica-Regular", size: 40)
        l.textColor = .white
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let statusLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "Aclonica-Regular", size: 24)
        l.textColor = UIColor.white.withAlphaComponent(0.9)
        l.textAlignment = .center
        l.numberOfLines = 3
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let timerLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "Aclonica-Regular", size: 58)
        l.textColor = .yellow
        l.translatesAutoresizingMaskIntoConstraints = false
        l.textAlignment = .center
        return l
    }()

    private let continueButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("CONTINUE", for: .normal)
        b.backgroundColor = UIColor(red: 21/255, green: 174/255, blue: 21/255, alpha: 1)
        b.setTitleColor(.white, for: .normal)
        b.layer.cornerRadius = 22
        b.translatesAutoresizingMaskIntoConstraints = false
        b.isHidden = true
        return b
    }()

    // MARK: - Initializer (THIS IS THE ONE USED!)
    init(roomCode: String,
         players: [RoomManager.Player],
         rumbleCount: Int,
         role: PlayerRole)
    {
        self.roomCode = roomCode
        self.players = players
        self.rumbleCount = rumbleCount
        self.role = role
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) not allowed") }

    // MARK: - Lifecycle
    deinit { stateListener?.remove(); timer?.invalidate() }

    override func viewDidLoad() {
        super.viewDidLoad()
        layoutUI()
        continueButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        addBackButton()
        startHapticsRound()
    }

    // MARK: UI
    private func layoutUI() {
        view.addSubview(bgImage)
        view.addSubview(roleCard)
        roleCard.addSubview(roleLabel)
        view.addSubview(statusLabel)
        view.addSubview(timerLabel)
        view.addSubview(continueButton)

        NSLayoutConstraint.activate([
            bgImage.topAnchor.constraint(equalTo: view.topAnchor),
            bgImage.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bgImage.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bgImage.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            roleCard.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),
            roleCard.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            roleCard.widthAnchor.constraint(equalToConstant: 250),
            roleCard.heightAnchor.constraint(equalToConstant: 70),

            roleLabel.centerXAnchor.constraint(equalTo: roleCard.centerXAnchor),
            roleLabel.centerYAnchor.constraint(equalTo: roleCard.centerYAnchor),

            statusLabel.topAnchor.constraint(equalTo: roleCard.bottomAnchor, constant: 25),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 25),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -25),

            timerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            timerLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            continueButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            continueButton.widthAnchor.constraint(equalToConstant: 220),
            continueButton.heightAnchor.constraint(equalToConstant: 55)
        ])
    }

    
    @objc private func onBack() { navigationController?.popViewController(animated: true) }

    // MARK: - GAME ROUND

    private func startHapticsRound() {
        secondsLeft = 10
        timerLabel.text = "10"

        roleLabel.text = role == .crewmate ? "CREWMATE" : "IMPOSTER"

        if role == .crewmate {
            statusLabel.text = "Feel the haptics..."
            sentRumbles = rumbleCount
            scheduleRumbles(count: rumbleCount)
        } else {
            statusLabel.text = "Stay silent.\nYou receive no haptics."
            sentRumbles = 0
        }

        startRoundTimer()
    }

    private func scheduleRumbles(count: Int) {
        guard count > 0 else { return }
        let gap = 10.0 / Double(count + 1)
        for i in 1...count {
            DispatchQueue.main.asyncAfter(deadline: .now() + gap * Double(i)) {
                HapticsEngineManager.shared.playRumble()
            }
        }
    }

    private func startRoundTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let s = self else { return }
            s.secondsLeft -= 1
            s.timerLabel.text = "\(s.secondsLeft)"
            if s.secondsLeft <= 0 { s.timer?.invalidate(); s.finishRound() }
        }
    }

    private func finishRound() {
        statusLabel.text = "Time’s up!"
        continueButton.isHidden = false
    }

    @objc private func nextTapped() {
        let vc = TapGuessViewController(
            roomCode: roomCode,
            rumbleCount: sentRumbles,
            myRole: role,
            players: players
        )
        navigationController?.pushViewController(vc, animated: true)
    }
}
