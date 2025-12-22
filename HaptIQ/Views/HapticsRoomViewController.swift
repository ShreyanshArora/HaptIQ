//
//  HapticsRoomViewController.swift
//  HaptIQ
//

import UIKit
import FirebaseFirestore

final class HapticsRoomViewController: UIViewController {

    // MARK: - Public game inputs
    var roomCode: String
    var rumbleCount: Int = 0
    var players: [RoomManager.Player] = []
    var role: PlayerRole
    var currentRound: Int = 1
    var selectedAvatar: AvatarPage? // 🆕 Add this property to store selected avatar

    enum PlayerRole { case crewmate, imposter }

    // MARK: - Internal state
    private var sentRumbles: Int = 0
    private var timer: Timer?
    private var secondsLeft = 10
    private var inRound = false
    private var stateListener: ListenerRegistration?

    // MARK: - PNG Animation
    private let pngAnimationView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    // MARK: UI
    private let bgImage: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "gScreen"))
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
    deinit {
        stateListener?.remove()
        timer?.invalidate()
        print("🗑️ HapticsRoomViewController deallocated")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Debug: Check avatar status
        if let avatar = selectedAvatar {
            print("🎨 HapticsRoomViewController has avatar: \(avatar.title)")
            print("   - lobbyImageName: \(avatar.lobbyImageName)")
            print("   - imageName: \(avatar.imageName)")
        } else {
            print("⚠️ HapticsRoomViewController has NO avatar")
        }
        
        layoutUI()
        setupPNGAnimation()
        continueButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        startHapticsRound()
        
        print("🎮 HapticsRoomViewController loaded - Round \(currentRound), Role: \(role), Players: \(players.count)")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timer?.invalidate()
    }

    // MARK: - PNG Animation Setup
    private func setupPNGAnimation() {
        guard let frame1 = UIImage(named: "haptic1"),
              let frame2Original = UIImage(named: "haptic2") else {
            print("⚠️ haptic1.png or haptic2.png not found")
            return
        }
        
        // Shift haptic2 image upward to align centers
        let frame2 = shiftImageUp(frame2Original, by: 25)
        
        pngAnimationView.animationImages = [frame1, frame2]
        pngAnimationView.animationDuration = 1.3 // 1.3 seconds total (0.65 sec per frame)
        pngAnimationView.animationRepeatCount = 0 // Loop forever
        pngAnimationView.startAnimating()
    }
    
    private func shiftImageUp(_ image: UIImage, by offset: CGFloat) -> UIImage {
        let newSize = image.size
        UIGraphicsBeginImageContextWithOptions(newSize, false, image.scale)
        
        // Draw the image shifted up
        image.draw(at: CGPoint(x: 0, y: -offset))
        
        let shiftedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return shiftedImage ?? image
    }

    // MARK: UI
    private func layoutUI() {
        view.addSubview(bgImage)
        view.addSubview(pngAnimationView) // Full screen PNG animation
        view.addSubview(roleLabel)
        view.addSubview(statusLabel)
        view.addSubview(timerLabel)
        view.addSubview(continueButton)

        NSLayoutConstraint.activate([
            bgImage.topAnchor.constraint(equalTo: view.topAnchor),
            bgImage.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bgImage.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bgImage.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            // PNG Animation - Full screen AspectFill
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

    @objc private func onBack() {
        navigationController?.popViewController(animated: true)
    }

    // MARK: - GAME ROUND

    private func startHapticsRound() {
        secondsLeft = 10
        updateTimerDisplay()

        if role == .crewmate {
            sentRumbles = rumbleCount
            
            // Delay haptic feedback by 2 seconds for crewmates
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                HapticsEngineManager.shared.playCountableRumble(count: self.rumbleCount)
                print("🔊 Crewmate received \(self.rumbleCount) rumbles")
            }
            
        } else {
            // Imposter doesn't feel rumbles
            sentRumbles = 0
            print("🎭 Imposter: No rumbles sent")
        }

        startRoundTimer()
    }
    
    private func updateTimerDisplay() {
        let minutes = secondsLeft / 60
        let seconds = secondsLeft % 60
        timerLabel.text = String(format: "%02d:%02d", minutes, seconds)
    }

    private func startRoundTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let s = self else { return }
            s.secondsLeft -= 1
            s.updateTimerDisplay()
            
            if s.secondsLeft <= 0 {
                s.timer?.invalidate()
                s.finishRound()
            }
        }
    }

    private func finishRound() {
        continueButton.isHidden = false
        print("⏱️ Round timer finished - Show continue button")
    }

    @objc private func nextTapped() {
        print("➡️ Continue tapped - Moving to TapGuessViewController")
        
        // Debug: Check avatar before passing
        if let avatar = selectedAvatar {
            print("🔍 Avatar being passed to TapGuessVC: \(avatar.title)")
            print("   - lobbyImageName: \(avatar.lobbyImageName)")
            print("   - imageName: \(avatar.imageName)")
        } else {
            print("⚠️ NO avatar to pass to TapGuessVC")
        }
        
        let vc = TapGuessViewController(
            roomCode: roomCode,
            rumbleCount: sentRumbles,
            myRole: role,
            players: players,
            currentRound: currentRound,
            selectedAvatar: selectedAvatar // 🆕 Pass the selected avatar
        )
        navigationController?.pushViewController(vc, animated: true)
    }
}
