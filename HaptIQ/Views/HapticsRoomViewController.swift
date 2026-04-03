//  HapticsRoomViewController.swift
//  HaptIQ anuj

import UIKit
import FirebaseFirestore

final class HapticsRoomViewController: UIViewController {

    // MARK: - Public game inputs
    var roomCode: String
    var rumbleCount: Int = 0
    var players: [RoomManager.Player] = []
    var role: PlayerRole
    var currentRound: Int = 1
    var selectedAvatar: AvatarPage?

    enum PlayerRole { case crewmate, imposter }

    // MARK: - Internal state
    private var sentRumbles: Int = 0
    private var timer: Timer?
    private var secondsLeft = 10
    private var hasNavigated = false

    // MARK: - UI
    private let pngAnimationView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let bgImage: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "gScreen"))
        iv.contentMode = .scaleAspectFill
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let roleLabel: UILabel = {
        let l = UILabel()
        l.text = "Haptic Round"
        l.font = UIFont(name: "Aclonica-Regular", size: 32)
        l.textColor = .white
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let statusLabel: UILabel = {
        let l = UILabel()
        l.text = "Feel the pulses. Stay quiet."
        l.font = UIFont(name: "Aclonica-Regular", size: 16)
        l.textColor = UIColor.white.withAlphaComponent(0.7)
        l.textAlignment = .center
        l.numberOfLines = 3
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let timerLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "Aclonica-Regular", size: 56)
        l.textColor = .white
        l.translatesAutoresizingMaskIntoConstraints = false
        l.textAlignment = .center
        return l
    }()

    private let continueButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Continue", for: .normal)
        b.titleLabel?.font = UIFont(name: "Aclonica-Regular", size: 20)
        b.backgroundColor = UIColor(red: 21/255, green: 174/255, blue: 21/255, alpha: 1)
        b.setTitleColor(.white, for: .normal)
        b.layer.cornerRadius = 22
        b.translatesAutoresizingMaskIntoConstraints = false
        b.isHidden = true
        return b
    }()

    // MARK: - Initializer
    init(roomCode: String, players: [RoomManager.Player], rumbleCount: Int, role: PlayerRole) {
        self.roomCode = roomCode
        self.players = players
        self.rumbleCount = rumbleCount
        self.role = role
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) not allowed") }

    deinit {
        cleanup()
        print("🗑️ HapticsRoomViewController deallocated")
    }
    
    private func cleanup() {
        timer?.invalidate()
        timer = nil
        pngAnimationView.stopAnimating()
        pngAnimationView.animationImages = nil
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        
        print("🎮 HapticsRoomViewController loaded - Round \(currentRound), Role: \(role), Rumbles: \(rumbleCount)")
        
        layoutUI()
        setupPNGAnimation()
        continueButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        startHapticsRound()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cleanup()
    }

    // MARK: - PNG Animation
    private func setupPNGAnimation() {
        guard let frame1 = UIImage(named: "haptic1"),
              let frame2 = UIImage(named: "haptic2") else {
            print("⚠️ Animation images not found")
            return
        }
        
        pngAnimationView.animationImages = [frame1, frame2]
        pngAnimationView.animationDuration = 1.3
        pngAnimationView.animationRepeatCount = 0
        pngAnimationView.startAnimating()
    }

    // MARK: - UI Layout
    private func layoutUI() {
        view.addSubview(bgImage)
        view.addSubview(pngAnimationView)
        view.addSubview(roleLabel)
        view.addSubview(statusLabel)
        view.addSubview(timerLabel)
        view.addSubview(continueButton)

        NSLayoutConstraint.activate([
            bgImage.topAnchor.constraint(equalTo: view.topAnchor),
            bgImage.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bgImage.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bgImage.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            pngAnimationView.topAnchor.constraint(equalTo: view.topAnchor),
            pngAnimationView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            pngAnimationView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pngAnimationView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            roleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            roleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            statusLabel.topAnchor.constraint(equalTo: roleLabel.bottomAnchor, constant: 8),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 25),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -25),

            timerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            timerLabel.bottomAnchor.constraint(equalTo: continueButton.topAnchor, constant: -20),

            continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            continueButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            continueButton.widthAnchor.constraint(equalToConstant: 220),
            continueButton.heightAnchor.constraint(equalToConstant: 55)
        ])
    }

    // MARK: - Game Round
    private func startHapticsRound() {
        secondsLeft = 10
        updateTimerDisplay()

        if role == .crewmate {
            sentRumbles = rumbleCount
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                guard let self = self, !self.hasNavigated else { return }
                HapticsEngineManager.shared.playCountableRumble(count: self.rumbleCount)
                print("🔊 Crewmate received \(self.rumbleCount) rumbles")
            }
        } else {
            sentRumbles = 0
            print("🎭 Imposter: No rumbles")
        }

        startRoundTimer()
    }
    
    private func updateTimerDisplay() {
        timerLabel.text = String(format: "%02d:%02d", secondsLeft / 60, secondsLeft % 60)
    }

    private func startRoundTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.secondsLeft -= 1
            self.updateTimerDisplay()
            
            if self.secondsLeft <= 0 {
                self.timer?.invalidate()
                self.timer = nil
                self.finishRound()
            }
        }
    }

    private func finishRound() {
        DispatchQueue.main.async { [weak self] in
            self?.continueButton.isHidden = false
        }
        print("⏱️ Timer finished")
    }

    // MARK: - Navigation
    @objc private func nextTapped() {
        guard !hasNavigated else { return }
        hasNavigated = true
        
        cleanup()
        
        continueButton.isEnabled = false
        continueButton.alpha = 0.6
        
        print("➡️ Continue → TapGuessViewController")
        
        let vc = TapGuessViewController(
            roomCode: roomCode,
            rumbleCount: rumbleCount,
            myRole: role,
            players: players,
            currentRound: currentRound,
            selectedAvatar: selectedAvatar
        )
        
        DispatchQueue.main.async { [weak self] in
            self?.navigationController?.pushViewController(vc, animated: true)
        }
    }
}
