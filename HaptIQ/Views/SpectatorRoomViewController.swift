//
//  SpectatorRoomViewController.swift
//  HaptIQ
//

import UIKit

final class SpectatorViewController: UIViewController {

    private let playerName: String
    private let playerAvatar: String
    
    init(playerName: String? = nil, playerAvatar: String? = nil) {
        self.playerName = playerName ?? UserDefaults.standard.string(forKey: "playerName") ?? "PLAYER"
        self.playerAvatar = playerAvatar ?? UserDefaults.standard.string(forKey: "selectedAvatarImage") ?? "char1"
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private let bgImage: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "bghex"))
        iv.contentMode = .scaleAspectFill
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let glowCircleView: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let largeAvatarView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "Aclonica-Regular", size: 36)
        l.textAlignment = .center
        l.textColor = .white
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "Aclonica-Regular", size: 16)
        l.textAlignment = .center
        l.textColor = UIColor.white.withAlphaComponent(0.8)
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let continueButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Continue", for: .normal)
        b.titleLabel?.font = UIFont(name: "Aclonica-Regular", size: 22)
        b.setTitleColor(.white, for: .normal)
        b.layer.cornerRadius = 25
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private let exitButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Exit to Home", for: .normal)
        b.titleLabel?.font = UIFont(name: "Aclonica-Regular", size: 22)
        b.backgroundColor = UIColor(red: 255/255, green: 72/255, blue: 72/255, alpha: 1) // Red exit button
        b.setTitleColor(.white, for: .normal)
        b.layer.cornerRadius = 25
        b.translatesAutoresizingMaskIntoConstraints = false
        b.alpha = 0 // Hidden initially
        return b
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        setupUI()
        configureInitialUI()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        drawRedGlowCircle()
        applyGradientToContinueButton()
    }

    private func setupUI() {
        view.backgroundColor = UIColor(red: 10/255, green: 20/255, blue: 45/255, alpha: 1)
        
        view.addSubview(bgImage)
        view.addSubview(glowCircleView)
        view.addSubview(largeAvatarView)
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(continueButton)
        view.addSubview(exitButton)

        NSLayoutConstraint.activate([
            bgImage.topAnchor.constraint(equalTo: view.topAnchor),
            bgImage.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bgImage.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bgImage.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            // Red glow circle (behind avatar)
            glowCircleView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            glowCircleView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            glowCircleView.widthAnchor.constraint(equalToConstant: 280),
            glowCircleView.heightAnchor.constraint(equalToConstant: 280),
            
            // Large avatar (centered)
            largeAvatarView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            largeAvatarView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            largeAvatarView.widthAnchor.constraint(equalToConstant: 220),
            largeAvatarView.heightAnchor.constraint(equalToConstant: 220),

            titleLabel.topAnchor.constraint(equalTo: largeAvatarView.bottomAnchor, constant: 40),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),

            continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50),
            continueButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            continueButton.widthAnchor.constraint(equalToConstant: 280),
            continueButton.heightAnchor.constraint(equalToConstant: 55),
            
            exitButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50),
            exitButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            exitButton.widthAnchor.constraint(equalToConstant: 280),
            exitButton.heightAnchor.constraint(equalToConstant: 55)
        ])

        continueButton.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)
        exitButton.addTarget(self, action: #selector(exitTapped), for: .touchUpInside)
    }

    private func configureInitialUI() {
        largeAvatarView.image = UIImage(named: playerAvatar) ?? UIImage(named: "char1")
        
        titleLabel.text = "IT WASN'T \(playerName.uppercased())"
        subtitleLabel.text = "The Imposter is still among you"
    }

    private func drawRedGlowCircle() {
        glowCircleView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        
        let circleLayer = CAShapeLayer()
        let center = CGPoint(x: glowCircleView.bounds.width / 2, y: glowCircleView.bounds.height / 2)
        let radius = min(glowCircleView.bounds.width, glowCircleView.bounds.height) / 2 - 10
        
        circleLayer.path = UIBezierPath(arcCenter: center, radius: radius, startAngle: 0, endAngle: .pi * 2, clockwise: true).cgPath
        circleLayer.fillColor = UIColor.clear.cgColor
        circleLayer.strokeColor = UIColor(red: 255/255, green: 50/255, blue: 50/255, alpha: 0.8).cgColor
        circleLayer.lineWidth = 4
        
        circleLayer.shadowColor = UIColor.red.cgColor
        circleLayer.shadowRadius = 15
        circleLayer.shadowOpacity = 0.8
        circleLayer.shadowOffset = .zero
        
        glowCircleView.layer.addSublayer(circleLayer)
        
        addLightningEffect()
    }

    private func addLightningEffect() {
        let lightningColor = UIColor(red: 255/255, green: 50/255, blue: 50/255, alpha: 0.8).cgColor
        
        let leftPath = UIBezierPath()
        leftPath.move(to: CGPoint(x: 20, y: 150))
        leftPath.addLine(to: CGPoint(x: -10, y: 130))
        leftPath.addLine(to: CGPoint(x: 10, y: 110))
        leftPath.addLine(to: CGPoint(x: -20, y: 80))
        
        let leftLayer = CAShapeLayer()
        leftLayer.path = leftPath.cgPath
        leftLayer.strokeColor = lightningColor
        leftLayer.lineWidth = 2
        leftLayer.fillColor = UIColor.clear.cgColor
        glowCircleView.layer.addSublayer(leftLayer)
        
        let rightPath = UIBezierPath()
        rightPath.move(to: CGPoint(x: 260, y: 140))
        rightPath.addLine(to: CGPoint(x: 290, y: 120))
        rightPath.addLine(to: CGPoint(x: 270, y: 100))
        rightPath.addLine(to: CGPoint(x: 300, y: 70))
        
        let rightLayer = CAShapeLayer()
        rightLayer.path = rightPath.cgPath
        rightLayer.strokeColor = lightningColor
        rightLayer.lineWidth = 2
        rightLayer.fillColor = UIColor.clear.cgColor
        glowCircleView.layer.addSublayer(rightLayer)
    }

    private func applyGradientToContinueButton() {
        continueButton.layer.sublayers?.filter { $0 is CAGradientLayer }.forEach { $0.removeFromSuperlayer() }
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor(red: 10/255, green: 20/255, blue: 40/255, alpha: 1).cgColor,
            UIColor(red: 50/255, green: 150/255, blue: 255/255, alpha: 1).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        gradientLayer.frame = continueButton.bounds
        gradientLayer.cornerRadius = 25
        
        continueButton.layer.insertSublayer(gradientLayer, at: 0)
    }

    @objc private func continueTapped() {
        // Change to spectating mode
        UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseInOut) {
            self.glowCircleView.alpha = 0
            self.largeAvatarView.alpha = 0
            self.continueButton.alpha = 0
            self.exitButton.alpha = 1
            
            // Move texts up seamlessly
            let transform = CGAffineTransform(translationX: 0, y: -200)
            self.titleLabel.transform = transform
            self.subtitleLabel.transform = transform
        } completion: { _ in
            UIView.transition(with: self.titleLabel, duration: 0.3, options: .transitionCrossDissolve) {
                self.titleLabel.text = "SPECTATING"
                self.titleLabel.font = UIFont(name: "Aclonica-Regular", size: 42)
            }
            UIView.transition(with: self.subtitleLabel, duration: 0.3, options: .transitionCrossDissolve) {
                self.subtitleLabel.text = "Wait for the game to finish..."
            }
        }
    }
    
    @objc private func exitTapped() {
        if let nav = navigationController {
            if let existing = nav.viewControllers.first(where: { $0 is JoinRoomViewController }) {
                nav.popToViewController(existing, animated: true)
            } else {
                nav.setViewControllers([JoinRoomViewController()], animated: true)
            }
        }
    }
}
