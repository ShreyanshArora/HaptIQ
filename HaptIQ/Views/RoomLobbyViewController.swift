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
        
        // Set avatar image
        if let avatarImage = player.avatarImage {
            avatarImageView.image = UIImage(named: avatarImage)
        } else {
            avatarImageView.image = UIImage(named: "char1")  // default avatar
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
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds
        
        // Apply gradients after layout is complete
        applyGradients()
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
        backgroundImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(backgroundImageView)
        view.sendSubviewToBack(backgroundImageView)
        
        // Add gradient overlay
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
        // Apply gradient to code container
        codeContainerView.applyGradient(
            colors: [
                UIColor(red: 5/255, green: 10/255, blue: 35/255, alpha: 1),
                UIColor(red: 20/255, green: 45/255, blue: 120/255, alpha: 1)
            ],
            startPoint: CGPoint(x: 0, y: 0.5),
            endPoint: CGPoint(x: 1, y: 0.5),
            cornerRadius: 20
        )
        
        // Apply gradient to startButton
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
            guard let self = self else { return }
            self.players = players
            DispatchQueue.main.async {
                self.playersCollectionView.reloadData()
                self.updateStartButtonVisibility()
            }
        }
    }
    
    private func updateStartButtonVisibility() {
        // Only show start button if current user is the host
        let isHost = players.contains { $0.id == RoomManager.shared.currentUserID && $0.isHost }
        startButton.isHidden = !isHost
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
    
    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func settingsTapped() {
        // Handle settings action
        print("Settings tapped")
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
        // 3 columns with spacing
        let totalSpacing: CGFloat = 30 // 2 gaps of 15 between 3 columns
        let width = (collectionView.bounds.width - totalSpacing) / 3
        let height = width + 30 // Square avatar + space for name
        return CGSize(width: width, height: height)
    }
}
