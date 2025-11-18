//
//  VotingViewController.swift
//  HaptIQ
//
//  Created by Shreyansh on 17/11/25.
//

import UIKit
import FirebaseFirestore

final class VotingViewController: UIViewController {
    
    private let roomCode: String
    private let players: [RoomManager.Player]
    private var selectedPlayerID: String?

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Who is the Imposter?"
        l.textColor = .white
        l.font = UIFont(name: "WinniePERSONALUSE", size: 38)
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
        b.titleLabel?.font = UIFont(name: "WinniePERSONALUSE", size: 24)
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = UIColor(red: 255/255, green: 72/255, blue: 72/255, alpha: 1)
        b.layer.cornerRadius = 18
        b.translatesAutoresizingMaskIntoConstraints = false
        b.isHidden = true
        return b
    }()
    
    init(roomCode: String, players: [RoomManager.Player]) {
        self.roomCode = roomCode
        self.players = players
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
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
        
        print("🗳 Voted for:", selected)
        
        // TODO: Write Firestore voting logic here
        
        navigationController?.popViewController(animated: true)
    }
}

extension VotingViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return players.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "VoteCell", for: indexPath) as! VoteCell
        cell.setPlayer(players[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedPlayerID = players[indexPath.row].id
        voteButton.isHidden = false
    }
}

final class VoteCell: UITableViewCell {
    
    private let nameLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = UIColor.white.withAlphaComponent(0.1)
        layer.cornerRadius = 12
        layer.masksToBounds = true
        
        nameLabel.font = UIFont(name: "WinniePERSONALUSE", size: 22)
        nameLabel.textColor = .white
        nameLabel.textAlignment = .center
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(nameLabel)
        NSLayoutConstraint.activate([
            nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setPlayer(_ player: RoomManager.Player) {
        nameLabel.text = player.name
    }
}
