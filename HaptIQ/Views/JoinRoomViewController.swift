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
           view.layer.shadowOffset = CGSize(width: 0, height: 3)
           view.translatesAutoresizingMaskIntoConstraints = false
           return view
       }()
       
       private let cardTitle: UILabel = {
           let label = UILabel()
           label.text = "Join ROOM"
           label.font = UIFont(name: "WinniePERSONALUSE", size: 34)
           label.textAlignment = .center
           label.textColor = .white
           label.translatesAutoresizingMaskIntoConstraints = false
           return label
       }()
       
       private let codeField: UITextField = {
           let textField = UITextField()
           textField.placeholder = "Enter Room ID"
           textField.font = UIFont(name: "WinniePERSONALUSE", size: 18)
           textField.textAlignment = .center
           textField.backgroundColor = .white
           textField.layer.cornerRadius = 10
           textField.layer.shadowColor = UIColor.black.cgColor
           textField.layer.shadowOpacity = 0.2
           textField.layer.shadowRadius = 3
           textField.translatesAutoresizingMaskIntoConstraints = false
           textField.heightAnchor.constraint(equalToConstant: 45).isActive = true
           return textField
       }()
       
       private let joinButton: UIButton = {
           let button = UIButton(type: .system)
           button.setTitle("Join", for: .normal)
           button.backgroundColor = UIColor(red: 0.2, green: 0.8, blue: 0.3, alpha: 1.0)
           button.setTitleColor(.white, for: .normal)
           button.titleLabel?.font = UIFont(name: "WinniePERSONALUSE", size: 26)
           button.layer.cornerRadius = 12
           button.translatesAutoresizingMaskIntoConstraints = false
           button.heightAnchor.constraint(equalToConstant: 45).isActive = true
           button.widthAnchor.constraint(equalToConstant: 150).isActive = true
           return button
       }()
       
       private let createButton: UIButton = {
           let button = UIButton(type: .system)
           button.setTitle("Create Room", for: .normal)
           button.backgroundColor = UIColor(red: 0.9, green: 0.4, blue: 0.1, alpha: 1.0)
           button.setTitleColor(.white, for: .normal)
           button.titleLabel?.font = UIFont(name: "WinniePERSONALUSE", size: 22)
           button.layer.cornerRadius = 10
           button.translatesAutoresizingMaskIntoConstraints = false
           button.heightAnchor.constraint(equalToConstant: 40).isActive = true
           button.widthAnchor.constraint(equalToConstant: 180).isActive = true
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
               lbl.font = UIFont.systemFont(ofSize: 40)
               lbl.textAlignment = .center
               lbl.backgroundColor = .white
               lbl.layer.cornerRadius = 35
               lbl.layer.masksToBounds = true
               lbl.layer.shadowColor = UIColor.black.cgColor
               lbl.layer.shadowOpacity = 0.25
               lbl.layer.shadowRadius = 4
               lbl.layer.shadowOffset = CGSize(width: 0, height: 2)
               lbl.translatesAutoresizingMaskIntoConstraints = false
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

    override func viewDidLoad() {
        super.viewDidLoad()
        setupGradient()
        setupUI()
        layoutUI()
        addFigmaBackButton() // root has back too (does nothing)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds
    }

    private func setupGradient() {
           let gradient = CAGradientLayer()
           gradient.frame = view.bounds
           gradient.colors = [
               UIColor(red: 0xE8/255, green: 0x6E/255, blue: 0x28/255, alpha: 1.0).cgColor,
               UIColor(red: 0xF2/255, green: 0x3D/255, blue: 0x2C/255, alpha: 1.0).cgColor,
               UIColor(red: 0xFF/255, green: 0x00/255, blue: 0x04/255, alpha: 1.0).cgColor
           ]
           gradient.locations = [0.0, 0.5, 1.0]
           gradient.startPoint = CGPoint(x: 0.5, y: 0.0)
           gradient.endPoint   = CGPoint(x: 0.5, y: 1.0)
           view.layer.insertSublayer(gradient, at: 0)
       }

    private func setupUI() {
        view.backgroundColor = .black

        card.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        card.layer.cornerRadius = 24

        cardTitle.text = "Join Room anuj"
        cardTitle.textColor = .white
        cardTitle.font = UIFont(name: "WinniePERSONALUSE", size: 22)
        cardTitle.textAlignment = .center

        codeField.placeholder = "Enter Room ID"
        codeField.backgroundColor = .white
        codeField.layer.cornerRadius = 12
        codeField.textAlignment = .center
        codeField.keyboardType = .numberPad
        codeField.heightAnchor.constraint(equalToConstant: 48).isActive = true

        styleButton(joinButton, title: "Join", background: .systemGreen , )
        styleButton(createButton, title: "Create Room", background: .systemOrange)

        joinButton.addTarget(self, action: #selector(joinTapped), for: .touchUpInside)
        createButton.addTarget(self, action: #selector(createTapped), for: .touchUpInside)

        nearbyLabel.text = "Nearby Players"
        nearbyLabel.textColor = UIColor.white.withAlphaComponent(0.8)
        nearbyLabel.textAlignment = .center
        nearbyLabel.font = UIFont(name: "WinniePERSONALUSE", size: 14)

        statusLabel.textColor = .white
        statusLabel.textAlignment = .center
        statusLabel.font = .systemFont(ofSize: 13, weight: .medium)
        statusLabel.numberOfLines = 0
    }

    private func styleButton(_ b: UIButton, title: String, background: UIColor) {
        b.setTitle(title, for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = background
        b.layer.cornerRadius = 14
        b.titleLabel?.font = .systemFont(ofSize: 17, weight: .bold)
        b.heightAnchor.constraint(equalToConstant: 52).isActive = true
    }

    private func layoutUI() {
        let container = UIStackView(arrangedSubviews: [titleLabel, card, nearbyLabel, emojiRow, statusLabel])
        container.axis = .vertical
        container.spacing = 20
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)

        let cardStack = UIStackView(arrangedSubviews: [cardTitle, codeField, joinButton, createButton])
        cardStack.axis = .vertical
        cardStack.spacing = 12
        cardStack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(cardStack)

        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            // push content down so it doesn't collide with back button
            container.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 100),

            cardStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            cardStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            cardStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            cardStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])
    }

    // MARK: Actions (now push, not present)
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

