//
//  VotingViewController.swift
//  HaptIQ
//

import UIKit
import FirebaseFirestore

// MARK: - Vote Player Cell
class VotePlayerCell: UICollectionViewCell {
    
    private let containerView: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.layer.borderWidth = 3
        iv.layer.borderColor = UIColor.white.cgColor
        iv.layer.cornerRadius = 1
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let nameLabel: UILabel = {
        let l = UILabel()
        l.textColor = .white
        l.font = UIFont(name: "Aclonica-Regular", size: 14)
        l.textAlignment = .center
        l.numberOfLines = 1
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let selectionOverlay: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 21/255, green: 174/255, blue: 21/255, alpha: 0.3)
        v.layer.cornerRadius = 1
        v.isHidden = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let checkmarkImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "checkmark.circle.fill")
        iv.tintColor = UIColor(red: 21/255, green: 174/255, blue: 21/255, alpha: 1)
        iv.contentMode = .scaleAspectFit
        iv.isHidden = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        contentView.addSubview(containerView)
        containerView.addSubview(avatarImageView)
        containerView.addSubview(selectionOverlay)
        containerView.addSubview(checkmarkImageView)
        containerView.addSubview(nameLabel)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            avatarImageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            avatarImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            avatarImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            avatarImageView.heightAnchor.constraint(equalTo: avatarImageView.widthAnchor),
            
            selectionOverlay.topAnchor.constraint(equalTo: avatarImageView.topAnchor),
            selectionOverlay.leadingAnchor.constraint(equalTo: avatarImageView.leadingAnchor),
            selectionOverlay.trailingAnchor.constraint(equalTo: avatarImageView.trailingAnchor),
            selectionOverlay.bottomAnchor.constraint(equalTo: avatarImageView.bottomAnchor),
            
            checkmarkImageView.centerXAnchor.constraint(equalTo: avatarImageView.centerXAnchor),
            checkmarkImageView.centerYAnchor.constraint(equalTo: avatarImageView.centerYAnchor),
            checkmarkImageView.widthAnchor.constraint(equalToConstant: 50),
            checkmarkImageView.heightAnchor.constraint(equalToConstant: 50),
            
            nameLabel.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            nameLabel.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor),
        ])
    }
    
    func configure(with player: RoomManager.Player, isSelected: Bool) {
        nameLabel.text = player.name
        
        if let avatarImage = player.avatarImage {
            avatarImageView.image = UIImage(named: avatarImage)
        } else {
            avatarImageView.image = UIImage(named: "char1")
        }
        
        setSelected(isSelected)
    }
    
    func setSelected(_ selected: Bool) {
        selectionOverlay.isHidden = !selected
        checkmarkImageView.isHidden = !selected
        
        if selected {
            avatarImageView.layer.borderColor = UIColor(red: 21/255, green: 174/255, blue: 21/255, alpha: 1).cgColor
            avatarImageView.layer.borderWidth = 4
        } else {
            avatarImageView.layer.borderColor = UIColor.white.cgColor
            avatarImageView.layer.borderWidth = 3
        }
    }
}

// MARK: - Voting View Controller
final class VotingViewController: UIViewController {
    
    private let roomCode: String
    private var players: [RoomManager.Player]
    private var selectedPlayerID: String?
    private let currentRound: Int
    
    private var hasVoted = false
    private var hasNavigated = false
    private var waitingForResultsSince: TimeInterval = 0
    
    private let db = Firestore.firestore()
    private var voteListener: ListenerRegistration?
    private var gameStateListener: ListenerRegistration?
    private let gradientLayer = CAGradientLayer()

