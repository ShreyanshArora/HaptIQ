import UIKit

final class RoomLobbyViewController: UIViewController {
    private let roomCode: String
    private let gradientLayer = CAGradientLayer()

    init(roomCode: String) {
        self.roomCode = roomCode
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private let headerLabel: UILabel = {
        let l = UILabel()
        l.text = "🎯 Room Lobby"
        l.textColor = .white
        l.font = .systemFont(ofSize: 32, weight: .bold)
        l.textAlignment = .center
        return l
    }()

    private let card = UIView()

    private let codeTitle: UILabel = {
        let l = UILabel()
        l.text = "Room Code:"
        l.textColor = UIColor.white.withAlphaComponent(0.8)
        l.textAlignment = .center
        l.font = .systemFont(ofSize: 16, weight: .medium)
        return l
    }()

    private let codeValue: UILabel = {
        let l = UILabel()
        l.textAlignment = .center
        l.textColor = .white
        l.font = .systemFont(ofSize: 26, weight: .bold)
        l.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        l.layer.cornerRadius = 12
        l.clipsToBounds = true
        l.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return l
    }()

    private let waitingLabel: UILabel = {
        let l = UILabel()
        l.text = "Waiting for other players to join..."
        l.textColor = UIColor.white.withAlphaComponent(0.95)
        l.textAlignment = .center
        l.font = .systemFont(ofSize: 18, weight: .semibold)
        return l
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupGradient()
        setupUI()
        layoutUI()
        addFigmaBackButton()
        codeValue.text = roomCode
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
        gradientLayer.endPoint   = CGPoint(x: 0.5, y: 1)
        view.layer.insertSublayer(gradientLayer, at: 0)
    }

    private func setupUI() {
        view.backgroundColor = .black
        card.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        card.layer.cornerRadius = 20
    }

    private func layoutUI() {
        let cardStack = UIStackView(arrangedSubviews: [codeTitle, codeValue])
        cardStack.axis = .vertical
        cardStack.spacing = 8
        cardStack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(cardStack)

        let root = UIStackView(arrangedSubviews: [headerLabel, card, waitingLabel, UIView()])
        root.axis = .vertical
        root.spacing = 25
        root.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(root)

        NSLayoutConstraint.activate([
            root.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            root.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            root.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 100), // ↓ shifted
            root.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -24),

            cardStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            cardStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            cardStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            cardStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
            card.heightAnchor.constraint(greaterThanOrEqualToConstant: 100)
        ])
    }
}
