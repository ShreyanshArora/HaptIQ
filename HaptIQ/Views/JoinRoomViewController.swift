import UIKit

final class JoinRoomViewController: UIViewController {
    
    private let gradientLayer = CAGradientLayer()
    
    // MARK: - UI Components
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Enter room code to Join the room"
        label.textColor = .white
        label.font = UIFont(name: "WinniePERSONALUSE", size: 28)
        label.textAlignment = .center
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let card: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0.95, green: 0.4, blue: 0.2, alpha: 1.0)
        view.layer.cornerRadius = 25
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.25
        view.layer.shadowRadius = 8
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let cardTitle: UILabel = {
        let label = UILabel()
        label.text = "Join ROOM"
        label.textColor = .white
        label.font = UIFont(name: "WinniePERSONALUSE", size: 34)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let codeField: UITextField = {
        let field = UITextField()
        field.placeholder = "Enter Room ID"
        field.backgroundColor = .white
        field.layer.cornerRadius = 10
        field.textAlignment = .center
        field.font = UIFont(name: "WinniePERSONALUSE", size: 18)
        field.layer.shadowColor = UIColor.black.cgColor
        field.layer.shadowOpacity = 0.2
        field.layer.shadowRadius = 3
        field.layer.shadowOffset = CGSize(width: 0, height: 2)
        field.heightAnchor.constraint(equalToConstant: 45).isActive = true
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()
    
    private let joinButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Join", for: .normal)
        button.backgroundColor = UIColor(red: 0.2, green: 0.8, blue: 0.3, alpha: 1.0)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont(name: "WinniePERSONALUSE", size: 26)
        button.layer.cornerRadius = 12
        button.heightAnchor.constraint(equalToConstant: 45).isActive = true
        button.widthAnchor.constraint(equalToConstant: 150).isActive = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let createButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Create Room", for: .normal)
        button.backgroundColor = UIColor(red: 0.9, green: 0.4, blue: 0.1, alpha: 1.0)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont(name: "WinniePERSONALUSE", size: 22)
        button.layer.cornerRadius = 10
        button.heightAnchor.constraint(equalToConstant: 40).isActive = true
        button.widthAnchor.constraint(equalToConstant: 180).isActive = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let nearbyLabel: UILabel = {
        let label = UILabel()
        label.text = "Nearby Players"
        label.font = UIFont(name: "WinniePERSONALUSE", size: 22)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let emojiRow: UIStackView = {
        let emojis = ["😆", "🙂", "😁", "😏"].map { emoji -> UILabel in
            let lbl = UILabel()
            lbl.text = emoji
            lbl.font = UIFont.systemFont(ofSize: 38)
            lbl.textAlignment = .center
            lbl.backgroundColor = .white
            lbl.layer.cornerRadius = 35
            lbl.layer.masksToBounds = true
            lbl.layer.shadowColor = UIColor.black.cgColor
            lbl.layer.shadowOpacity = 0.25
            lbl.layer.shadowRadius = 4
            lbl.layer.shadowOffset = CGSize(width: 0, height: 2)
            lbl.widthAnchor.constraint(equalToConstant: 70).isActive = true
            lbl.heightAnchor.constraint(equalToConstant: 70).isActive = true
            return lbl
        }
        let stack = UIStackView(arrangedSubviews: emojis)
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .equalSpacing
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGradientBackground()
        setupUI()
        layoutUI()
        setupActions()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds
    }
    
    // MARK: - Gradient
    private func setupGradientBackground() {
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
    
    // MARK: - Layout Setup
    private func setupUI() {
        view.addSubview(titleLabel)
        view.addSubview(card)
        view.addSubview(nearbyLabel)
        view.addSubview(emojiRow)
        view.addSubview(statusLabel)
        
        let cardStack = UIStackView(arrangedSubviews: [cardTitle, codeField, joinButton, createButton])
        cardStack.axis = .vertical
        cardStack.alignment = .center
        cardStack.spacing = 15
        cardStack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(cardStack)
        
        NSLayoutConstraint.activate([
            // Title
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Card
            card.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30),
            card.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            card.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            card.heightAnchor.constraint(equalToConstant: 500),
            
            // CardStack inside card
            cardStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            cardStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            cardStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 40),
            
            // Nearby Label
            nearbyLabel.topAnchor.constraint(equalTo: card.bottomAnchor, constant: 25),
            nearbyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Emoji Row
            emojiRow.topAnchor.constraint(equalTo: nearbyLabel.bottomAnchor, constant: 15),
            emojiRow.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Status Label
            statusLabel.topAnchor.constraint(equalTo: emojiRow.bottomAnchor, constant: 20),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    private func layoutUI() {}
    
    private func setupActions() {
        joinButton.addTarget(self, action: #selector(joinTapped), for: .touchUpInside)
        createButton.addTarget(self, action: #selector(createTapped), for: .touchUpInside)
    }
    
    // MARK: - Actions
    @objc private func createTapped() {
        RoomManager.shared.createRoom { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let code):
                    let vc = CreateRoomViewController(roomCode: code)
                    self?.navigationController?.pushViewController(vc, animated: true)
                case .failure(let err):
                    self?.statusLabel.text = err.localizedDescription
                }
            }
        }
    }

    @objc private func joinTapped() {
        let code = codeField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !code.isEmpty else {
            statusLabel.text = "⚠️ Please enter a room code first."
            return
        }
        RoomManager.shared.joinRoom(withCode: code) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    let vc = RoomLobbyViewController(roomCode: code)
                    self?.navigationController?.pushViewController(vc, animated: true)
                case .failure(let err):
                    self?.statusLabel.text = err.localizedDescription
                }
            }
        }
    }
}