    // UI Components
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Time to Vote"
        l.textColor = .white
        l.font = UIFont(name: "Aclonica-Regular", size: 32)
        l.textAlignment = .center
        l.numberOfLines = 2
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let instructionLabel: UILabel = {
        let l = UILabel()
        l.text = "Tap a player to vote them out"
        l.textColor = UIColor.white.withAlphaComponent(0.7)
        l.font = UIFont(name: "Aclonica-Regular", size: 14)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let playersCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 20
        layout.minimumInteritemSpacing = 15
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()
    
    private let voteButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("CAST VOTE", for: .normal)
        b.titleLabel?.font = UIFont(name: "Aclonica-Regular", size: 24)
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = UIColor(red: 255/255, green: 72/255, blue: 72/255, alpha: 1)
        b.layer.cornerRadius = 20
        b.translatesAutoresizingMaskIntoConstraints = false
        b.alpha = 0.5
        b.isEnabled = false
        return b
    }()
    
    init(roomCode: String, players: [RoomManager.Player], currentRound: Int = 1) {
        self.roomCode = roomCode
        self.players = players
        self.currentRound = currentRound
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    deinit {
        cleanup()
        print("🗑️ VotingViewController deallocated")
    }
    
    private func cleanup() {
        voteListener?.remove()
        voteListener = nil
        gameStateListener?.remove()
        gameStateListener = nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCollectionView()
        navigationItem.hidesBackButton = true
        
        print("🗳 Voting screen loaded - \(players.count) players, Round \(currentRound)")
        print("👑 Am I host? \(RoomManager.shared.isHost)")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cleanup()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds
        applyGradients()
    }

    private func setupUI() {
        view.backgroundColor = .black
        
        let backgroundImageView = UIImageView(frame: view.bounds)
        backgroundImageView.image = UIImage(named: "spiralBG")
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.alpha = 0.8
        backgroundImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(backgroundImageView)
        view.sendSubviewToBack(backgroundImageView)
        
        gradientLayer.colors = [
            UIColor(red: 6/255, green: 27/255, blue: 53/255, alpha: 0.6).cgColor,
            UIColor(red: 18/255, green: 57/255, blue: 99/255, alpha: 0.6).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        view.layer.insertSublayer(gradientLayer, at: 1)
        
        view.addSubview(titleLabel)
        view.addSubview(instructionLabel)
        view.addSubview(playersCollectionView)
        view.addSubview(voteButton)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            instructionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            instructionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            playersCollectionView.topAnchor.constraint(equalTo: instructionLabel.bottomAnchor, constant: 30),
            playersCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            playersCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            playersCollectionView.bottomAnchor.constraint(equalTo: voteButton.topAnchor, constant: -20),
            
            voteButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            voteButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            voteButton.widthAnchor.constraint(equalToConstant: 280),
            voteButton.heightAnchor.constraint(equalToConstant: 60)
        ])
        
        voteButton.addTarget(self, action: #selector(castVote), for: .touchUpInside)
    }
    
    private func applyGradients() {
        voteButton.applyGradient(
            colors: [
                UIColor(red: 255/255, green: 72/255, blue: 72/255, alpha: 1),
                UIColor(red: 255/255, green: 120/255, blue: 120/255, alpha: 1)
            ],
            startPoint: CGPoint(x: 0, y: 0.5),
            endPoint: CGPoint(x: 1, y: 0.5),
            cornerRadius: 20
        )
    }

    private func setupCollectionView() {
        playersCollectionView.delegate = self
        playersCollectionView.dataSource = self
        playersCollectionView.register(VotePlayerCell.self, forCellWithReuseIdentifier: "VotePlayerCell")
    }
    
    // MARK: - Cast Vote
    @objc private func castVote() {
        guard let selected = selectedPlayerID else { return }
        guard !hasVoted else { return }
        
        hasVoted = true
        waitingForResultsSince = Date().timeIntervalSince1970
        
        let myID = RoomManager.shared.currentUserID
        
        voteButton.isEnabled = false
        voteButton.alpha = 0.5
        voteButton.setTitle("VOTE CAST", for: .normal)
        playersCollectionView.isUserInteractionEnabled = false
        
        print("🗳 Casting vote for: \(String(selected.prefix(8)))")
        
        db.collection("rooms")
            .document(roomCode)
            .collection("votes")
            .document(myID)
            .setData([
                "voterID": myID,
                "votedFor": selected,
                "round": currentRound,
                "timestamp": FieldValue.serverTimestamp()
            ]) { [weak self] error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Vote error: \(error)")
                    self.hasVoted = false
                    self.voteButton.isEnabled = true
                    self.voteButton.alpha = 1.0
                    self.voteButton.setTitle("CAST VOTE", for: .normal)
                    self.playersCollectionView.isUserInteractionEnabled = true
                    return
                }
                
                print("✅ Vote cast successfully")
                
                if RoomManager.shared.isHost {
                    // ✅ HOST: Listen for all votes, then evaluate
                    self.hostListenForAllVotes()
                } else {
                    // ✅ NON-HOST: Listen for voteResult from host
                    self.nonHostListenForVoteResult()
                }
            }
    }
    
