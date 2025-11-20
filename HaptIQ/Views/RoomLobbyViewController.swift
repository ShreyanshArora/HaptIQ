import UIKit
import FirebaseFirestore

final class RoomLobbyViewController: UIViewController {

    private let roomCode: String
    private let gradientLayer = CAGradientLayer()

    private var playersListener: ListenerRegistration?
    private var stateListener: ListenerRegistration?
    private var players: [RoomManager.Player] = []

    // UI (minimal)
    private let headerLabel: UILabel = {
        let l = UILabel()
        l.text = "Players Joined"
        l.textColor = .white
        l.font = UIFont(name: "Aclonica-Regular", size: 36)
        l.textAlignment = .center
        return l
    }()

    private let codeLabel: UILabel = {
        let l = UILabel()
        l.textColor = .white
        l.font = UIFont(name: "Aclonica-Regular", size: 22)
        l.textAlignment = .center
        l.text = ""
        return l
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
        codeLabel.text = "Room Code: \(roomCode)"
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
        // simple layout:
        view.addSubview(headerLabel)
        view.addSubview(codeLabel)
        view.addSubview(startButton)

        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        codeLabel.translatesAutoresizingMaskIntoConstraints = false
        startButton.translatesAutoresizingMaskIntoConstraints = false

        startButton.setTitle("Start Game", for: .normal)
        startButton.backgroundColor = UIColor(red: 21/255, green: 174/255, blue: 21/255, alpha: 1)
        startButton.setTitleColor(.white, for: .normal)
        startButton.layer.cornerRadius = 12
        startButton.addTarget(self, action: #selector(startGameTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            headerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            codeLabel.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 8),
            codeLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            startButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            startButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            startButton.widthAnchor.constraint(equalToConstant: 220),
            startButton.heightAnchor.constraint(equalToConstant: 55)
        ])
    }

    private func observePlayers() {
        playersListener = RoomManager.shared.observePlayers(inRoom: roomCode) { [weak self] players in
            guard let self = self else { return }
            self.players = players
            // TODO: update UI grid (omitted for brevity). This ensures players are fresh.
        }
    }

    private func observeState() {
        stateListener = RoomManager.shared.observeState(inRoom: roomCode) { [weak self] round, rumble in
            guard let self = self else { return }
            // update cached roles if rooms doc contains them
            Firestore.firestore().collection("rooms").document(self.roomCode).getDocument { snap, _ in
                if let data = snap?.data(), let roles = data["roles"] as? [String: String] {
                    RoomManager.shared.cachedRoles = roles
                    // If my role is assigned, navigate to haptics screen
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
        // ensure current user is host
        guard let host = players.first(where: { $0.isHost }) else {
            print("No host in players list")
            return
        }

        if host.id != RoomManager.shared.currentUserID {
            print("NOT HOST, cannot start")
            return
        }

        // host assigns roles & writes rumbleCount to state
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
