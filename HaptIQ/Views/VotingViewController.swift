//
//  VotingViewController.swift
//  HaptIQ
//

import UIKit
import FirebaseFirestore

// MARK: - Vote Player Cell (Similar to PlayerCell but with selection state)
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
        
        // Set avatar image
        if let avatarImage = player.avatarImage {
            avatarImageView.image = UIImage(named: avatarImage)
        } else {
            avatarImageView.image = UIImage(named: "char1")
        }
        
        // Update selection state
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
    private var hasVoted = false  // 🔧 Prevent duplicate votes
    
    private let db = Firestore.firestore()
    private var voteListener: ListenerRegistration?
    private let gradientLayer = CAGradientLayer()

    // UI Components
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Who is the Imposter?"
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
        voteListener?.remove()
        print("🗑️ VotingViewController deallocated")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCollectionView()
        navigationItem.hidesBackButton = true
        
        print("🗳 Voting screen loaded - \(players.count) players")
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds
        applyGradients()
    }

    private func setupUI() {
        view.backgroundColor = .black
        
        // Add background image
        let backgroundImageView = UIImageView(frame: view.bounds)
        backgroundImageView.image = UIImage(named: "spiralBG")
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.alpha = 0.8
        backgroundImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(backgroundImageView)
        view.sendSubviewToBack(backgroundImageView)
        
        // Add gradient overlay
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
        // Apply gradient to vote button
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
    
    @objc private func castVote() {
        guard let selected = selectedPlayerID else { return }
        guard !hasVoted else {
            print("⚠️ Already voted")
            return
        }
        
        let myID = RoomManager.shared.currentUserID
        hasVoted = true
        
        // Disable interactions immediately
        voteButton.isEnabled = false
        voteButton.alpha = 0.5
        voteButton.setTitle("VOTE CAST", for: .normal)
        playersCollectionView.isUserInteractionEnabled = false
        
        print("🗳 Casting vote for: \(selected.prefix(4))")
        
        // Store vote in Firestore
        db.collection("rooms")
            .document(roomCode)
            .collection("votes")
            .document(myID)
            .setData([
                "voterID": myID,
                "votedFor": selected,
                "timestamp": FieldValue.serverTimestamp()
            ]) { error in
                if let error = error {
                    print("❌ Vote error:", error)
                    self.hasVoted = false  // Allow retry
                    self.voteButton.isEnabled = true
                    self.voteButton.alpha = 1.0
                    self.playersCollectionView.isUserInteractionEnabled = true
                    return
                }
                
                print("✅ Vote successfully cast")
                
                // Listen for all votes
                self.listenForAllVotes()
            }
    }
    
    private func listenForAllVotes() {
        voteListener?.remove()
        voteListener = db.collection("rooms")
            .document(roomCode)
            .collection("votes")
            .addSnapshotListener { [weak self] snap, error in
                guard let self = self else { return }
                guard let docs = snap?.documents else { return }
                
                print("📊 Votes received: \(docs.count)/\(self.players.count)")
                
                // Check if everyone has voted
                if docs.count >= self.players.count {
                    self.voteListener?.remove()  // Stop listening
                    self.evaluateVotes(docs.map { $0.data() })
                }
            }
    }
    
    private func evaluateVotes(_ votes: [[String: Any]]) {
        print("\n🗳 === EVALUATING VOTES ===")
        
        // Count votes for each player
        var voteCounts: [String: Int] = [:]
        
        for vote in votes {
            if let votedFor = vote["votedFor"] as? String {
                voteCounts[votedFor, default: 0] += 1
                print("📊 Vote for: \(votedFor.prefix(4))")
            }
        }
        
        // Find player with most votes
        guard let mostVotedID = voteCounts.max(by: { $0.value < $1.value })?.key else {
            print("❌ No votes found")
            return
        }
        
        let voteCount = voteCounts[mostVotedID] ?? 0
        print("🎯 Most voted: \(mostVotedID.prefix(4)) with \(voteCount) votes")
        
        // Check if voted player is imposter
        var imposterID = ""
        for (id, role) in RoomManager.shared.cachedRoles {
            if role == "imposter" {
                imposterID = id
                print("🎭 Imposter ID: \(id.prefix(4))")
            }
        }
        
        // Clear votes for next phase
        clearVotes()
        
        if mostVotedID == imposterID {
            // ✅ CREWMATES WIN - Found the imposter!
            print("🎉 CREWMATES WIN - Imposter voted out!")
            DispatchQueue.main.async {
                self.showGameResult(crewmatesWon: true)
            }
        } else {
            // ❌ Wrong person voted out
            print("❌ Wrong person voted out: \(mostVotedID.prefix(4))")
            
            // Remove voted player from players array
            players.removeAll { $0.id == mostVotedID }
            print("👥 Remaining players: \(players.count)")
            
            let myID = RoomManager.shared.currentUserID
            
            if myID == mostVotedID {
                // I was voted out - Go to spectator
                print("💀 I was voted out → Spectator")
                DispatchQueue.main.async {
                    self.navigationController?.pushViewController(
                        SpectatorViewController(),
                        animated: true
                    )
                }
            } else if myID == imposterID && players.count == 1 {
                // Only 1 crewmate left and I'm imposter - IMPOSTER WINS
                print("🏆 IMPOSTER WINS - Only 1 crewmate left!")
                DispatchQueue.main.async {
                    self.showGameResult(crewmatesWon: false)
                }
            } else {
                // Continue game with remaining players
                print("➡️ Continuing to next round")
                DispatchQueue.main.async {
                    self.continueNextRound()
                }
            }
        }
        
        print("=== END VOTE EVALUATION ===\n")
    }
    
    private func continueNextRound() {
        let nextRumble = Int.random(in: 2...5)
        let myID = RoomManager.shared.currentUserID
        let myRole: HapticsRoomViewController.PlayerRole =
            (RoomManager.shared.cachedRoles[myID] == "imposter") ? .imposter : .crewmate
        
        print("🎮 Next round: \(currentRound + 1), Rumbles: \(nextRumble), Players: \(players.count)")
        
        let vc = HapticsRoomViewController(
            roomCode: roomCode,
            players: players,
            rumbleCount: nextRumble,
            role: myRole
        )
        vc.currentRound = currentRound + 1
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func showGameResult(crewmatesWon: Bool) {
        let vc = GameResultViewController(crewmatesWon: crewmatesWon, roomCode: roomCode)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func clearVotes() {
        db.collection("rooms")
            .document(roomCode)
            .collection("votes")
            .getDocuments { snap, _ in
                guard let docs = snap?.documents else { return }
                let batch = self.db.batch()
                for doc in docs {
                    batch.deleteDocument(doc.reference)
                }
                batch.commit { error in
                    if let error = error {
                        print("❌ Error clearing votes: \(error)")
                    } else {
                        print("🧹 Cleared \(docs.count) votes")
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
        // 3 columns with spacing
        let totalSpacing: CGFloat = 30 // 2 gaps of 15 between 3 columns
        let width = (collectionView.bounds.width - totalSpacing) / 3
        let height = width + 30 // Square avatar + space for name
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard !hasVoted else {
            print("⚠️ Already voted, can't change selection")
            return
        }
        
        let selectedPlayer = players[indexPath.item]
        let myID = RoomManager.shared.currentUserID
        
        // Prevent voting for yourself
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
        
        // Update selection
        selectedPlayerID = selectedPlayer.id
        print("👆 Selected: \(selectedPlayer.name) (\(selectedPlayer.id.prefix(4)))")
        
        // Enable vote button
        voteButton.isEnabled = true
        voteButton.alpha = 1.0
        
        // Reload collection view to update visual selection
        collectionView.reloadData()
    }
}
