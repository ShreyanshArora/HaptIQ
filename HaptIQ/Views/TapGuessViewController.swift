import UIKit
import FirebaseFirestore

final class TapGuessViewController: UIViewController {

    private let roomCode: String
    private let rumbleCount: Int
    private let myRole: HapticsRoomViewController.PlayerRole
    private var players: [RoomManager.Player]
    private var currentRound: Int
    private let selectedAvatar: AvatarPage?

    private var myTapCount = 0
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private var hasProcessedResults = false

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
         selectedAvatar: AvatarPage? = nil) {
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
        
        if let avatar = selectedAvatar {
            print("🎨 Avatar passed to TapGuessViewController: \(avatar.title)")
        } else {
            print("⚠️ NO avatar passed to TapGuessViewController")
        }
        
        layoutUI()
        setupButtonActions()
        loadUserProfile()
        
        print("📱 TapGuessViewController loaded - Round \(currentRound), Players: \(players.count), Rumbles: \(rumbleCount)")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("📱 TapGuessViewController appeared")
        print("   - Navigation stack: \(navigationController?.viewControllers.count ?? 0) controllers")
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("📱 TapGuessViewController will disappear")
    }
    
    private func loadUserProfile() {
        if let avatar = selectedAvatar {
            if let avatarImage = UIImage(named: avatar.imageName) {
                profileImageView.image = avatarImage
                print("✅ Loaded avatar: \(avatar.title) - \(avatar.imageName)")
            } else {
                print("⚠️ Avatar image '\(avatar.imageName)' not found in assets")
                if let lobbyImage = UIImage(named: avatar.lobbyImageName) {
                    profileImageView.image = lobbyImage
                    print("✅ Using lobby image instead: \(avatar.lobbyImageName)")
                } else {
                    print("❌ Neither avatar image found, using default")
                    profileImageView.image = UIImage(named: "defaultProfile") ?? UIImage(systemName: "person.circle.fill")
                }
            }
        } else {
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
                print("⚠️ Using default profile image")
                profileImageView.image = UIImage(named: "defaultProfile") ?? UIImage(systemName: "person.circle.fill")
            }
        }
        
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
        
        circlesContainer.addSubview(profileImageView)
        
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
        myTapCount += 1
        updateCounter()
        HapticsEngineManager.shared.playRumble()
        
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
        
        UIView.animate(withDuration: 0.15, animations: {
            self.counterLabel.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }) { _ in
            UIView.animate(withDuration: 0.15) {
                self.counterLabel.transform = .identity
            }
        }
    }

    // MARK: - Submit with Improved Error Handling
    @objc private func submitTapped() {
        let uid = RoomManager.shared.currentUserID
        
        print("🔵 SUBMIT TAPPED - User: \(uid.prefix(4))")
        print("   - Tap Count: \(myTapCount)")
        print("   - Expected Rumbles: \(rumbleCount)")
        print("   - Total Players: \(players.count)")

        db.collection("rooms")
            .document(roomCode)
            .collection("guesses")
            .document(uid)
            .setData([
                "tapCount": myTapCount,
                "rumbleCount": rumbleCount,
                "playerID": uid,
                "timestamp": FieldValue.serverTimestamp()
            ], merge: true) { error in
                if let error = error {
                    print("❌ Submit error: \(error)")
                    return
                }
                
                print("✅ Successfully submitted guess to Firestore")
                
                DispatchQueue.main.async {
                    self.listenForResults()
                    self.submitButton.isEnabled = false
                    self.submitButton.alpha = 0.6
                    self.submitButton.setTitle("Waiting...", for: .normal)
                }
            }
    }

    // MARK: - Improved Listen For Results
    private func listenForResults() {
        guard !hasProcessedResults else {
            print("⚠️ Already processed results, skipping listener")
            return
        }
        
        print("👂 Starting to listen for results...")
        print("   - Expected players: \(players.count)")
        
        listener?.remove()
        listener = db.collection("rooms")
            .document(roomCode)
            .collection("guesses")
            .addSnapshotListener { [weak self] snap, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Listener error: \(error)")
                    return
                }
                
                guard let docs = snap?.documents else {
                    print("⚠️ No documents in snapshot")
                    return
                }
                
                let submittedPlayerIDs = Set(docs.compactMap { $0.data()["playerID"] as? String })
                let expectedPlayerIDs = Set(self.players.map { $0.id })
                
                print("📊 Guess Status:")
                print("   - Submitted: \(submittedPlayerIDs.count)/\(self.players.count)")
                print("   - Submitted IDs: \(submittedPlayerIDs.map { $0.prefix(4) })")
                print("   - Expected IDs: \(expectedPlayerIDs.map { $0.prefix(4) })")
                print("   - Missing: \(expectedPlayerIDs.subtracting(submittedPlayerIDs).map { $0.prefix(4) })")
                
                let allPlayersSubmitted = submittedPlayerIDs.count >= self.players.count
                
                if allPlayersSubmitted && !self.hasProcessedResults {
                    print("🎯 All players submitted! Processing results...")
                    self.hasProcessedResults = true
                    self.listener?.remove()
                    
                    let results = docs.map { $0.data() }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.evaluateResults(results)
                    }
                } else if !allPlayersSubmitted {
                    print("⏳ Still waiting for \(self.players.count - submittedPlayerIDs.count) player(s)")
                }
            }
    }

    // MARK: - Result Evaluation (FIXED VOTING LOGIC)
    private func evaluateResults(_ guesses: [[String: Any]]) {
        print("\n🎯 === EVALUATING ROUND \(currentRound) ===")
        print("📊 Total guesses received: \(guesses.count)")
        print("👥 Expected players: \(players.count)")
        
        guard guesses.count >= players.count else {
            print("⚠️ WARNING: Not enough guesses (\(guesses.count)/\(players.count))")
            return
        }
        
        var imposterID = ""
        for (id, role) in RoomManager.shared.cachedRoles {
            if role == "imposter" {
                imposterID = id
                print("🎭 Imposter ID: \(id.prefix(4))")
            }
        }
        
        guard !imposterID.isEmpty else {
            print("❌ ERROR: No imposter found in cached roles!")
            print("   Cached roles: \(RoomManager.shared.cachedRoles)")
            return
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
                if tap != correct {
                    imposterWrong = true
                    print("   ⚠️ IMPOSTER GUESSED WRONG")
                }
            } else {
                if tap != correct {
                    crewmatesWrong.append(id)
                    print("   ⚠️ CREWMATE GUESSED WRONG")
                }
            }
        }

        print("📈 Summary:")
        print("   - Imposter wrong: \(imposterWrong)")
        print("   - Crewmates wrong: \(crewmatesWrong.count)")

        clearGuesses()

        let maxRounds = getMaxRounds()
        let myID = RoomManager.shared.currentUserID
        
        // 🎯 FIXED LOGIC: Only go to voting if imposter guessed WRONG
        if imposterWrong {
            print("🗳️ Case 1: Imposter guessed WRONG → GO TO VOTING")
            DispatchQueue.main.async {
                print("🔄 Navigating to VotingViewController...")
                let vc = VotingViewController(
                    roomCode: self.roomCode,
                    players: self.players,
                    currentRound: self.currentRound
                )
                self.navigationController?.pushViewController(vc, animated: true)
                print("✅ Navigation initiated")
            }
            return
        }
        
        // ✅ Imposter guessed CORRECT - Continue game based on crewmate performance
        print("✅ Imposter guessed CORRECTLY")
        
        // Case 2: Imposter CORRECT + Some crewmates wrong → Eliminate crewmates
        if !crewmatesWrong.isEmpty {
            print("🎲 Case 2: Imposter correct, \(crewmatesWrong.count) crewmate(s) wrong → Eliminate them")
            
            let survivingPlayers = players.filter { player in
                let survived = !crewmatesWrong.contains(player.id)
                if !survived {
                    print("💀 Eliminated: \(player.name) (\(player.id.prefix(4)))")
                }
                return survived
            }
            
            print("✅ Surviving players: \(survivingPlayers.count)")
            
            // Check win conditions
            if survivingPlayers.count <= 1 || currentRound >= maxRounds {
                print("🏆 IMPOSTER WINS - Too few crewmates or last round reached")
                DispatchQueue.main.async {
                    print("🔄 Navigating to GameResultViewController (Imposter wins)...")
                    let vc = GameResultViewController(
                        crewmatesWon: false,
                        roomCode: self.roomCode
                    )
                    self.navigationController?.pushViewController(vc, animated: true)
                    print("✅ Navigation initiated")
                }
            } else {
                // Check if I was eliminated
                if crewmatesWrong.contains(myID) {
                    print("💀 I was eliminated → Spectator mode")
                    DispatchQueue.main.async {
                        print("🔄 Navigating to SpectatorViewController...")
                        let vc = SpectatorViewController()
                        self.navigationController?.pushViewController(vc, animated: true)
                        print("✅ Navigation initiated")
                    }
                } else {
                    print("✅ I survived → Continue to next round")
                    continueToNextRound(with: survivingPlayers)
                }
            }
            return
        }
        
        // Case 3: Everyone guessed correctly (including imposter) → Continue to next round
        print("🎲 Case 3: Everyone (including imposter) guessed correctly → Continue game")
        
        if currentRound >= maxRounds {
            print("📊 Last round reached and everyone correct → Forced voting to find imposter")
            DispatchQueue.main.async {
                print("🔄 Navigating to VotingViewController (forced - last round)...")
                let vc = VotingViewController(
                    roomCode: self.roomCode,
                    players: self.players,
                    currentRound: self.currentRound
                )
                self.navigationController?.pushViewController(vc, animated: true)
                print("✅ Navigation initiated")
            }
        } else {
            print("➡️ Continuing to round \(self.currentRound + 1)")
            continueToNextRound(with: players)
        }
        
        print("=== END EVALUATION ===\n")
    }

    private func continueToNextRound(with activePlayers: [RoomManager.Player]) {
        let nextR = Int.random(in: 2...5)
        print("🎮 Next round: \(currentRound + 1), Rumbles: \(nextR), Active players: \(activePlayers.count)")
        
        DispatchQueue.main.async {
            print("🔄 Navigating to HapticsRoomViewController...")
            let vc = HapticsRoomViewController(
                roomCode: self.roomCode,
                players: activePlayers,
                rumbleCount: nextR,
                role: self.myRole
            )
            vc.currentRound = self.currentRound + 1
            
            if let avatar = self.selectedAvatar {
                vc.selectedAvatar = avatar
            }
            
            self.navigationController?.pushViewController(vc, animated: true)
            print("✅ Navigation initiated")
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
