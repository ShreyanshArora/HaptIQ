import UIKit

class JoinRoomViewController: UIViewController {

    // MARK: - Background + Characters

    private let backgroundImage: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "bgHex"))
        iv.contentMode = .scaleAspectFill
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

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

    private let titleBanner: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "titleBanner"))
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Haptic Hunt"
        l.font = UIFont(name: "WinniePERSONALUSE", size: 42)
        l.textColor = .white
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // MARK: - Input + Buttons

    private let codeField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Enter Room Code"
        tf.font = UIFont(name: "WinniePERSONALUSE", size: 24)
        tf.textAlignment = .center
        tf.backgroundColor = .white
        tf.layer.cornerRadius = 16
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.heightAnchor.constraint(equalToConstant: 55).isActive = true
        return tf
    }()

    private let joinButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Join Room", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = UIFont(name: "WinniePERSONALUSE", size: 28)
        b.layer.cornerRadius = 20
        b.layer.borderColor = UIColor.white.cgColor
        b.layer.borderWidth = 4
        b.backgroundColor = UIColor(red: 62/255, green: 136/255, blue: 245/255, alpha: 1)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private let createButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Create Room", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = UIFont(name: "WinniePERSONALUSE", size: 28)
        b.layer.cornerRadius = 20
        b.layer.borderColor = UIColor.white.cgColor
        b.layer.borderWidth = 4
        b.backgroundColor = UIColor(red: 252/255, green: 137/255, blue: 66/255, alpha: 1)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    // Help icon
    private func setupHelpButton() {
        let icon = UIBarButtonItem(
            image: UIImage(systemName: "questionmark.circle.fill"),
            style: .plain,
            target: self,
            action: #selector(openHelp)
        )
        icon.tintColor = .white
        navigationItem.rightBarButtonItem = icon
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationItem.title = ""

        setupHelpButton()
        setupLayout()
        setupActions()
    }

    // MARK: - Layout

    private func setupLayout() {

        view.addSubview(backgroundImage)
        view.addSubview(leftCharacter)
        view.addSubview(rightCharacter)
        view.addSubview(titleBanner)
        view.addSubview(titleLabel)
        view.addSubview(codeField)
        view.addSubview(joinButton)
        view.addSubview(createButton)

        NSLayoutConstraint.activate([

            // Background
            backgroundImage.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImage.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImage.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImage.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Characters
            leftCharacter.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 5),
            leftCharacter.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            leftCharacter.widthAnchor.constraint(equalToConstant: 140),
            leftCharacter.heightAnchor.constraint(equalToConstant: 240),

            rightCharacter.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -5),
            rightCharacter.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            rightCharacter.widthAnchor.constraint(equalToConstant: 140),
            rightCharacter.heightAnchor.constraint(equalToConstant: 240),

            // Title banner
            titleBanner.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            titleBanner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleBanner.widthAnchor.constraint(equalToConstant: 280),
            titleBanner.heightAnchor.constraint(equalToConstant: 100),

            // Title text
            titleLabel.centerXAnchor.constraint(equalTo: titleBanner.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: titleBanner.centerYAnchor),

            // Room code input
            codeField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            codeField.topAnchor.constraint(equalTo: titleBanner.bottomAnchor, constant: 40),
            codeField.widthAnchor.constraint(equalToConstant: 240),

            // Join button
            joinButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            joinButton.topAnchor.constraint(equalTo: codeField.bottomAnchor, constant: 25),
            joinButton.widthAnchor.constraint(equalToConstant: 240),
            joinButton.heightAnchor.constraint(equalToConstant: 65),

            // Create button
            createButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            createButton.topAnchor.constraint(equalTo: joinButton.bottomAnchor, constant: 20),
            createButton.widthAnchor.constraint(equalToConstant: 240),
            createButton.heightAnchor.constraint(equalToConstant: 65)
        ])
    }

    // MARK: - Actions

    private func setupActions() {
        joinButton.addTarget(self, action: #selector(joinTapped), for: .touchUpInside)
        createButton.addTarget(self, action: #selector(createTapped), for: .touchUpInside)
    }

    @objc private func joinTapped() {
        guard let code = codeField.text?.trimmingCharacters(in: .whitespaces), !code.isEmpty else { return }

        RoomManager.shared.joinRoom(withCode: code) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    let vc = EnterNameViewController(roomCode: code, isCreator: false)
                    self?.navigationController?.pushViewController(vc, animated: true)
                case .failure(let error):
                    print("Join Err:", error)
                }
            }
        }
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

    @objc private func openHelp() {
        navigationController?.pushViewController(Instructions(), animated: true)
    }
}
