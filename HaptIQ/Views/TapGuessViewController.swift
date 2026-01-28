import UIKit
import FirebaseFirestore

final class TapGuessViewController: UIViewController {

    private let roomCode: String
    private let rumbleCount: Int
    private let myRole: HapticsRoomViewController.PlayerRole
    private var players: [RoomManager.Player]
    private var currentRound: Int
    private let selectedAvatar: AvatarPage? // 🆕 Store selected avatar

    private var myTapCount = 0
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private var hasProcessedResults = false  // 🔧 Prevent duplicate processing

    // UI
    private let bgImage: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "tapScreenBg"))
        iv.contentMode = .scaleAspectFill
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Tap Round"
        l.font = UIFont(name: "Aclonica-Regular", size: 36)
        l.textColor = .white
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.text = "Trust your touch, tap every haptics you feel"
        l.font = UIFont(name: "Aclonica-Regular", size: 14)
        l.textColor = UIColor.white.withAlphaComponent(0.8)
        l.textAlignment = .center
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let roundLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "Aclonica-Regular", size: 24)
        l.textColor = .white
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // Concentric circles container
    private let circlesContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    // Profile image in center
    private let profileImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.layer.cornerRadius = 60
        iv.layer.borderWidth = 3
        iv.layer.borderColor = UIColor.cyan.cgColor
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        // Set default profile image or user's profile
        iv.image = UIImage(named: "defaultProfile") ?? UIImage(systemName: "person.circle.fill")
        iv.tintColor = .white
        return iv
    }()
    
    // Counter controls
    private let counterContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let decrementButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("−", for: .normal)
        b.titleLabel?.font = UIFont.systemFont(ofSize: 40, weight: .light)
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        b.layer.cornerRadius = 30
        b.layer.borderWidth = 1
        b.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()
    
    private let counterLabel: UILabel = {
        let l = UILabel()
        l.text = "0"
        l.font = UIFont(name: "Aclonica-Regular", size: 48)
        l.textColor = .white
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let incrementButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("+", for: .normal)
        b.titleLabel?.font = UIFont.systemFont(ofSize: 40, weight: .light)
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        b.layer.cornerRadius = 30
        b.layer.borderWidth = 1
        b.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private let submitButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Next", for: .normal)
        b.titleLabel?.font = UIFont(name: "Aclonica-Regular", size: 22)
        b.backgroundColor = UIColor(red: 21/255, green: 174/255, blue: 21/255, alpha: 1)
        b.setTitleColor(.white, for: .normal)
        b.layer.cornerRadius = 27.5
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    // MARK: - Init
    init(roomCode: String,
         rumbleCount: Int,
         myRole: HapticsRoomViewController.PlayerRole,
         players: [RoomManager.Player],
         currentRound: Int = 1,
         selectedAvatar: AvatarPage? = nil) { // 🆕 Add avatar parameter
        self.roomCode = roomCode
        self.rumbleCount = rumbleCount
        self.myRole = myRole
        self.players = players
        self.currentRound = currentRound
        self.selectedAvatar = selectedAvatar
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("not allowed") }

    deinit {
        listener?.remove()
        print("🗑️ TapGuessViewController deallocated")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Debug: Check if avatar was passed
        if let avatar = selectedAvatar {
            print("🎨 Avatar passed to TapGuessViewController: \(avatar.title)")
            print("   - lobbyImageName: \(avatar.lobbyImageName)")
            print("   - imageName: \(avatar.imageName)")
        } else {
            print("⚠️ NO avatar passed to TapGuessViewController")
        }
        
        layoutUI()
        updateRoundLabel()
        setupButtonActions()
        loadUserProfile()
        
        print("📱 TapGuessViewController loaded - Round \(currentRound), Players: \(players.count), Rumbles: \(rumbleCount)")
    }
    
    private func loadUserProfile() {
        // Use the selected avatar if available
        if let avatar = selectedAvatar {
            // Use imageName for the tap screen (the main avatar image)
            if let avatarImage = UIImage(named: avatar.imageName) {
                profileImageView.image = avatarImage
                print("✅ Loaded avatar: \(avatar.title) - \(avatar.imageName)")
            } else {
                print("⚠️ Avatar image '\(avatar.imageName)' not found in assets")
                // Try lobby image as fallback
                if let lobbyImage = UIImage(named: avatar.lobbyImageName) {
                    profileImageView.image = lobbyImage
                    print("✅ Using lobby image instead: \(avatar.lobbyImageName)")
                } else {
                    print("❌ Neither avatar image found, using default")
                    profileImageView.image = UIImage(named: "defaultProfile") ?? UIImage(systemName: "person.circle.fill")
                }
            }
        } else {
            // Fallback: Try to load from saved preferences
            print("⚠️ No avatar passed to TapGuessViewController")
            if let savedAvatarName = UserDefaults.standard.string(forKey: "selectedAvatar_\(RoomManager.shared.currentUserID)") {
                if let savedImage = UIImage(named: savedAvatarName) {
                    profileImageView.image = savedImage
                    print("✅ Loaded saved avatar: \(savedAvatarName)")
                } else {
                    print("⚠️ Saved avatar '\(savedAvatarName)' not found")
                    profileImageView.image = UIImage(named: "defaultProfile") ?? UIImage(systemName: "person.circle.fill")
                }
            } else {
                // Ultimate fallback
                print("⚠️ Using default profile image")
                profileImageView.image = UIImage(named: "defaultProfile") ?? UIImage(systemName: "person.circle.fill")
            }
        }
        
        // Debug: Print what image is actually set
        if profileImageView.image != nil {
            print("✅ Profile image view has an image")
        } else {
            print("❌ Profile image view has NO image")
        }
    }
    
    private func setupButtonActions() {
        incrementButton.addTarget(self, action: #selector(incrementTapped), for: .touchUpInside)
        decrementButton.addTarget(self, action: #selector(decrementTapped), for: .touchUpInside)
        submitButton.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
        
        // Add tap gesture to profile image area
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(profileTapped))
        profileImageView.addGestureRecognizer(tapGesture)
        profileImageView.isUserInteractionEnabled = true
    }

    // MARK: UI Layout
    private func layoutUI() {
        view.addSubview(bgImage)
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(circlesContainer)
        view.addSubview(counterContainer)
        view.addSubview(submitButton)
        
        // Add concentric circles
        createConcentricCircles()
        
        // Add profile to circles container
        circlesContainer.addSubview(profileImageView)
        
        // Add counter controls
        counterContainer.addSubview(decrementButton)
        counterContainer.addSubview(counterLabel)
        counterContainer.addSubview(incrementButton)

        NSLayoutConstraint.activate([
            bgImage.topAnchor.constraint(equalTo: view.topAnchor),
            bgImage.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bgImage.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bgImage.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),

            circlesContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            circlesContainer.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 40),
            circlesContainer.widthAnchor.constraint(equalToConstant: 380),
            circlesContainer.heightAnchor.constraint(equalToConstant: 380),
            
            profileImageView.centerXAnchor.constraint(equalTo: circlesContainer.centerXAnchor),
            profileImageView.centerYAnchor.constraint(equalTo: circlesContainer.centerYAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 120),
            profileImageView.heightAnchor.constraint(equalToConstant: 120),
            
            counterContainer.topAnchor.constraint(equalTo: circlesContainer.bottomAnchor, constant: 15),
            counterContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            counterContainer.heightAnchor.constraint(equalToConstant: 60),
            
            decrementButton.leadingAnchor.constraint(equalTo: counterContainer.leadingAnchor),
            decrementButton.centerYAnchor.constraint(equalTo: counterContainer.centerYAnchor),
            decrementButton.widthAnchor.constraint(equalToConstant: 60),
            decrementButton.heightAnchor.constraint(equalToConstant: 60),
            
            counterLabel.centerXAnchor.constraint(equalTo: counterContainer.centerXAnchor),
            counterLabel.centerYAnchor.constraint(equalTo: counterContainer.centerYAnchor),
            counterLabel.leadingAnchor.constraint(equalTo: decrementButton.trailingAnchor, constant: 30),
            counterLabel.trailingAnchor.constraint(equalTo: incrementButton.leadingAnchor, constant: -30),
            
            incrementButton.trailingAnchor.constraint(equalTo: counterContainer.trailingAnchor),
            incrementButton.centerYAnchor.constraint(equalTo: counterContainer.centerYAnchor),
            incrementButton.widthAnchor.constraint(equalToConstant: 60),
            incrementButton.heightAnchor.constraint(equalToConstant: 60),

            submitButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            submitButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            submitButton.widthAnchor.constraint(equalToConstant: 340),
            submitButton.heightAnchor.constraint(equalToConstant: 55)
        ])
    }
    
    private func createConcentricCircles() {
        // Circles removed - background image handles the visual design
    }
    
    private func updateRoundLabel() {
        let maxRounds = getMaxRounds()
        // Round label removed from main UI, can add back if needed
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

    // MARK: - Button Actions
    @objc private func incrementTapped() {
        myTapCount += 1
        updateCounter()
        HapticsEngineManager.shared.playRumble()
    }
    
    @objc private func decrementTapped() {
        if myTapCount > 0 {
            myTapCount -= 1
            updateCounter()
            HapticsEngineManager.shared.playRumble()
        }
    }
    
    @objc private func profileTapped() {
        // Tapping profile also registers a haptic
        myTapCount += 1
        updateCounter()
        HapticsEngineManager.shared.playRumble()
        
        // Add a subtle scale animation
        UIView.animate(withDuration: 0.1, animations: {
            self.profileImageView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.profileImageView.transform = .identity
            }
        }
    }
    
    private func updateCounter() {
        counterLabel.text = "\(myTapCount)"
        
        // Add bounce animation
        UIView.animate(withDuration: 0.15, animations: {
            self.counterLabel.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }) { _ in
            UIView.animate(withDuration: 0.15) {
                self.counterLabel.transform = .identity
            }
        }
    }

    @objc private func onBack() {
        navigationController?.popViewController(animated: true)
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
            
            // 🆕 Pass the selected avatar to next round
            if let avatar = self.selectedAvatar {
                vc.selectedAvatar = avatar
            }
            
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
