import UIKit
import FirebaseFirestore

class EnterNameViewController: UIViewController {
    
    private let roomCode: String
    private let isCreator: Bool
    private let gradientLayer = CAGradientLayer()
    
    init(roomCode: String, isCreator: Bool) {
        self.roomCode = roomCode
        self.isCreator = isCreator
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    // MARK: - UI Components
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Enter Your Name"
        l.font = UIFont(name: "WinniePERSONALUSE", size: 32)
        l.textColor = .white
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let card: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 25
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.25
        v.layer.shadowRadius = 8
        v.layer.shadowOffset = CGSize(width: 0, height: 4)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let nameField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Your name"
        tf.font = UIFont(name: "WinniePERSONALUSE", size: 22)
        tf.backgroundColor = .white
        tf.layer.cornerRadius = 12
        tf.textAlignment = .center
        tf.textColor = .black
        tf.heightAnchor.constraint(equalToConstant: 48).isActive = true
        tf.widthAnchor.constraint(equalToConstant: 220).isActive = true
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    private let moveButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("MOVE TO LOBBY", for: .normal)
        b.backgroundColor = UIColor(red: 21/255, green: 174/255, blue: 21/255, alpha: 1.0)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = UIFont(name: "WinniePERSONALUSE", size: 22)
        b.layer.cornerRadius = 18
        b.layer.shadowColor = UIColor.black.cgColor
        b.layer.shadowOpacity = 0.25
        b.layer.shadowRadius = 4
        b.layer.shadowOffset = CGSize(width: 2, height: 2)
        b.heightAnchor.constraint(equalToConstant: 48).isActive = true
        b.widthAnchor.constraint(equalToConstant: 190).isActive = true
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()
    
    private let hintLabel: UILabel = {
        let l = UILabel()
        l.text = "This name will be visible to your friends"
        l.textColor = UIColor.white.withAlphaComponent(0.9)
        l.font = UIFont(name: "WinniePERSONALUSE", size: 20)
        l.textAlignment = .center
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGradient()
        setupUI()
        layoutUI()
        addFigmaBackButton()
        setupActions()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds
        card.applyGradient(
            colors: [
                UIColor(red: 232/255, green: 110/255, blue: 40/255, alpha: 1),
                UIColor(red: 242/255, green: 61/255, blue: 44/255, alpha: 1),
                UIColor(red: 255/255, green: 0/255, blue: 4/255, alpha: 1)
            ],
            startPoint: CGPoint(x: 0, y: 0),
            endPoint: CGPoint(x: 1, y: 1),
            cornerRadius: 25
        )
    }
    
    // MARK: - Setup
    private func setupGradient() {
        gradientLayer.colors = [
            UIColor(red: 0xE8/255, green: 0x6E/255, blue: 0x28/255, alpha: 1.0).cgColor,
            UIColor(red: 0xF2/255, green: 0x3D/255, blue: 0x2C/255, alpha: 1.0).cgColor,
            UIColor(red: 0xFF/255, green: 0x00/255, blue: 0x04/255, alpha: 1.0).cgColor
        ]
        gradientLayer.locations = [0.0, 0.5, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        view.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        view.addSubview(titleLabel)
        view.addSubview(card)
        view.addSubview(hintLabel)
    }
    
    private func layoutUI() {
        let stack = UIStackView(arrangedSubviews: [nameField, moveButton])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 25
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)
        
        let container = UIStackView(arrangedSubviews: [titleLabel, card, hintLabel])
        container.axis = .vertical
        container.alignment = .center
        container.spacing = 40
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)
        
        NSLayoutConstraint.activate([
            container.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            
            card.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            card.heightAnchor.constraint(equalToConstant: 240),
            
            stack.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            
            titleLabel.topAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
        ])
    }
    
    private func setupActions() {
        moveButton.addTarget(self, action: #selector(moveTapped), for: .touchUpInside)
    }
    
    // MARK: - Actions
    @objc private func moveTapped() {
        guard let name = nameField.text, !name.isEmpty else { return }

        if isCreator {
            let hostID = RoomManager.shared.currentUserID

            Firestore.firestore()
                .collection("rooms")
                .document(roomCode)
                .collection("players")
                .document(hostID)
                .setData([
                    "name": name,
                    "isHost": true
                ], merge: true) { _ in
                    self.go()
                }

            return
        }


        // JOINER: use NEW ID & update currentUserID
        let uid = UUID().uuidString
        RoomManager.shared.currentUserID = uid

        RoomManager.shared.addPlayer(
            id: uid,
            name: name,
            isHost: false,
            to: roomCode
        ) { _ in
            self.go()
        }
    }

    
    private func go() {
        DispatchQueue.main.async {
            let vc = RoomLobbyViewController(roomCode: self.roomCode)
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
}
