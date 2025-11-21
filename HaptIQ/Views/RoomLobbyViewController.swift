import UIKit
import FirebaseFirestore

// MARK: - Player Cell
class PlayerCell: UICollectionViewCell {
    
    private let containerView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 100/255, green: 180/255, blue: 255/255, alpha: 0.3)
        v.layer.cornerRadius = 15
        v.layer.borderWidth = 2
        v.layer.borderColor = UIColor.white.cgColor
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let nameLabel: UILabel = {
        let l = UILabel()
        l.textColor = .white
        l.font = UIFont(name: "Aclonica-Regular", size: 16)
        l.textAlignment = .center
        l.numberOfLines = 2
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let hostBadge: UILabel = {
        let l = UILabel()
        l.text = "HOST"
        l.textColor = .white
        l.font = UIFont.systemFont(ofSize: 10, weight: .bold)
        l.backgroundColor = UIColor(red: 255/255, green: 215/255, blue: 0/255, alpha: 1)
        l.textAlignment = .center
        l.layer.cornerRadius = 8
        l.clipsToBounds = true
        l.translatesAutoresizingMaskIntoConstraints = false
        l.isHidden = true
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
        containerView.addSubview(hostBadge)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            avatarImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 15),
            avatarImageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 80),
            avatarImageView.heightAnchor.constraint(equalToConstant: 80),
            
            nameLabel.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 10),
            nameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            nameLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            
            hostBadge.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            hostBadge.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            hostBadge.widthAnchor.constraint(equalToConstant: 50),
            hostBadge.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    func configure(with player: RoomManager.Player) {
        nameLabel.text = player.name
        
        // Set avatar image
        if let avatarImage = player.avatarImage {
            avatarImageView.image = UIImage(named: avatarImage)
        } else {
            avatarImageView.image = UIImage(named: "char1")  // default avatar
        }
        
        // Show host badge if player is host
        hostBadge.isHidden = !player.isHost
    }
}

// MARK: - Room Lobby View Controller
final class RoomLobbyViewController: UIViewController {

    private let roomCode: String
    private let gradientLayer = CAGradientLayer()

    private var playersListener: ListenerRegistration?
    private var stateListener: ListenerRegistration?
    private var players: [RoomManager.Player] = []

    // UI Components

    private let roomTitleLabel: UILabel = {
        let l = UILabel()
        l.text = "My room"
        l.textColor = .white
        l.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        l.textAlignment = .center
        return l
    }()

    private let codeLabel: UILabel = {
        let l = UILabel()
        l.textColor = .white
        l.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        l.textAlignment = .center
        l.text = ""
        return l
    }()

    private let readyLabel: UILabel = {
        let l = UILabel()
        l.text = "Everyone is ready!"
        l.textColor = .white
        l.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        l.textAlignment = .center
        return l
    }()

    private let playersCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 15
        layout.minimumInteritemSpacing = 10
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()

    private let startButton = UIButton(type: .system)

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
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds
    }

    deinit {
        playersListener?.remove()
        stateListener?.remove()
    }

    private func setupUI() {
        view.backgroundColor = .black
        
        // Add background image
        let backgroundImageView = UIImageView(frame: view.bounds)
        backgroundImageView.image = UIImage(named: "spiralBG")
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.alpha = 0.8
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
        
        view.addSubview(roomTitleLabel)
        view.addSubview(codeLabel)
        view.addSubview(readyLabel)
        view.addSubview(playersCollectionView)
        view.addSubview(startButton)

    
        roomTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        codeLabel.translatesAutoresizingMaskIntoConstraints = false
        readyLabel.translatesAutoresizingMaskIntoConstraints = false
        startButton.translatesAutoresizingMaskIntoConstraints = false

        startButton.setTitle("Start", for: .normal)
        startButton.backgroundColor = UIColor(red: 21/255, green: 174/255, blue: 21/255, alpha: 1)
        startButton.setTitleColor(.white, for: .normal)
        startButton.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        startButton.layer.cornerRadius = 25
        startButton.addTarget(self, action: #selector(startGameTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([

            roomTitleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            roomTitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            codeLabel.topAnchor.constraint(equalTo: roomTitleLabel.bottomAnchor, constant: 5),
            codeLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            readyLabel.topAnchor.constraint(equalTo: codeLabel.bottomAnchor, constant: 15),
            readyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            playersCollectionView.topAnchor.constraint(equalTo: readyLabel.bottomAnchor, constant: 20),
            playersCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            playersCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            playersCollectionView.bottomAnchor.constraint(equalTo: startButton.topAnchor, constant: -20),

            startButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            startButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            startButton.widthAnchor.constraint(equalToConstant: 150),
            startButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    private func setupCollectionView() {
        playersCollectionView.delegate = self
        playersCollectionView.dataSource = self
        playersCollectionView.register(PlayerCell.self, forCellWithReuseIdentifier: "PlayerCell")
    }

    private func observePlayers() {
        playersListener = RoomManager.shared.observePlayers(inRoom: roomCode) { [weak self] players in
            guard let self = self else { return }
            self.players = players
            DispatchQueue.main.async {
                self.playersCollectionView.reloadData()
            }
        }
    }

    private func observeState() {
        stateListener = RoomManager.shared.observeState(inRoom: roomCode) { [weak self] round, rumble in
            guard let self = self else { return }
            Firestore.firestore().collection("rooms").document(self.roomCode).getDocument { snap, _ in
                if let data = snap?.data(), let roles = data["roles"] as? [String: String] {
                    RoomManager.shared.cachedRoles = roles
                    if let myRole = roles[RoomManager.shared.currentUserID] {
                        DispatchQueue.main.async {
                            self.moveToHaptics(roleString: myRole, rumbleCount: rumble)
                        }
                    }
                }
            }
        }
    }

    @objc private func startGameTapped() {
        guard let host = players.first(where: { $0.isHost }) else {
            print("No host in players list")
            return
        }

        if host.id != RoomManager.shared.currentUserID {
            print("NOT HOST, cannot start")
            return
        }

        RoomManager.shared.hostAssignRolesAndStartRound(roomCode: roomCode, players: players) { err in
            if let err = err {
                print("Failed to start round:", err.localizedDescription)
            } else {
                print("Host started round")
            }
        }
    }

    private func moveToHaptics(roleString: String, rumbleCount: Int?) {
        if navigationController?.topViewController is HapticsRoomViewController { return }

        let role: HapticsRoomViewController.PlayerRole =
            (roleString == "imposter") ? .imposter : .crewmate

        let r = rumbleCount ?? 0

        let vc = HapticsRoomViewController(
            roomCode: roomCode,
            players: players,
            rumbleCount: r,
            role: role
        )

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
        let width = (collectionView.bounds.width - 20) / 3  // 3 columns with spacing for 7 players
        return CGSize(width: width, height: 120) // Smaller height to fit more players
    }
}
