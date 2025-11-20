//
//  VotingViewController.swift
//  HaptIQ
//

import UIKit
import FirebaseFirestore

final class VotingViewController: UIViewController {
    
    private let roomCode: String
    private var players: [RoomManager.Player]
    private var selectedPlayerID: String?
    private let currentRound: Int
    
    private let db = Firestore.firestore()
    private var voteListener: ListenerRegistration?

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Who is the Imposter?"
        l.textColor = .white
        l.font = UIFont(name: "Aclonica-Regular", size: 38)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let tableView: UITableView = {
        let tv = UITableView()
        tv.backgroundColor = .clear
        tv.separatorStyle = .none
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()
    
    private let voteButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("CAST VOTE", for: .normal)
        b.titleLabel?.font = UIFont(name: "Aclonica-Regular", size: 24)
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = UIColor(red: 255/255, green: 72/255, blue: 72/255, alpha: 1)
        b.layer.cornerRadius = 18
        b.translatesAutoresizingMaskIntoConstraints = false
        b.isHidden = true
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
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        navigationItem.hidesBackButton = true  // Can't go back during voting
        
        setupTable()
        setupUI()
    }

    private func setupUI() {
        view.addSubview(titleLabel)
        view.addSubview(tableView)
        view.addSubview(voteButton)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            tableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            tableView.bottomAnchor.constraint(equalTo: voteButton.topAnchor, constant: -20),
            
            voteButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            voteButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            voteButton.widthAnchor.constraint(equalToConstant: 200),
            voteButton.heightAnchor.constraint(equalToConstant: 55)
        ])
        
        voteButton.addTarget(self, action: #selector(castVote), for: .touchUpInside)
    }

    private func setupTable() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(VoteCell.self, forCellReuseIdentifier: "VoteCell")
    }
    
    @objc private func castVote() {
        guard let selected = selectedPlayerID else { return }
        
        let myID = RoomManager.shared.currentUserID
        
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
                    return
                }
                
                print("✅ Vote cast for: \(selected)")
                
                // Disable button after voting
                self.voteButton.isEnabled = false
                self.voteButton.alpha = 0.5
                self.voteButton.setTitle("VOTE CAST", for: .normal)
                
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
                
                // Check if everyone has voted
                if docs.count >= self.players.count {
                    self.evaluateVotes(docs.map { $0.data() })
                }
            }
    }
    
    private func evaluateVotes(_ votes: [[String: Any]]) {
        // Count votes for each player
        var voteCounts: [String: Int] = [:]
        
        for vote in votes {
            if let votedFor = vote["votedFor"] as? String {
                voteCounts[votedFor, default: 0] += 1
            }
        }
        
        // Find player with most votes
        guard let mostVotedID = voteCounts.max(by: { $0.value < $1.value })?.key else {
            print("❌ No votes found")
            return
        }
        
        let voteCount = voteCounts[mostVotedID] ?? 0
        print("🗳 Most voted: \(mostVotedID) with \(voteCount) votes")
        
        // Check if voted player is imposter
        var imposterID = ""
        for (id, role) in RoomManager.shared.cachedRoles {
            if role == "imposter" { imposterID = id }
        }
        
        // Clear votes for next game
        clearVotes()
        
        if mostVotedID == imposterID {
            // ✅ CREWMATES WIN - Found the imposter!
            DispatchQueue.main.async {
                self.showGameResult(crewmatesWon: true)
            }
        } else {
            // ❌ Wrong person voted out - Remove them from game
            
            // Remove voted player from players array
            players.removeAll { $0.id == mostVotedID }
            
            let myID = RoomManager.shared.currentUserID
            
            if myID == mostVotedID {
                // I was voted out - Go to spectator
                DispatchQueue.main.async {
                    self.navigationController?.pushViewController(
                        SpectatorViewController(),
                        animated: true
                    )
                }
            } else if myID == imposterID && players.count == 1 {
                // Only 1 crewmate left and I'm imposter - IMPOSTER WINS
                DispatchQueue.main.async {
                    self.showGameResult(crewmatesWon: false)
                }
            } else {
                // Continue game with remaining players
                DispatchQueue.main.async {
                    self.continueNextRound()
                }
            }
        }
    }
    
    private func continueNextRound() {
        let nextRumble = Int.random(in: 2...5)
        let myID = RoomManager.shared.currentUserID
        let myRole: HapticsRoomViewController.PlayerRole =
            (RoomManager.shared.cachedRoles[myID] == "imposter") ? .imposter : .crewmate
        
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
                batch.commit()
            }
    }
}

// MARK: - TableView
extension VotingViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return players.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "VoteCell", for: indexPath) as! VoteCell
        cell.setPlayer(players[indexPath.row])
        cell.selectionStyle = .none
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Prevent voting for yourself
        let myID = RoomManager.shared.currentUserID
        let selectedPlayer = players[indexPath.row]
        
        if selectedPlayer.id == myID {
            let alert = UIAlertController(
                title: "Invalid Vote",
                message: "You cannot vote for yourself!",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            tableView.deselectRow(at: indexPath, animated: true)
            return
        }
        
        selectedPlayerID = selectedPlayer.id
        voteButton.isHidden = false
        
        // Visual feedback - highlight selected cell
        for i in 0..<players.count {
            if let cell = tableView.cellForRow(at: IndexPath(row: i, section: 0)) as? VoteCell {
                cell.setSelected(i == indexPath.row)
            }
        }
    }
}

// MARK: - Vote Cell
final class VoteCell: UITableViewCell {
    
    private let nameLabel = UILabel()
    private let checkmark = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = UIColor.white.withAlphaComponent(0.1)
        layer.cornerRadius = 12
        layer.masksToBounds = true
        
        nameLabel.font = UIFont(name: "Aclonica-Regular", size: 22)
        nameLabel.textColor = .white
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        checkmark.image = UIImage(systemName: "checkmark.circle.fill")
        checkmark.tintColor = UIColor(red: 21/255, green: 174/255, blue: 21/255, alpha: 1)
        checkmark.translatesAutoresizingMaskIntoConstraints = false
        checkmark.isHidden = true
        
        contentView.addSubview(nameLabel)
        contentView.addSubview(checkmark)
        
        NSLayoutConstraint.activate([
            nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            checkmark.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            checkmark.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            checkmark.widthAnchor.constraint(equalToConstant: 28),
            checkmark.heightAnchor.constraint(equalToConstant: 28)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setPlayer(_ player: RoomManager.Player) {
        nameLabel.text = player.name
    }
    
    func setSelected(_ selected: Bool) {
        checkmark.isHidden = !selected
        backgroundColor = selected ?
            UIColor.white.withAlphaComponent(0.2) :
            UIColor.white.withAlphaComponent(0.1)
    }
}
