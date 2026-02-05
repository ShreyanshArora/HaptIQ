import UIKit
import FirebaseFirestore

final class TapGuessViewController: UIViewController {

    // MARK: - Properties
    private let roomCode: String
    private let rumbleCount: Int
    private let myRole: HapticsRoomViewController.PlayerRole
    private var players: [RoomManager.Player]
    private var currentRound: Int
    private let selectedAvatar: AvatarPage?

    private var myTapCount = 0
    private let db = Firestore.firestore()
    private var guessListener: ListenerRegistration?
    private var gameStateListener: ListenerRegistration?
    private var hasSubmitted = false
    private var hasProcessedResults = false
    private var hasNavigated = false
    
    //  Track the timestamp when we start waiting for results
    private var waitingForResultsSince: TimeInterval = 0

    // MARK: - UI Components
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

    private let circlesContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
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

    // MARK: - Initializer
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
    
    required init?(coder: NSCoder) { fatalError("init(coder:) not allowed") }

    deinit {
        cleanup()
        print("🗑️ TapGuessViewController deallocated")
    }
    
    private func cleanup() {
        guessListener?.remove()
        guessListener = nil
        gameStateListener?.remove()
        gameStateListener = nil
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        
        layoutUI()
        setupButtonActions()
        loadUserProfile()
        
        print("📱 TapGuessViewController loaded - Round \(currentRound), Players: \(players.count), Expected: \(rumbleCount)")
        print("👑 Am I host? \(RoomManager.shared.isHost)")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cleanup()
        print("🛑 TapGuessViewController will disappear")
    }
    
    // MARK: - Profile Loading
    private func loadUserProfile() {
        if let avatar = selectedAvatar, let img = UIImage(named: avatar.imageName) {
            profileImageView.image = img
        } else if let avatar = selectedAvatar, let img = UIImage(named: avatar.lobbyImageName) {
            profileImageView.image = img
        }
    }
    
    // MARK: - Button Setup
    private func setupButtonActions() {
        incrementButton.addTarget(self, action: #selector(incrementTapped), for: .touchUpInside)
        decrementButton.addTarget(self, action: #selector(decrementTapped), for: .touchUpInside)
        submitButton.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(profileTapped))
        profileImageView.addGestureRecognizer(tapGesture)
        profileImageView.isUserInteractionEnabled = true
    }

    // MARK: - UI Layout
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
        if players.count >= 5 { return 3 }
        else if players.count >= 3 { return 2 }
        else { return 2 }
    }

    // MARK: - Button Actions
    @objc private func incrementTapped() {
        myTapCount += 1
        counterLabel.text = "\(myTapCount)"
        HapticsEngineManager.shared.playRumble()
    }
    
    @objc private func decrementTapped() {
        guard myTapCount > 0 else { return }
        myTapCount -= 1
        counterLabel.text = "\(myTapCount)"
        HapticsEngineManager.shared.playRumble()
    }
    
    @objc private func profileTapped() {
        myTapCount += 1
        counterLabel.text = "\(myTapCount)"
        HapticsEngineManager.shared.playRumble()
    }

