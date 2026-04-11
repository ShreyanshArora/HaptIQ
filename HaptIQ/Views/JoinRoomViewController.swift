import UIKit
import SwiftUI

class JoinRoomViewController: UIViewController {

    // MARK: - Background
    private let backgroundImage: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "bghex"))
        iv.contentMode = .scaleAspectFill
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
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
        iv.alpha = 0.7
        return iv
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Haptic Hunt"
        l.font = UIFont(name: "Aclonica-Regular", size: 48)
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
        b.titleLabel?.font = UIFont(name: "Aclonica-Regular", size: 32)
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
        b.titleLabel?.font = UIFont(name: "Aclonica-Regular", size: 32)
        b.layer.cornerRadius = 25
        b.layer.borderColor = UIColor.white.cgColor
        b.layer.borderWidth = 3
        b.backgroundColor = .clear
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private let pulseButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Pulse Protocol", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = UIFont(name: "Aclonica-Regular", size: 32)
        b.layer.cornerRadius = 25
        b.layer.borderColor = UIColor.white.cgColor
        b.layer.borderWidth = 3
        b.backgroundColor = .clear
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()
    private func animatePulseButton() {
        UIView.animate(
            withDuration: 1.4,
            delay: 0,
            options: [.autoreverse, .repeat, .allowUserInteraction],
            animations: {
                self.pulseButton.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
            }
        )
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if let gradient = pulseButton.layer.sublayers?.first as? CAGradientLayer {
            gradient.frame = pulseButton.bounds
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animatePulseButton()
    }

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
        view.addSubview(leftCharacter)
        view.addSubview(rightCharacter)
        view.addSubview(titleBanner)
        view.addSubview(titleLabel)
        view.addSubview(createButton)
        view.addSubview(joinButton)
        view.addSubview(pulseButton)

        NSLayoutConstraint.activate([
            // Background
            backgroundImage.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImage.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImage.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImage.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Left Character
            leftCharacter.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: -50),
            leftCharacter.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 60),
            leftCharacter.widthAnchor.constraint(equalToConstant: 350),
            leftCharacter.heightAnchor.constraint(equalToConstant: 530),

            // Right Character
            rightCharacter.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 50),
            rightCharacter.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 180),
            rightCharacter.widthAnchor.constraint(equalToConstant: 200),
            rightCharacter.heightAnchor.constraint(equalToConstant: 340),

            // Title banner
            titleBanner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleBanner.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 100),
            titleBanner.widthAnchor.constraint(equalToConstant: 360),
            titleBanner.heightAnchor.constraint(equalToConstant: 140),

            // Title label
            titleLabel.centerXAnchor.constraint(equalTo: titleBanner.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: titleBanner.centerYAnchor),

            // Create button
            createButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            createButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 30),
            createButton.widthAnchor.constraint(equalToConstant: 280),
            createButton.heightAnchor.constraint(equalToConstant: 70),

            // Join button
            joinButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            joinButton.topAnchor.constraint(equalTo: createButton.bottomAnchor, constant: 25),
            joinButton.widthAnchor.constraint(equalToConstant: 280),
            joinButton.heightAnchor.constraint(equalToConstant: 70),

            // PulseProtocol button
            pulseButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pulseButton.topAnchor.constraint(equalTo: joinButton.bottomAnchor, constant: 55),
            pulseButton.widthAnchor.constraint(equalToConstant: 270),
            pulseButton.heightAnchor.constraint(equalToConstant: 62)

        ])
    }

    // MARK: - Actions
    private func setupActions() {
        createButton.addTarget(self, action: #selector(createTapped), for: .touchUpInside)
        joinButton.addTarget(self, action: #selector(joinTapped), for: .touchUpInside)
        pulseButton.addTarget(self, action: #selector(openPulseProtocol), for: .touchUpInside)
    }

    @objc private func joinTapped() {
        let vc = RoomCodeEntry()
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func createTapped() {
        RoomManager.shared.createRoom { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let code):
                    self?.navigationController?.pushViewController(
                        CreateRoomViewController(roomCode: code),
                        animated: true
                    )
                case .failure(let error):
                    print("Create Err:", error)
                }
            }
        }
    }

    // ✅ THIS IS THE ONLY CORRECT WAY TO OPEN SWIFTUI
    @objc private func openPulseProtocol() {
        let pulseView = PulseProtocolEntry.rootView()
        let vc = UIHostingController(rootView: pulseView)
        vc.view.backgroundColor = .clear

        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
            

    }
}
