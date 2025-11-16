import UIKit
import FirebaseFirestore

final class RoomLobbyViewController: UIViewController {
    
    private let roomCode: String
    private let gradientLayer = CAGradientLayer()
    
    private var playersListener: ListenerRegistration?
    private var rolesListener: ListenerRegistration?
    
    private var players: [RoomManager.Player] = []
    
    private let gridContainer = UIStackView()
    private let startButton = UIButton(type: .system)
    
    // MARK: - Init
    init(roomCode: String) {
        self.roomCode = roomCode
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    
    // MARK: - UI Components
    private let headerLabel: UILabel = {
        let l = UILabel()
        l.text = "Players Joined"
        l.textColor = .white
        l.font = UIFont(name: "WinniePERSONALUSE", size: 36)
        l.textAlignment = .center
        return l
    }()
    
    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "Mafia")
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .white
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let codeLabel: UILabel = {
        let l = UILabel()
        l.textColor = .white
        l.font = UIFont(name: "WinniePERSONALUSE", size: 22)
        l.textAlignment = .center
        l.text = ""
        return l
    }()
    
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGradient()
        setupUI()
        layoutUI()
        addFigmaBackButton()
        
        codeLabel.text = "Room Code: \(roomCode)"
        
        observePlayers()
        observeRoles()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds
    }
    
    deinit {
        playersListener?.remove()
        rolesListener?.remove()
    }
    
    
    // MARK: - Setup
    private func setupGradient() {
        gradientLayer.colors = [
            UIColor(red: 1.0, green: 0.5, blue: 0.3, alpha: 1.0).cgColor,
            UIColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 1.0).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        view.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        
        gridContainer.axis = .vertical
        gridContainer.spacing = 18
        gridContainer.alignment = .center
        gridContainer.translatesAutoresizingMaskIntoConstraints = false
        
        startButton.setTitle("Start Game", for: .normal)
        startButton.backgroundColor = UIColor(red: 21/255, green: 174/255, blue: 21/255, alpha: 1.0)
        startButton.setTitleColor(.white, for: .normal)
        startButton.titleLabel?.font = UIFont(name: "WinniePERSONALUSE", size: 26)
        startButton.layer.cornerRadius = 16
        startButton.layer.shadowColor = UIColor.black.cgColor
        startButton.layer.shadowOpacity = 0.25
        startButton.layer.shadowRadius = 4
        startButton.layer.shadowOffset = CGSize(width: 2, height: 2)
        startButton.translatesAutoresizingMaskIntoConstraints = false
        startButton.addTarget(self, action: #selector(startGameTapped), for: .touchUpInside)
    }
    
    
    private func layoutUI() {
        view.addSubview(iconImageView)
        view.addSubview(headerLabel)
        view.addSubview(codeLabel)
        view.addSubview(gridContainer)
        view.addSubview(startButton)
        
        NSLayoutConstraint.activate([
            iconImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            iconImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            iconImageView.heightAnchor.constraint(equalToConstant: 100),
            iconImageView.widthAnchor.constraint(equalToConstant: 100),
            
            headerLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 20),
            headerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            codeLabel.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 8),
            codeLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            gridContainer.topAnchor.constraint(equalTo: codeLabel.bottomAnchor, constant: 20),
            gridContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            gridContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            gridContainer.bottomAnchor.constraint(lessThanOrEqualTo: startButton.topAnchor, constant: -40),
            gridContainer.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            startButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            startButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            startButton.widthAnchor.constraint(equalToConstant: 220),
            startButton.heightAnchor.constraint(equalToConstant:55)
        ])
    }
    
    
    // MARK: - Firestore Realtime Updates
    private func observePlayers() {
        playersListener = RoomManager.shared.observePlayers(inRoom: roomCode) { [weak self] players in
            guard let self = self else { return }
            self.players = players
            DispatchQueue.main.async {
                self.updatePlayerGrid()
            }
        }
    }
    
    private func observeRoles() {
        rolesListener = Firestore.firestore()
            .collection("rooms")
            .document(roomCode)
            .addSnapshotListener { snap, _ in
                
                guard let data = snap?.data(),
                      let roles = data["roles"] as? [String: String] else { return }

                RoomManager.shared.cachedRoles = roles

                if let myRole = roles[RoomManager.shared.currentUserID] {
                    self.moveToHaptics(myRole)
                }
            }
    }

    
    // MARK: - Assign Roles (HOST ONLY)
    @objc private func startGameTapped() {

        guard let host = players.first(where: { $0.isHost }) else {
            print("NO HOST FOUND")
            return
        }

        print("Host is:", host.id)
        print("My ID is:", RoomManager.shared.currentUserID)

        if host.id != RoomManager.shared.currentUserID {
            print("❌ You are not the host. Cannot start game.")
            return
        }

        assignRoles()
    }


    private func assignRoles() {
        guard players.count >= 2 else { return }

        let imposter = players.randomElement()!
        var roles: [String: String] = [:]

        for p in players {
            roles[p.id] = (p.id == imposter.id ? "imposter" : "crewmate")
        }

        Firestore.firestore()
            .collection("rooms")
            .document(roomCode)
            .updateData(["roles": roles])
    }


    
    private func assignRolesAndStartGame() {
        guard players.count >= 2 else { return }
        
        let imposter = players.randomElement()!
        
        var roleDict: [String: String] = [:]
        
        for p in players {
            roleDict[p.id] = (p.id == imposter.id) ? "imposter" : "crewmate"
        }
        
        Firestore.firestore()
            .collection("rooms")
            .document(roomCode)
            .setData(["roles": roleDict], merge: true) { error in
                
                if let error = error {
                    print("🔥 FIRESTORE ERROR:", error.localizedDescription)
                } else {
                    print("🔥 ROLES SAVED SUCCESSFULLY:", roleDict)
                }
            }

    }
    
    
    // MARK: - Navigation
    private func moveToHaptics(_ role: String) {
        let vc = HapticsRoomViewController()
        vc.role = (role == "imposter" ? .imposter : .crewmate)
        navigationController?.pushViewController(vc, animated: true)
    }

    
    
    // MARK: - Grid Logic
    private func layoutSettings(for count: Int) -> (columns: Int, size: CGFloat) {
        switch count {
        case 1...2: return (1, 150)
        case 3...4: return (2, 130)
        case 5...6: return (3, 110)
        default: return (4, 95)
        }
    }
    
    
    private func updatePlayerGrid() {
        gridContainer.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        let (columns, tileSize) = layoutSettings(for: players.count)
        
        var row = UIStackView()
        row.axis = .horizontal
        row.spacing = 20
        row.distribution = .fillEqually
        row.alignment = .center
        
        for (i, p) in players.enumerated() {
            let card = makePlayerCard(name: p.name, tileSize: tileSize)
            row.addArrangedSubview(card)
            
            if (i + 1) % columns == 0 {
                gridContainer.addArrangedSubview(row)
                row = UIStackView()
                row.axis = .horizontal
                row.spacing = 20
                row.distribution = .fillEqually
                row.alignment = .center
            }
        }
        
        if !row.arrangedSubviews.isEmpty {
            gridContainer.addArrangedSubview(row)
        }
    }
    
    
    private func makePlayerCard(name: String, tileSize: CGFloat) -> UIView {
        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.widthAnchor.constraint(equalToConstant: tileSize).isActive = true
        card.heightAnchor.constraint(equalToConstant: tileSize).isActive = true
        
        card.layer.cornerRadius = 20
        card.layer.borderWidth = 2
        card.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        card.backgroundColor = UIColor(red: 0.9, green: 0.3, blue: 0.2, alpha: 0.8)
        
        let icon = UIImageView(image: UIImage(named: "playerIcon"))
        icon.contentMode = .scaleAspectFit
        icon.tintColor = .white
        icon.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.text = name
        label.font = UIFont(name: "WinniePERSONALUSE", size: 20)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        card.addSubview(icon)
        card.addSubview(label)
        
        NSLayoutConstraint.activate([
            icon.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            icon.topAnchor.constraint(equalTo: card.topAnchor, constant: 6),
            icon.heightAnchor.constraint(equalToConstant: tileSize * 0.45),
            icon.widthAnchor.constraint(equalToConstant: tileSize * 0.45),
            
            label.topAnchor.constraint(equalTo: icon.bottomAnchor, constant: 4),
            label.centerXAnchor.constraint(equalTo: card.centerXAnchor)
        ])
        
        return card
    }
}
