import UIKit

final class RoomViewController: UIViewController {

    private let gradientLayer = CAGradientLayer()
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Enter room code to Join the room"
        l.textColor = .white
        l.font = .systemFont(ofSize: 20, weight: .semibold)
        l.textAlignment = .center
        l.numberOfLines = 2
        return l
    }()

    private let card = UIView()
    private let cardTitle = UILabel()
    private let codeField = UITextField()
    private let joinButton = UIButton(type: .system)
    private let createButton = UIButton(type: .system)
    private let nearbyLabel = UILabel()
    private let emojiRow = UIStackView()
    private let statusLabel = UILabel()

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

        card.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        card.layer.cornerRadius = 24

        cardTitle.text = "Join Room"
        cardTitle.textColor = .white
        cardTitle.font = .systemFont(ofSize: 22, weight: .bold)
        cardTitle.textAlignment = .center

        codeField.placeholder = "Enter Room ID"
        codeField.backgroundColor = .white
        codeField.layer.cornerRadius = 12
        codeField.textAlignment = .center
        codeField.keyboardType = .numberPad
        codeField.heightAnchor.constraint(equalToConstant: 48).isActive = true

        styleButton(joinButton, title: "Join", background: .systemGreen)
        styleButton(createButton, title: "Create Room", background: .systemOrange)

        joinButton.addTarget(self, action: #selector(joinTapped), for: .touchUpInside)
        createButton.addTarget(self, action: #selector(createTapped), for: .touchUpInside)

        nearbyLabel.text = "Nearby Players"
        nearbyLabel.textColor = UIColor.white.withAlphaComponent(0.8)
        nearbyLabel.textAlignment = .center
        nearbyLabel.font = .systemFont(ofSize: 14, weight: .medium)

        ["😆","🙂","😁","🤪"].forEach {
            let lbl = UILabel(); lbl.text = $0; lbl.font = .systemFont(ofSize: 32)
            emojiRow.addArrangedSubview(lbl)
        }
        emojiRow.axis = .horizontal
        emojiRow.spacing = 16
        emojiRow.distribution = .equalCentering

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
