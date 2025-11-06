import UIKit

final class CreateRoomViewController: UIViewController {
    private let roomCode: String
    private let gradientLayer = CAGradientLayer()

    init(roomCode: String) {
        self.roomCode = roomCode
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private let tipLabel: UILabel = {
        let l = UILabel()
        l.text = "Share this code with your friends"
        l.textColor = .white
        l.font = .systemFont(ofSize: 18, weight: .semibold)
        l.textAlignment = .center
        l.numberOfLines = 2
        return l
    }()

    private let card = UIView()
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "CREATE ROOM"
        l.textColor = .white
        l.textAlignment = .center
        l.font = .systemFont(ofSize: 22, weight: .bold)
        return l
    }()

    private let codeLabel: UILabel = {
        let l = UILabel()
        l.textAlignment = .center
        l.textColor = .orange
        l.font = .systemFont(ofSize: 24, weight: .bold)
        l.backgroundColor = .white
        l.layer.cornerRadius = 12
        l.layer.masksToBounds = true
        l.heightAnchor.constraint(equalToConstant: 52).isActive = true
        return l
    }()

    private let nextButton = UIButton(type: .system)
    private let copyHint: UILabel = {
        let l = UILabel()
        l.text = "Tap to copy the code"
        l.textColor = UIColor.white.withAlphaComponent(0.8)
        l.textAlignment = .center
        l.font = .systemFont(ofSize: 12)
        return l
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupGradient()
        setupUI()
        layoutUI()
        addFigmaBackButton()
        codeLabel.text = roomCode
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
        card.layer.cornerRadius = 24

        styleButton(nextButton, title: "NEXT", background: .systemGreen)
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)

        let tap = UITapGestureRecognizer(target: self, action: #selector(copyCode))
        codeLabel.isUserInteractionEnabled = true
        codeLabel.addGestureRecognizer(tap)
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
        let container = UIStackView(arrangedSubviews: [tipLabel, card, copyHint])
        container.axis = .vertical
        container.spacing = 30
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)

        let cardStack = UIStackView(arrangedSubviews: [titleLabel, codeLabel, nextButton])
        cardStack.axis = .vertical
        cardStack.spacing = 18
        cardStack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(cardStack)

        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            container.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 100), // ↓ shifted

            cardStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            cardStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            cardStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            cardStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
        ])
    }

    @objc private func copyCode() {
        UIPasteboard.general.string = roomCode
    }

    @objc private func nextTapped() {
        let vc = EnterNameViewController(roomCode: roomCode)
        navigationController?.pushViewController(vc, animated: true)
    }
}
