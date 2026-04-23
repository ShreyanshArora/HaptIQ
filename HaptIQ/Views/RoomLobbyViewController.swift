import UIKit
import FirebaseFirestore

// MARK: - Padded Label for Room Code
class PaddedLabel: UILabel {
    var padding = UIEdgeInsets(top: 8, left: 20, bottom: 8, right: 20)
    
    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: padding))
    }
    
    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + padding.left + padding.right,
                      height: size.height + padding.top + padding.bottom)
    }
}

// MARK: - Player Cell
class PlayerCell: UICollectionViewCell {
    
    private let containerView: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.layer.borderWidth = 1
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
            
            nameLabel.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            nameLabel.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor),
        ])
    }
    
    func configure(with player: RoomManager.Player) {
        nameLabel.text = player.name
        if let avatarImage = player.avatarImage {
            avatarImageView.image = UIImage(named: avatarImage)
        } else {
            avatarImageView.image = UIImage(named: "char1")
        }
    }
}

// MARK: - Room Lobby View Controller
final class RoomLobbyViewController: UIViewController {

    private let roomCode: String
    private let gradientLayer = CAGradientLayer()

    private var playersListener: ListenerRegistration?
    private var stateListener: ListenerRegistration?
    private var players: [RoomManager.Player] = []
    
    // ✅ CRITICAL: Flag to prevent duplicate navigation
    private var hasLeftLobby = false

    // UI Components
    private let roomTitleLabel: UILabel = {
        let l = UILabel()
        l.text = "Room Code"
        l.textColor = .white
        l.font = UIFont(name: "Aclonica-Regular", size: 24)
        l.textAlignment = .center
        return l
    }()

