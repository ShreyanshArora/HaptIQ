import UIKit

class JoinRoomViewController: UIViewController {

    // MARK: - Background
    private let backgroundImage: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "bghex"))
        iv.contentMode = .scaleAspectFill
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    // MARK: - Top Bar Icons
    private let profileButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(named: "char1"), for: .normal) // Replace with your avatar
        b.layer.cornerRadius = 25
        b.layer.borderWidth = 2
        b.layer.borderColor = UIColor.white.cgColor
        b.clipsToBounds = true
        b.backgroundColor = UIColor(white: 0.2, alpha: 0.5)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()
    


    // MARK: - Characters
    private let leftCharacter: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "leftChar"))
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let rightCharacter: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "rightChar"))
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    // MARK: - Title
    private let titleBanner: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "titleBanner"))
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.transform = CGAffineTransform(rotationAngle: -0.08)
        iv.alpha = 0.7 // Make it transparent
        return iv
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Haptic Hunt"
        l.font = UIFont(name: "WinniePERSONALUSE", size: 48)
        l.textColor = .white
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        l.transform = CGAffineTransform(rotationAngle: -0.2)
        return l
    }()

    // MARK: - Buttons
    private let createButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Create Room", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = UIFont(name: "WinniePERSONALUSE", size: 32)
        b.layer.cornerRadius = 25
        b.layer.borderColor = UIColor.white.cgColor
        b.layer.borderWidth = 3
        b.backgroundColor = .clear
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private let joinButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Join Room", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = UIFont(name: "WinniePERSONALUSE", size: 32)
        b.layer.cornerRadius = 25
        b.layer.borderColor = UIColor.white.cgColor
        b.layer.borderWidth = 3
        b.backgroundColor = .clear
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()



    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        setupLayout()
        setupActions()
    }

    // MARK: - Layout
    private func setupLayout() {
        view.addSubview(backgroundImage)
        view.addSubview(profileButton)
        view.addSubview(leftCharacter)
        view.addSubview(rightCharacter)
        view.addSubview(titleBanner)
        view.addSubview(titleLabel)
        view.addSubview(createButton)
        view.addSubview(joinButton)

        NSLayoutConstraint.activate([
            // Background
            backgroundImage.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImage.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImage.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImage.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Top Left - Profile
            profileButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 15),
            profileButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            profileButton.widthAnchor.constraint(equalToConstant: 50),
            profileButton.heightAnchor.constraint(equalToConstant: 50),

            // Left Character - extreme edge, centered
            leftCharacter.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: -30),
            leftCharacter.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),
            leftCharacter.widthAnchor.constraint(equalToConstant: 240),
            leftCharacter.heightAnchor.constraint(equalToConstant: 400),

            // Right Character - extreme edge, lower
            rightCharacter.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 50),
            rightCharacter.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 140),
            rightCharacter.widthAnchor.constraint(equalToConstant: 200),
            rightCharacter.heightAnchor.constraint(equalToConstant: 340),

            // Title banner - bigger and tilted
            titleBanner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleBanner.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 100),
            titleBanner.widthAnchor.constraint(equalToConstant: 360),
            titleBanner.heightAnchor.constraint(equalToConstant: 140),

            // Title text
            titleLabel.centerXAnchor.constraint(equalTo: titleBanner.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: titleBanner.centerYAnchor),

            // Create Room button
            createButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            createButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 30),
            createButton.widthAnchor.constraint(equalToConstant: 280),
            createButton.heightAnchor.constraint(equalToConstant: 70),

            // Join Room button
            joinButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            joinButton.topAnchor.constraint(equalTo: createButton.bottomAnchor, constant: 25),
            joinButton.widthAnchor.constraint(equalToConstant: 280),
            joinButton.heightAnchor.constraint(equalToConstant: 70)
        ])
    }

    // MARK: - Actions
    private func setupActions() {
        createButton.addTarget(self, action: #selector(createTapped), for: .touchUpInside)
        joinButton.addTarget(self, action: #selector(joinTapped), for: .touchUpInside)
    }

    @objc private func joinTapped() {
        // Navigate to room code entry screen
        let vc = RoomCodeEntryViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func createTapped() {
        RoomManager.shared.createRoom { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let code):
                    self?.navigationController?.pushViewController(CreateRoomViewController(roomCode: code), animated: true)
                case .failure(let error):
                    print("Create Err:", error)
                }
            }
        }
    }
}
