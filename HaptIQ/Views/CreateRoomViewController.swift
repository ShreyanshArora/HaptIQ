import UIKit

class CreateRoomViewController: UIViewController {
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
        l.font = UIFont(name: "WinniePERSONALUSE", size: 26)
        l.textAlignment = .center
        l.numberOfLines = 2
        return l
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
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "CREATE ROOM"
        l.textColor = .white
        l.textAlignment = .center
        l.font = UIFont(name: "WinniePERSONALUSE", size: 30)
        return l
    }()

    private let codeLabel: UILabel = {
        let l = UILabel()
        l.textAlignment = .center
        l.textColor = .orange
        l.font = UIFont(name: "WinniePERSONALUSE", size: 24)
        l.backgroundColor = .white
        l.layer.cornerRadius = 10
        l.layer.masksToBounds = true
        l.heightAnchor.constraint(equalToConstant: 51).isActive = true
        l.widthAnchor.constraint(equalToConstant: 218).isActive = true
        return l
    }()

    private let nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("NEXT", for: .normal)
        button.backgroundColor = UIColor(red: 21/255, green: 174/255, blue: 21/255, alpha: 1.0)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont(name: "WinniePERSONALUSE", size: 32)
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
    
    private let copyHint: UILabel = {
        let l = UILabel()
        l.text = "Tap to copy the code anuj"
        l.font = UIFont(name: "WinniePERSONALUSE", size: 24)
        l.textColor  = .white
        l.textAlignment = .center
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
        card.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        card.layer.cornerRadius = 24
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)

        let tap = UITapGestureRecognizer(target: self, action: #selector(copyCode))
        codeLabel.isUserInteractionEnabled = true
        codeLabel.addGestureRecognizer(tap)
    }
                            // useless code dont have any use
//    private func styleButton(_ b: UIButton, title: String, background: UIColor) {
//        b.setTitle(title, for: .normal)
//        b.setTitleColor(.white, for: .normal)
//        b.backgroundColor = background
//        b.layer.cornerRadius = 14
//        b.titleLabel?.font = .systemFont(ofSize: 17, weight: .bold)
//        b.heightAnchor.constraint(equalToConstant: 52).isActive = true
//    }

    private func layoutUI() {
        let container = UIStackView(arrangedSubviews: [tipLabel, card, copyHint])
        container.axis = .vertical
        container.spacing = 50
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)

        let cardStack = UIStackView(arrangedSubviews: [titleLabel, codeLabel, nextButton])
        cardStack.axis = .vertical
        cardStack.spacing = 45
        cardStack.alignment = .center
        cardStack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(cardStack)

        NSLayoutConstraint.activate([
            // Container
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            container.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 100),

            // Card stack inside card
            cardStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            cardStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            cardStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 20),
            cardStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -20)
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