    private let codeContainerView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 20
        v.layer.borderWidth = 2
        v.layer.borderColor = UIColor.white.cgColor
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let codeLabel: UILabel = {
        let l = UILabel()
        l.textColor = .white
        l.font = UIFont(name: "Aclonica-Regular", size: 28)
        l.textAlignment = .center
        l.text = ""
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let readyLabel: UILabel = {
        let l = UILabel()
        l.text = "Everyone is ready!"
        l.textColor = .white
        l.font = UIFont(name: "Aclonica-Regular", size: 16)
        l.textAlignment = .center
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

    private let startButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Start", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont(name: "Aclonica-Regular", size: 24)
        button.layer.cornerRadius = 30
        button.layer.borderWidth = 3
        button.layer.borderColor = UIColor.white.cgColor
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    init(roomCode: String) {
        self.roomCode = roomCode
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCollectionView()
        codeLabel.text = roomCode
        observePlayers()
        observeState()
        
        print("📍 RoomLobbyViewController loaded - Room: \(roomCode)")
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds
        applyGradients()
    }

    deinit {
        removeAllListeners()
        print("🗑️ RoomLobbyViewController deallocated")
    }
    
    // ✅ Centralized listener cleanup
    private func removeAllListeners() {
        playersListener?.remove()
        playersListener = nil
        stateListener?.remove()
        stateListener = nil
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
            UIColor(red: 5/255, green: 10/255, blue: 35/255, alpha: 1).cgColor,
            UIColor(red: 20/255, green: 45/255, blue: 120/255, alpha: 1).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        view.layer.insertSublayer(gradientLayer, at: 1)
        
        view.addSubview(roomTitleLabel)
        view.addSubview(codeContainerView)
        codeContainerView.addSubview(codeLabel)
        view.addSubview(readyLabel)
        view.addSubview(playersCollectionView)
        view.addSubview(startButton)
        
        roomTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        readyLabel.translatesAutoresizingMaskIntoConstraints = false

        startButton.addTarget(self, action: #selector(startGameTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            roomTitleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            roomTitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            codeContainerView.topAnchor.constraint(equalTo: roomTitleLabel.bottomAnchor, constant: 8),
            codeContainerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            codeContainerView.heightAnchor.constraint(equalToConstant: 50),
            
            codeLabel.topAnchor.constraint(equalTo: codeContainerView.topAnchor, constant: 8),
            codeLabel.bottomAnchor.constraint(equalTo: codeContainerView.bottomAnchor, constant: -8),
            codeLabel.leadingAnchor.constraint(equalTo: codeContainerView.leadingAnchor, constant: 20),
            codeLabel.trailingAnchor.constraint(equalTo: codeContainerView.trailingAnchor, constant: -20),
            
            readyLabel.topAnchor.constraint(equalTo: codeContainerView.bottomAnchor, constant: 15),
            readyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            playersCollectionView.topAnchor.constraint(equalTo: readyLabel.bottomAnchor, constant: 30),
            playersCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            playersCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            playersCollectionView.bottomAnchor.constraint(equalTo: startButton.topAnchor, constant: -30),

            startButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            startButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            startButton.widthAnchor.constraint(equalToConstant: 280),
            startButton.heightAnchor.constraint(equalToConstant: 60),
        ])
    }
    
    private func applyGradients() {
        codeContainerView.applyGradient(
            colors: [
                UIColor(red: 5/255, green: 10/255, blue: 35/255, alpha: 1),
                UIColor(red: 20/255, green: 45/255, blue: 120/255, alpha: 1)
            ],
            startPoint: CGPoint(x: 0, y: 0.5),
            endPoint: CGPoint(x: 1, y: 0.5),
            cornerRadius: 20
        )
        
        startButton.applyGradient(
            colors: [
                UIColor(red: 5/255, green: 10/255, blue: 35/255, alpha: 1),
                UIColor(red: 20/255, green: 45/255, blue: 120/255, alpha: 1)
            ],
            startPoint: CGPoint(x: 0, y: 0.5),
            endPoint: CGPoint(x: 1, y: 0.5),
            cornerRadius: 30
        )
    }

    private func setupCollectionView() {
        playersCollectionView.delegate = self
        playersCollectionView.dataSource = self
        playersCollectionView.register(PlayerCell.self, forCellWithReuseIdentifier: "PlayerCell")
    }

    private func observePlayers() {
        playersListener = RoomManager.shared.observePlayers(inRoom: roomCode) { [weak self] players in
            guard let self = self, !self.hasLeftLobby else { return }
            
            self.players = players
            
            if let host = players.first(where: { $0.isHost }) {
                RoomManager.shared.hostID = host.id
            }
            
            DispatchQueue.main.async {
                self.playersCollectionView.reloadData()
                self.updateStartButtonVisibility()
            }
        }
    }
    
    private func updateStartButtonVisibility() {
        let isHost = players.contains { $0.id == RoomManager.shared.currentUserID && $0.isHost }
        startButton.isHidden = !isHost
    }

    // ✅ FIXED: Only trigger once
    private func observeState() {
        stateListener = RoomManager.shared.observeState(inRoom: roomCode) { [weak self] (round: Int, rumble: Int) in
            guard let self = self else { return }
            
            // ✅ CRITICAL: Check flag first
            guard !self.hasLeftLobby else {
                print("⚠️ hasLeftLobby=true, ignoring state update")
                return
            }
            
            print("📡 State changed - Round: \(round), Rumble: \(rumble)")
            
            // ✅ Set flag IMMEDIATELY before any async work
            self.hasLeftLobby = true
            
            // ✅ Remove listeners IMMEDIATELY
            self.removeAllListeners()
            
            Firestore.firestore().collection("rooms").document(self.roomCode).getDocument { [weak self] snap, _ in
                guard let self = self else { return }
                
                if let data = snap?.data(), let roles = data["roles"] as? [String: String] {
                    RoomManager.shared.cachedRoles = roles
                    
                    if let myRole = roles[RoomManager.shared.currentUserID] {
                        print("🎭 My role: \(myRole)")
                        
                        DispatchQueue.main.async {
                            self.moveToHaptics(roleString: myRole, rumbleCount: rumble)
                        }
                    }
                }
            }
        }
    }

    @objc private func startGameTapped() {
        guard !hasLeftLobby else { return }
        
        // ✅ Check minimum player count
        if players.count < 2 {
            let alert = UIAlertController(
                title: "Not Enough Players!",
                message: "At least 2 players are needed to start the game. Share the room code and wait for others to join!",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        guard let host = players.first(where: { $0.isHost }) else {
            print("❌ No host in players list")
            return
        }

        if host.id != RoomManager.shared.currentUserID {
            print("❌ NOT HOST, cannot start")
            return
        }
        
        startButton.isEnabled = false
        startButton.alpha = 0.6

        print("👑 Host starting game...")
        
        RoomManager.shared.hostAssignRolesAndStartRound(roomCode: roomCode, players: players) { [weak self] err in
            DispatchQueue.main.async {
                if let err = err {
                    print("❌ Failed to start round: \(err.localizedDescription)")
                    self?.startButton.isEnabled = true
                    self?.startButton.alpha = 1.0
                } else {
                    print("✅ Host started round successfully")
                }
            }
        }
    }

    private func moveToHaptics(roleString: String, rumbleCount: Int) {
        // ✅ Check if already navigated
        if navigationController?.viewControllers.contains(where: { $0 is HapticsRoomViewController }) == true {
            print("⚠️ HapticsRoomViewController already in stack")
            return
        }

        let role: HapticsRoomViewController.PlayerRole =
            (roleString == "imposter") ? .imposter : .crewmate

        print("🎮 Moving to HapticsRoom - Role: \(roleString), Rumbles: \(rumbleCount)")

        let vc = HapticsRoomViewController(
            roomCode: roomCode,
            players: players,
            rumbleCount: rumbleCount,
            role: role
        )
        vc.currentRound = 1

        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - CollectionView DataSource & Delegate
extension RoomLobbyViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return players.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PlayerCell", for: indexPath) as! PlayerCell
        let player = players[indexPath.item]
        cell.configure(with: player)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let totalSpacing: CGFloat = 30
        let width = (collectionView.bounds.width - totalSpacing) / 3
        let height = width + 30
        return CGSize(width: width, height: height)
    }
}