    // ════════════════════════════════════════════════════════════════════
    // MARK: - HOST ONLY: Listen for all votes and evaluate
    // ════════════════════════════════════════════════════════════════════
    
    private func hostListenForAllVotes() {
        guard RoomManager.shared.isHost else { return }
        
        print("👑 [HOST] Listening for all votes...")
        
        voteListener?.remove()
        voteListener = db.collection("rooms")
            .document(roomCode)
            .collection("votes")
            .whereField("round", isEqualTo: currentRound)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                guard RoomManager.shared.isHost else { return }
                guard !self.hasNavigated else { return }
                
                if let error = error {
                    print("❌ [HOST] Vote listener error: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                print("👑 [HOST] Votes: \(documents.count)/\(self.players.count)")
                
                if documents.count >= self.players.count {
                    print("👑 [HOST] All votes received!")
                    
                    self.voteListener?.remove()
                    self.voteListener = nil
                    
                    let allVotes = documents.map { $0.data() }
                    self.hostEvaluateVotesAndWriteResult(allVotes)
                }
            }
    }
    
    private func hostEvaluateVotesAndWriteResult(_ votes: [[String: Any]]) {
        guard RoomManager.shared.isHost else { return }
        guard !hasNavigated else { return }
        
        print("\n👑 [HOST] === EVALUATING VOTES ===")
        
        // Count votes
        var voteCounts: [String: Int] = [:]
        for vote in votes {
            if let votedFor = vote["votedFor"] as? String {
                voteCounts[votedFor, default: 0] += 1
                print("👑 [HOST] Vote for: \(String(votedFor.prefix(8)))")
            }
        }
        
        // Find most voted
        guard let mostVotedID = voteCounts.max(by: { $0.value < $1.value })?.key else {
            print("❌ [HOST] No votes found")
            return
        }
        
        let voteCount = voteCounts[mostVotedID] ?? 0
        print("👑 [HOST] Most voted: \(String(mostVotedID.prefix(8))) with \(voteCount) votes")
        
        // Find imposter
        var imposterID = ""
        for (id, role) in RoomManager.shared.cachedRoles {
            if role == "imposter" {
                imposterID = id
                break
            }
        }
        print("👑 [HOST] Imposter: \(String(imposterID.prefix(8)))")
        
        // Determine result
        var nextScreen: String
        var crewmatesWon: Bool? = nil
        var eliminatedPlayerID = mostVotedID
        var survivingPlayerIDs = players.map { $0.id }
        
        if mostVotedID == imposterID {
            // ✅ Crewmates win!
            print("👑 [HOST] Decision: → RESULT (Crewmates win - Imposter voted out!)")
            nextScreen = "result"
            crewmatesWon = true
        } else {
            // ❌ Wrong person voted out
            print("👑 [HOST] Decision: Wrong person voted out")
            
            survivingPlayerIDs = players.map { $0.id }.filter { $0 != mostVotedID }
            let crewmatesRemaining = survivingPlayerIDs.filter { $0 != imposterID }.count
            
            if crewmatesRemaining <= 1 {
                // Imposter wins
                print("👑 [HOST] → RESULT (Imposter wins - only \(crewmatesRemaining) crewmate left)")
                nextScreen = "result"
                crewmatesWon = false
            } else {
                // Continue to next haptics round
                print("👑 [HOST] → HAPTICS (Continue with \(survivingPlayerIDs.count) players)")
                nextScreen = "haptics"
            }
        }
        
        // Get eliminated player info
        let eliminatedPlayer = players.first(where: { $0.id == eliminatedPlayerID })
        let eliminatedName = eliminatedPlayer?.name ?? ""
        let eliminatedAvatar = eliminatedPlayer?.avatarImage ?? "char1"
        
        // ✅ Write vote result to Firestore
        let voteResultData: [String: Any] = [
            "screen": nextScreen,
            "round": currentRound + 1,
            "rumbleCount": Int.random(in: 2...5),
            "survivingPlayerIDs": survivingPlayerIDs,
            "eliminatedPlayerID": eliminatedPlayerID,
            "eliminatedPlayerName": eliminatedName,
            "eliminatedAvatarImage": eliminatedAvatar,
            "crewmatesWon": crewmatesWon as Any,
            "forVotingRound": currentRound,
            "timestamp": FieldValue.serverTimestamp()
        ]
        
        print("👑 [HOST] Writing voteResult: screen=\(nextScreen)")
        
        db.collection("rooms")
            .document(roomCode)
            .updateData(["voteResult": voteResultData]) { [weak self] error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ [HOST] Failed to write voteResult: \(error)")
                    return
                }
                
                print("✅ [HOST] voteResult written successfully")
                
                // Clear votes
                self.clearVotes()
                
                // Host navigates
                DispatchQueue.main.async {
                    self.navigateBasedOnResult(
                        screen: nextScreen,
                        round: self.currentRound + 1,
                        rumbleCount: voteResultData["rumbleCount"] as? Int ?? 3,
                        survivingPlayerIDs: survivingPlayerIDs,
                        eliminatedPlayerID: eliminatedPlayerID,
                        crewmatesWon: crewmatesWon,
                        eliminatedName: eliminatedName,
                        eliminatedAvatar: eliminatedAvatar
                    )
                }
            }
    }
    