    // MARK: - Submit Guess
    @objc private func submitTapped() {
        guard !hasSubmitted else { return }
        hasSubmitted = true
        
        let uid = RoomManager.shared.currentUserID
        
        print("🔵 SUBMIT - User: \(String(uid.prefix(8))), Taps: \(myTapCount), Expected: \(rumbleCount)")
        
        submitButton.isEnabled = false
        submitButton.alpha = 0.6
        submitButton.setTitle("Waiting...", for: .normal)
        
        // ✅ Record when we started waiting
        waitingForResultsSince = Date().timeIntervalSince1970

        db.collection("rooms")
            .document(roomCode)
            .collection("guesses")
            .document(uid)
            .setData([
                "tapCount": myTapCount,
                "playerID": uid,
                "round": currentRound,
                "timestamp": FieldValue.serverTimestamp()
            ]) { [weak self] error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Submit error: \(error)")
                    self.hasSubmitted = false
                    self.submitButton.isEnabled = true
                    self.submitButton.alpha = 1.0
                    self.submitButton.setTitle("Next", for: .normal)
                    return
                }
                
                print("✅ Guess submitted")
                
                if RoomManager.shared.isHost {
                    // ✅ HOST: Listen for all guesses, then evaluate
                    self.hostListenForAllGuesses()
                } else {
                    // ✅ NON-HOST: Listen for game state update from host
                    self.nonHostListenForGameState()
                }
            }
    }

    // ════════════════════════════════════════════════════════════════════
    // MARK: - HOST ONLY: Listen for all guesses and evaluate
    // ════════════════════════════════════════════════════════════════════
    
    private func hostListenForAllGuesses() {
        guard RoomManager.shared.isHost else { return }
        
        print("👑 [HOST] Listening for all guesses...")
        
        guessListener?.remove()
        guessListener = db.collection("rooms")
            .document(roomCode)
            .collection("guesses")
            .whereField("round", isEqualTo: currentRound)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                guard RoomManager.shared.isHost else { return }
                guard !self.hasProcessedResults else { return }
                
                if let error = error {
                    print("❌ [HOST] Listener error: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                print("👑 [HOST] Guesses for round \(self.currentRound): \(documents.count)/\(self.players.count)")
                
                if documents.count >= self.players.count {
                    print("👑 [HOST] All players submitted!")
                    
                    self.hasProcessedResults = true
                    self.guessListener?.remove()
                    self.guessListener = nil
                    
                    let allGuesses = documents.map { $0.data() }
                    self.hostEvaluateAndWriteGameState(allGuesses)
                }
            }
    }
    
    private func hostEvaluateAndWriteGameState(_ guesses: [[String: Any]]) {
        guard RoomManager.shared.isHost else { return }
        
        print("\n👑 [HOST] === EVALUATING ROUND \(currentRound) ===")
        
        // Find imposter
        var imposterID = ""
        for (playerID, role) in RoomManager.shared.cachedRoles {
            if role == "imposter" {
                imposterID = playerID
                break
            }
        }
        
        guard !imposterID.isEmpty else {
            print("❌ [HOST] No imposter found")
            return
        }
        
        print("👑 [HOST] Imposter: \(String(imposterID.prefix(8)))")

        var imposterWrong = false
        var wrongCrewmates: [String] = []

        for guess in guesses {
            guard let playerID = guess["playerID"] as? String,
                  let tapCount = guess["tapCount"] as? Int else { continue }
            
            let isCorrect = tapCount == rumbleCount
            print("👑 [HOST] Player \(String(playerID.prefix(8))): \(tapCount) vs \(rumbleCount) = \(isCorrect ? "✅" : "❌")")

            if playerID == imposterID {
                if !isCorrect { imposterWrong = true }
            } else {
                if !isCorrect { wrongCrewmates.append(playerID) }
            }
        }

        print("👑 [HOST] Imposter wrong: \(imposterWrong), Crewmates wrong: \(wrongCrewmates.count)")

        // Determine next state
        let maxRounds = getMaxRounds()
        var nextScreen: String
        var nextRound = currentRound
        var nextRumbleCount = rumbleCount
        var survivingPlayerIDs = players.map { $0.id }
        var eliminatedPlayerIDs: [String] = []
        var crewmatesWon: Bool? = nil
        
        // CASE 1: Imposter wrong → Voting
        if imposterWrong {
            print("👑 [HOST] Decision: → VOTING (Imposter wrong)")
            nextScreen = "voting"
        }
        // CASE 2: Imposter correct + crewmates wrong → Eliminate
        else if !wrongCrewmates.isEmpty {
            eliminatedPlayerIDs = wrongCrewmates
            survivingPlayerIDs = players.map { $0.id }.filter { !wrongCrewmates.contains($0) }
            let crewmatesRemaining = survivingPlayerIDs.filter { $0 != imposterID }.count
            
            if crewmatesRemaining <= 1 {
                print("👑 [HOST] Decision: → RESULT (Imposter wins)")
                nextScreen = "result"
                crewmatesWon = false
            } else {
                print("👑 [HOST] Decision: → HAPTICS Round \(currentRound + 1)")
                nextScreen = "haptics"
                nextRound = currentRound + 1
                nextRumbleCount = Int.random(in: 2...5)
            }
        }
        // CASE 3: Everyone correct
        else {
            if currentRound >= maxRounds {
                print("👑 [HOST] Decision: → VOTING (Max rounds)")
                nextScreen = "voting"
            } else {
                print("👑 [HOST] Decision: → HAPTICS Round \(currentRound + 1)")
                nextScreen = "haptics"
                nextRound = currentRound + 1
                nextRumbleCount = Int.random(in: 2...5)
            }
        }
        
        // ✅ Write game state to Firestore
        let gameStateData: [String: Any] = [
            "screen": nextScreen,
            "round": nextRound,
            "rumbleCount": nextRumbleCount,
            "survivingPlayerIDs": survivingPlayerIDs,
            "eliminatedPlayerIDs": eliminatedPlayerIDs,
            "crewmatesWon": crewmatesWon as Any,
            "forRound": currentRound,  // ✅ Which round this result is for
            "timestamp": FieldValue.serverTimestamp()
        ]
        
        print("👑 [HOST] Writing gameState: screen=\(nextScreen), forRound=\(currentRound)")
        
        db.collection("rooms")
            .document(roomCode)
            .updateData(["gameState": gameStateData]) { [weak self] error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ [HOST] Failed to write gameState: \(error)")
                    return
                }
                
                print("✅ [HOST] gameState written successfully")
                
                // ✅ Clear guesses after writing state
                self.clearGuesses()
                
                // ✅ Host navigates based on what they wrote
                DispatchQueue.main.async {
                    self.navigateToScreen(
                        screen: nextScreen,
                        round: nextRound,
                        rumbleCount: nextRumbleCount,
                        survivingPlayerIDs: survivingPlayerIDs,
                        eliminatedPlayerIDs: eliminatedPlayerIDs,
                        crewmatesWon: crewmatesWon
                    )
                }
            }
    }

    // ════════════════════════════════════════════════════════════════════
    // MARK: - NON-HOST: Listen for game state from host
    // ════════════════════════════════════════════════════════════════════
    
    private func nonHostListenForGameState() {
        guard !RoomManager.shared.isHost else { return }
        
        print("👂 [NON-HOST] Listening for gameState...")
        
        gameStateListener?.remove()
        gameStateListener = db.collection("rooms")
            .document(roomCode)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                guard !self.hasNavigated else { return }
                
                if let error = error {
                    print("❌ [NON-HOST] Listener error: \(error)")
                    return
                }
                
                guard let data = snapshot?.data(),
                      let gameState = data["gameState"] as? [String: Any] else {
                    print("👂 [NON-HOST] No gameState yet")
                    return
                }
                
                // ✅ Check if this update is for our current round
                let forRound = gameState["forRound"] as? Int ?? 0
                guard forRound == self.currentRound else {
                    print("👂 [NON-HOST] Ignoring gameState for round \(forRound), we're on \(self.currentRound)")
                    return
                }
                
                // ✅ Check timestamp to ensure it's a new update
                if let timestamp = gameState["timestamp"] as? Timestamp {
                    let stateTime = timestamp.dateValue().timeIntervalSince1970
                    guard stateTime > self.waitingForResultsSince else {
                        print("👂 [NON-HOST] Ignoring old gameState (before we submitted)")
                        return
                    }
                }
                
                let screen = gameState["screen"] as? String ?? ""
                let round = gameState["round"] as? Int ?? 1
                let rumbleCount = gameState["rumbleCount"] as? Int ?? 3
                let survivingPlayerIDs = gameState["survivingPlayerIDs"] as? [String] ?? []
                let eliminatedPlayerIDs = gameState["eliminatedPlayerIDs"] as? [String] ?? []
                let crewmatesWon = gameState["crewmatesWon"] as? Bool
                
                print("📡 [NON-HOST] Received gameState: screen=\(screen), round=\(round), forRound=\(forRound)")
                
                // ✅ Stop listening
                self.gameStateListener?.remove()
                self.gameStateListener = nil
                
                // ✅ Navigate
                DispatchQueue.main.async {
                    self.navigateToScreen(
                        screen: screen,
                        round: round,
                        rumbleCount: rumbleCount,
                        survivingPlayerIDs: survivingPlayerIDs,
                        eliminatedPlayerIDs: eliminatedPlayerIDs,
                        crewmatesWon: crewmatesWon
                    )
                }
            }
    }

    // ════════════════════════════════════════════════════════════════════
    // MARK: - Navigation (Both Host and Non-Host)
    // ════════════════════════════════════════════════════════════════════
    
    private func navigateToScreen(screen: String,
                                   round: Int,
                                   rumbleCount: Int,
                                   survivingPlayerIDs: [String],
                                   eliminatedPlayerIDs: [String],
                                   crewmatesWon: Bool?) {
        guard !hasNavigated else {
            print("⚠️ Already navigated, ignoring")
            return
        }
        hasNavigated = true
        
        cleanup()
        
        let myID = RoomManager.shared.currentUserID
        
        // Check if I was eliminated
        if eliminatedPlayerIDs.contains(myID) {
            print("💀 I was eliminated → Spectator")
            navigateToSpectator()
            return
        }
        
        print("🔄 Navigating to: \(screen)")
        
        switch screen {
        case "voting":
            navigateToVoting()
            
        case "haptics":
            let survivingPlayers = players.filter { survivingPlayerIDs.contains($0.id) }
            navigateToHaptics(round: round, rumbleCount: rumbleCount, players: survivingPlayers)
            
        case "result":
            navigateToGameResult(crewmatesWon: crewmatesWon ?? false)
            
        default:
            print("⚠️ Unknown screen: \(screen)")
        }
    }
    
    private func navigateToVoting() {
        let vc = VotingViewController(
            roomCode: roomCode,
            players: players,
            currentRound: currentRound
        )
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func navigateToHaptics(round: Int, rumbleCount: Int, players: [RoomManager.Player]) {
        let vc = HapticsRoomViewController(
            roomCode: roomCode,
            players: players,
            rumbleCount: rumbleCount,
            role: myRole
        )
        vc.currentRound = round
        vc.selectedAvatar = selectedAvatar
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func navigateToGameResult(crewmatesWon: Bool) {
        let vc = GameResultViewController(
            crewmatesWon: crewmatesWon,
            roomCode: roomCode,
            eliminatedPlayerName: "",
            eliminatedAvatarImage: "char1"
        )
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func navigateToSpectator() {
        let vc = SpectatorViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - Cleanup
    private func clearGuesses() {
        db.collection("rooms")
            .document(roomCode)
            .collection("guesses")
            .whereField("round", isEqualTo: currentRound)
            .getDocuments { [weak self] snapshot, _ in
                guard let documents = snapshot?.documents, !documents.isEmpty else { return }
                guard let self = self else { return }
                
                let batch = self.db.batch()
                for doc in documents {
                    batch.deleteDocument(doc.reference)
                }
                batch.commit { error in
                    if error == nil {
                        print("🧹 Cleared \(documents.count) guesses for round \(self.currentRound)")
                    }
                }
            }
    }
}
