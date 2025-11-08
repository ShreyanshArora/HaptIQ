import UIKit
extension UIView {
    func applyGradient(
        colors: [UIColor],
        startPoint: CGPoint = CGPoint(x: 0.5, y: 0.0),
        endPoint: CGPoint = CGPoint(x: 0.5, y: 1.0),
        cornerRadius: CGFloat = 0
    ) {
        // Remove existing gradient (avoid stacking multiple)
        layer.sublayers?.removeAll(where: { $0 is CAGradientLayer })

        let gradient = CAGradientLayer()
        gradient.frame = bounds
        gradient.colors = colors.map { $0.cgColor }
        gradient.startPoint = startPoint
        gradient.endPoint = endPoint
        gradient.cornerRadius = cornerRadius
        layer.insertSublayer(gradient, at: 0)
    }
}

 class JoinRoomViewController: UIViewController {
    
    
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
        field.layer.shadowOffset = CGSize(width: 3, height: 2)
        field.heightAnchor.constraint(equalToConstant: 45).isActive = true
        field.widthAnchor.constraint(equalToConstant: 220).isActive = true
        
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()
    
    private let joinButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Join", for: .normal)
        button.backgroundColor = UIColor(red: 21/255, green: 174/255, blue: 21/255, alpha: 1.0)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont(name: "WinniePERSONALUSE", size: 30)
        button.layer.cornerRadius = 20
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.2
        button.layer.shadowRadius = 3
        button.layer.shadowOffset = CGSize(width: 3, height: 2)
        button.heightAnchor.constraint(equalToConstant: 48).isActive = true
        button.widthAnchor.constraint(equalToConstant: 185).isActive = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let createButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Create Room", for: .normal)
        button.backgroundColor = UIColor(red: 0.9, green: 0.4, blue: 0.1, alpha: 1.0)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont(name: "WinniePERSONALUSE", size: 16)
        button.layer.cornerRadius = 15
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.2
        button.layer.shadowRadius = 3
        button.layer.shadowOffset = CGSize(width: 3, height: 2)
        button.heightAnchor.constraint(equalToConstant: 32).isActive = true
        button.widthAnchor.constraint(equalToConstant: 141).isActive = true
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
     // MARK: - Layout
     private func setupUI() {
         view.addSubview(titleLabel)
         view.addSubview(card)

         // Stack inside the card (includes all items)
         let cardStack = UIStackView(arrangedSubviews: [
             cardTitle,
             codeField,
             joinButton,
             createButton,
             nearbyLabel,
             emojiRow
         ])
         cardStack.axis = .vertical
         cardStack.spacing = 16
         cardStack.alignment = .center
         cardStack.translatesAutoresizingMaskIntoConstraints = false
         card.addSubview(cardStack)

         // ✅ Constraints
         NSLayoutConstraint.activate([
             // Title Label
             titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 80),
             titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

             // Card
             card.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30),
             card.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
             card.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
             card.heightAnchor.constraint(equalToConstant: 500),

             // Stack inside card
             cardStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
             cardStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
             cardStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 40),
             cardStack.bottomAnchor.constraint(lessThanOrEqualTo: card.bottomAnchor, constant: -20)
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