    // ════════════════════════════════════════════════════════════════════
    // MARK: - NON-HOST: Listen for vote result from host
    // ════════════════════════════════════��═══════════════════════════════
    
    private func nonHostListenForVoteResult() {
        guard !RoomManager.shared.isHost else { return }
        
        print("👂 [NON-HOST] Listening for voteResult...")
        
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
                      let voteResult = data["voteResult"] as? [String: Any] else {
                    return
                }
                
                // Check if this is for our voting round
                let forVotingRound = voteResult["forVotingRound"] as? Int ?? 0
                guard forVotingRound == self.currentRound else {
                    print("👂 [NON-HOST] Ignoring voteResult for round \(forVotingRound), we're on \(self.currentRound)")
                    return
                }
                
                // Check timestamp
                if let timestamp = voteResult["timestamp"] as? Timestamp {
                    let resultTime = timestamp.dateValue().timeIntervalSince1970
                    guard resultTime > self.waitingForResultsSince else {
                        print("👂 [NON-HOST] Ignoring old voteResult")
                        return
                    }
                }
                
                let screen = voteResult["screen"] as? String ?? ""
                let round = voteResult["round"] as? Int ?? self.currentRound + 1
                let rumbleCount = voteResult["rumbleCount"] as? Int ?? 3
                let survivingPlayerIDs = voteResult["survivingPlayerIDs"] as? [String] ?? []
                let eliminatedPlayerID = voteResult["eliminatedPlayerID"] as? String ?? ""
                let crewmatesWon = voteResult["crewmatesWon"] as? Bool
                let eliminatedName = voteResult["eliminatedPlayerName"] as? String ?? ""
                let eliminatedAvatar = voteResult["eliminatedAvatarImage"] as? String ?? "char1"
                
                print("📡 [NON-HOST] Received voteResult: screen=\(screen)")
                
                self.gameStateListener?.remove()
                self.gameStateListener = nil
                
                DispatchQueue.main.async {
                    self.navigateBasedOnResult(
                        screen: screen,
                        round: round,
                        rumbleCount: rumbleCount,
                        survivingPlayerIDs: survivingPlayerIDs,
                        eliminatedPlayerID: eliminatedPlayerID,
                        crewmatesWon: crewmatesWon,
                        eliminatedName: eliminatedName,
                        eliminatedAvatar: eliminatedAvatar
                    )
                }
            }
    }
    
    // ════════════════════════════════════════════════════════════════════
    // MARK: - Navigation
    // ════════════════════════════════════════════════════════════════════
    
    private func navigateBasedOnResult(screen: String,
                                        round: Int,
                                        rumbleCount: Int,
                                        survivingPlayerIDs: [String],
                                        eliminatedPlayerID: String,
                                        crewmatesWon: Bool?,
                                        eliminatedName: String,
                                        eliminatedAvatar: String) {
        guard !hasNavigated else { return }
        hasNavigated = true
        
        cleanup()
        
        let myID = RoomManager.shared.currentUserID
        
        // Check if I was voted out
        if eliminatedPlayerID == myID {
            print("💀 I was voted out → Spectator")
            navigateToSpectator()
            return
        }
        
        print("🔄 Navigating to: \(screen)")
        
        switch screen {
        case "result":
            navigateToGameResult(
                crewmatesWon: crewmatesWon ?? false,
                eliminatedName: eliminatedName,
                eliminatedAvatar: eliminatedAvatar
            )
            
        case "haptics":
            let survivingPlayers = players.filter { survivingPlayerIDs.contains($0.id) }
            navigateToHaptics(round: round, rumbleCount: rumbleCount, players: survivingPlayers)
            
        default:
            print("⚠️ Unknown screen: \(screen)")
        }
    }
    
    private func navigateToGameResult(crewmatesWon: Bool, eliminatedName: String, eliminatedAvatar: String) {
        let vc = GameResultViewController(
            crewmatesWon: crewmatesWon,
            roomCode: roomCode,
            eliminatedPlayerName: eliminatedName,
            eliminatedAvatarImage: eliminatedAvatar
        )
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func navigateToHaptics(round: Int, rumbleCount: Int, players: [RoomManager.Player]) {
        let myID = RoomManager.shared.currentUserID
        let myRole: HapticsRoomViewController.PlayerRole =
            (RoomManager.shared.cachedRoles[myID] == "imposter") ? .imposter : .crewmate
        
        let vc = HapticsRoomViewController(
            roomCode: roomCode,
            players: players,
            rumbleCount: rumbleCount,
            role: myRole
        )
        vc.currentRound = round
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func navigateToSpectator() {
        let vc = SpectatorViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    // MARK: - Cleanup
    private func clearVotes() {
        db.collection("rooms")
            .document(roomCode)
            .collection("votes")
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
                        print("🧹 Cleared \(documents.count) votes")
                    }
                }
            }
    }
}

// MARK: - CollectionView DataSource & Delegate
extension VotingViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return players.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VotePlayerCell", for: indexPath) as! VotePlayerCell
        let player = players[indexPath.item]
        let isSelected = player.id == selectedPlayerID
        cell.configure(with: player, isSelected: isSelected)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let totalSpacing: CGFloat = 30
        let width = (collectionView.bounds.width - totalSpacing) / 3
        let height = width + 30
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard !hasVoted else { return }
        
        let selectedPlayer = players[indexPath.item]
        let myID = RoomManager.shared.currentUserID
        
        // Can't vote for yourself
        if selectedPlayer.id == myID {
            let alert = UIAlertController(
                title: "Invalid Vote",
                message: "You cannot vote for yourself!",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        selectedPlayerID = selectedPlayer.id
        print("👆 Selected: \(selectedPlayer.name)")
        
        voteButton.isEnabled = true
        voteButton.alpha = 1.0
        
        collectionView.reloadData()
    }
}
