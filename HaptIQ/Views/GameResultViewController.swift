//
//  GameResultViewController.swift
//  HaptIQ
//
//  Created by Shreyansh on 20/11/25.
//

//
//  GameResultViewController.swift
//  HaptIQ
//

import UIKit
import FirebaseFirestore

final class GameResultViewController: UIViewController {
    
    private let crewmatesWon: Bool
    private let roomCode: String
    
    private let bgImage: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "bghex"))
        iv.contentMode = .scaleAspectFill
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let resultLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "Aclonica-Regular", size: 48)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        l.numberOfLines = 2
        return l
    }()
    
    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "Aclonica-Regular", size: 24)
        l.textColor = .white
        l.textAlignment = .center
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let iconView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let playAgainButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("PLAY AGAIN", for: .normal)
        b.backgroundColor = UIColor(red: 21/255, green: 174/255, blue: 21/255, alpha: 1)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = UIFont(name: "Aclonica-Regular", size: 24)
        b.layer.cornerRadius = 22
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()
    
    private let exitButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("EXIT TO MENU", for: .normal)
        b.backgroundColor = UIColor(red: 255/255, green: 72/255, blue: 72/255, alpha: 1)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = UIFont(name: "Aclonica-Regular", size: 24)
        b.layer.cornerRadius = 22
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()
    
    init(crewmatesWon: Bool, roomCode: String) {
        self.crewmatesWon = crewmatesWon
        self.roomCode = roomCode
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        setupUI()
        configureResult()
    }
    
    private func setupUI() {
        view.addSubview(bgImage)
        view.addSubview(iconView)
        view.addSubview(resultLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(playAgainButton)
        view.addSubview(exitButton)
        
        NSLayoutConstraint.activate([
            bgImage.topAnchor.constraint(equalTo: view.topAnchor),
            bgImage.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bgImage.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bgImage.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            iconView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            iconView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 180),
            iconView.heightAnchor.constraint(equalToConstant: 180),
            
            resultLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 40),
            resultLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            resultLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            
            subtitleLabel.topAnchor.constraint(equalTo: resultLabel.bottomAnchor, constant: 20),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            playAgainButton.bottomAnchor.constraint(equalTo: exitButton.topAnchor, constant: -20),
            playAgainButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playAgainButton.widthAnchor.constraint(equalToConstant: 260),
            playAgainButton.heightAnchor.constraint(equalToConstant: 60),
            
            exitButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            exitButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            exitButton.widthAnchor.constraint(equalToConstant: 260),
            exitButton.heightAnchor.constraint(equalToConstant: 60)
        ])
        
        playAgainButton.addTarget(self, action: #selector(playAgainTapped), for: .touchUpInside)
        exitButton.addTarget(self, action: #selector(exitTapped), for: .touchUpInside)
    }
    
    private func configureResult() {
        let myID = RoomManager.shared.currentUserID
        let myRole = RoomManager.shared.cachedRoles[myID]
        let iWasImposter = (myRole == "imposter")
        
        if crewmatesWon {
            // Crewmates won
            if iWasImposter {
                // I was imposter and lost
                resultLabel.text = "YOU LOSE!"
                resultLabel.textColor = UIColor(red: 255/255, green: 72/255, blue: 72/255, alpha: 1)
                subtitleLabel.text = "The crew caught you!\nBetter luck next time."
                iconView.image = UIImage(named: "Mafia") // Use your imposter icon
            } else {
                // I was crewmate and won
                resultLabel.text = "VICTORY!"
                resultLabel.textColor = UIColor(red: 21/255, green: 174/255, blue: 21/255, alpha: 1)
                subtitleLabel.text = "You caught the imposter!\nGreat teamwork!"
                iconView.image = UIImage(systemName: "crown.fill")
                iconView.tintColor = .yellow
            }
        } else {
            // Imposter won
            if iWasImposter {
                // I was imposter and won
                resultLabel.text = "VICTORY!"
                resultLabel.textColor = UIColor(red: 255/255, green: 72/255, blue: 72/255, alpha: 1)
                subtitleLabel.text = "You fooled everyone!\nMaster of deception!"
                iconView.image = UIImage(named: "Mafia")
            } else {
                // I was crewmate and lost
                resultLabel.text = "YOU LOSE!"
                resultLabel.textColor = UIColor(red: 255/255, green: 72/255, blue: 72/255, alpha: 1)
                subtitleLabel.text = "The imposter won!\nTry to be more careful next time."
                iconView.image = UIImage(systemName: "xmark.circle.fill")
                iconView.tintColor = .red
            }
        }
    }
    
    @objc private func playAgainTapped() {
        // Clear game data and go back to lobby
        clearGameData()
        
        // Navigate back to room lobby
        let vc = RoomLobbyViewController(roomCode: roomCode)
        
        // Clear navigation stack and set lobby as root
        if let nav = navigationController {
            var viewControllers = nav.viewControllers
            // Keep only the initial screens and add lobby
            if let joinRoomIndex = viewControllers.firstIndex(where: { $0 is JoinRoomViewController }) {
                viewControllers = Array(viewControllers[0...joinRoomIndex])
            }
            viewControllers.append(vc)
            nav.setViewControllers(viewControllers, animated: true)
        }
    }
    
    @objc private func exitTapped() {
        // Clear game data
        clearGameData()
        
        // Go back to main menu
        let vc = JoinRoomViewController()
        
        if let nav = navigationController {
            // Find the JoinRoomViewController in stack or create new one
            if let existing = nav.viewControllers.first(where: { $0 is JoinRoomViewController }) {
                nav.popToViewController(existing, animated: true)
            } else {
                nav.setViewControllers([vc], animated: true)
            }
        }
    }
    
    private func clearGameData() {
        let db = Firestore.firestore()
        let roomRef = db.collection("rooms").document(roomCode)
        
        // Clear guesses
        roomRef.collection("guesses").getDocuments { snap, _ in
            guard let docs = snap?.documents else { return }
            for doc in docs {
                doc.reference.delete()
            }
        }
        
        // Clear votes
        roomRef.collection("votes").getDocuments { snap, _ in
            guard let docs = snap?.documents else { return }
            for doc in docs {
                doc.reference.delete()
            }
        }
        
        // Clear roles and state
        roomRef.updateData([
            "roles": FieldValue.delete(),
            "state": FieldValue.delete()
        ])
        
        // Clear cached roles locally
        RoomManager.shared.cachedRoles = [:]
    }
}
