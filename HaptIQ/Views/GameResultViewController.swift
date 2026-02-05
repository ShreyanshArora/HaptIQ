import UIKit
import FirebaseFirestore

final class GameResultViewController: UIViewController {
    
    // MARK: - Properties
    private let crewmatesWon: Bool
    private let roomCode: String
    private let eliminatedPlayerName: String
    private let eliminatedAvatarImage: String
    private let isWrongElimination: Bool
    private let survivingPlayers: [RoomManager.Player]
    private let nextRound: Int
    private let nextRumbleCount: Int
    
    private var hasNavigated = false
    
    // MARK: - UI Components
    
    private let bgImage: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "bghex"))
        iv.contentMode = .scaleAspectFill
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    // "Haptic Hunt" title badge (for crewmates win screen)
    private let titleBadge: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.isHidden = true
        return iv
    }()
    
    // Title label for badge text
    private let titleBadgeLabel: UILabel = {
        let l = UILabel()
        l.text = "HaPtiC HuNt"
        l.font = UIFont(name: "Aclonica-Regular", size: 22)
        l.textColor = UIColor(red: 255/255, green: 100/255, blue: 100/255, alpha: 1)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        l.isHidden = true
        return l
    }()
    
    // Badge background
    private let badgeBackground: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 100/255, green: 150/255, blue: 200/255, alpha: 0.8)
        v.layer.cornerRadius = 20
        v.translatesAutoresizingMaskIntoConstraints = false
        v.isHidden = true
        return v
    }()
    
    // Red glow circle (for wrong elimination screen)
    private let glowCircleView: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        v.translatesAutoresizingMaskIntoConstraints = false
        v.isHidden = true
        return v
    }()
    
    private let resultLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "Aclonica-Regular", size: 32)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        l.numberOfLines = 3
        return l
    }()
    
    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "Aclonica-Regular", size: 18)
        l.textColor = .white
        l.textAlignment = .center
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let iconView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    // Large avatar for wrong elimination / imposter caught screen
    private let largeAvatarView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.isHidden = true
        return iv
    }()
    
    // Small eliminated player display (for some final results)
    private let eliminatedLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "Aclonica-Regular", size: 18)
        l.textColor = .white
        l.textAlignment = .center
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let eliminatedAvatarView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.layer.cornerRadius = 40
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    // Continue button (for wrong elimination - game continues)
    private let continueButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Continue", for: .normal)
        b.titleLabel?.font = UIFont(name: "Aclonica-Regular", size: 22)
        b.setTitleColor(.white, for: .normal)
        b.layer.cornerRadius = 25
        b.translatesAutoresizingMaskIntoConstraints = false
        b.isHidden = true
        return b
    }()
    
    // Play Again button (for final result)
    private let playAgainButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("PLAY AGAIN", for: .normal)
        b.backgroundColor = UIColor(red: 21/255, green: 174/255, blue: 21/255, alpha: 1)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = UIFont(name: "Aclonica-Regular", size: 24)
        b.layer.cornerRadius = 22
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()
    
    // Exit button (for final result)
    private let exitButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("EXIT TO MENU", for: .normal)
        b.backgroundColor = UIColor(red: 255/255, green: 72/255, blue: 72/255, alpha: 1)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = UIFont(name: "Aclonica-Regular", size: 24)
        b.layer.cornerRadius = 22
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()
    
    // MARK: - Initializer
    
    init(crewmatesWon: Bool,
         roomCode: String,
         eliminatedPlayerName: String = "",
         eliminatedAvatarImage: String = "char1",
         isWrongElimination: Bool = false,
         survivingPlayers: [RoomManager.Player] = [],
         nextRound: Int = 1,
         nextRumbleCount: Int = 3) {
        self.crewmatesWon = crewmatesWon
        self.roomCode = roomCode
        self.eliminatedPlayerName = eliminatedPlayerName
        self.eliminatedAvatarImage = eliminatedAvatarImage
        self.isWrongElimination = isWrongElimination
        self.survivingPlayers = survivingPlayers
        self.nextRound = nextRound
        self.nextRumbleCount = nextRumbleCount
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        
        let myID = RoomManager.shared.currentUserID
        let iAmImposter = (RoomManager.shared.cachedRoles[myID] == "imposter")
        
        print("🎮 GameResultViewController - isWrongElimination: \(isWrongElimination), crewmatesWon: \(crewmatesWon), iAmImposter: \(iAmImposter)")
        
        if isWrongElimination {
            // Wrong person eliminated - game continues
            setupWrongEliminationUI()
            configureWrongElimination()
        } else if crewmatesWon && !iAmImposter {
            // ✅ Crewmates won and I'm a crewmate - show "YOU CAUGHT THE IMPOSTER!"
            setupCrewmatesWonUI()
            configureCrewmatesWon()
        } else if crewmatesWon && iAmImposter {
            // Crewmates won but I'm the imposter - show lose screen
            setupImposterLostUI()
            configureImposterLost()
        } else if !crewmatesWon && iAmImposter {
            // Imposter won and I'm the imposter - show win screen
            setupImposterWonUI()
            configureImposterWon()
        } else {
            // Imposter won and I'm a crewmate - show lose screen
            setupCrewmateLostUI()
            configureCrewmateLost()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if isWrongElimination {
            applyGradientToContinueButton()
            drawRedGlowCircle()
        }
    }
    
    // ════════════════════════════════════════════════════════════════════
    // MARK: - Crewmates Won UI (for crewmates) - "YOU CAUGHT THE IMPOSTER!"
    // ════════════════════════════════════════════════════════════════════
    
    private func setupCrewmatesWonUI() {
        view.backgroundColor = UIColor(red: 10/255, green: 20/255, blue: 45/255, alpha: 1)
        
        view.addSubview(bgImage)
        view.addSubview(badgeBackground)
        view.addSubview(titleBadgeLabel)
        view.addSubview(largeAvatarView)
        view.addSubview(resultLabel)
        view.addSubview(playAgainButton)
        view.addSubview(exitButton)
        
        // Show elements
        badgeBackground.isHidden = false
        titleBadgeLabel.isHidden = false
        largeAvatarView.isHidden = false
        
        // Hide other elements
        iconView.isHidden = true
        subtitleLabel.isHidden = true
        eliminatedAvatarView.isHidden = true
        eliminatedLabel.isHidden = true
        continueButton.isHidden = true
        glowCircleView.isHidden = true
        
        NSLayoutConstraint.activate([
            // Background
            bgImage.topAnchor.constraint(equalTo: view.topAnchor),
            bgImage.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bgImage.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bgImage.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            // Badge background
            badgeBackground.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            badgeBackground.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            badgeBackground.widthAnchor.constraint(equalToConstant: 180),
            badgeBackground.heightAnchor.constraint(equalToConstant: 45),
            
            // Title badge label
            titleBadgeLabel.centerXAnchor.constraint(equalTo: badgeBackground.centerXAnchor),
            titleBadgeLabel.centerYAnchor.constraint(equalTo: badgeBackground.centerYAnchor),
            
            // Large avatar (imposter character)
            largeAvatarView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            largeAvatarView.topAnchor.constraint(equalTo: badgeBackground.bottomAnchor, constant: 30),
            largeAvatarView.widthAnchor.constraint(equalToConstant: 250),
            largeAvatarView.heightAnchor.constraint(equalToConstant: 250),
            
            // Result label
            resultLabel.topAnchor.constraint(equalTo: largeAvatarView.bottomAnchor, constant: 30),
            resultLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            resultLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            
            // Buttons
            playAgainButton.bottomAnchor.constraint(equalTo: exitButton.topAnchor, constant: -20),
            playAgainButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playAgainButton.widthAnchor.constraint(equalToConstant: 260),
            playAgainButton.heightAnchor.constraint(equalToConstant: 60),
            
            exitButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            exitButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            exitButton.widthAnchor.constraint(equalToConstant: 260),
            exitButton.heightAnchor.constraint(equalToConstant: 60)
        ])
        
        playAgainButton.addTarget(self, action: #selector(playAgainTapped), for: .touchUpInside)
        exitButton.addTarget(self, action: #selector(exitTapped), for: .touchUpInside)
    }
    
    private func configureCrewmatesWon() {
        // Show imposter character image (the masked villain)
        largeAvatarView.image = UIImage(named: "imposterCharacter") ?? UIImage(named: "Mafia") ?? UIImage(named: eliminatedAvatarImage)
        
        // "YOU CAUGHT THE IMPOSTER! YOU WON!"
        resultLabel.text = "YOU CAUGHT THE\nIMPOSTER!\nYOU WON!"
        resultLabel.textColor = .white
        resultLabel.font = UIFont(name: "Aclonica-Regular", size: 28)
    }
    
    // ════════════════════════════════════════════════════════════════════
    // MARK: - Imposter Lost UI (for imposter when caught)
    // ════════════════════════════════════════════════════════════════════
    
    private func setupImposterLostUI() {
        view.backgroundColor = UIColor(red: 10/255, green: 20/255, blue: 45/255, alpha: 1)
        
        view.addSubview(bgImage)
        view.addSubview(iconView)
        view.addSubview(resultLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(playAgainButton)
        view.addSubview(exitButton)
        
        // Hide other elements
        badgeBackground.isHidden = true
        titleBadgeLabel.isHidden = true
        largeAvatarView.isHidden = true
        eliminatedAvatarView.isHidden = true
        eliminatedLabel.isHidden = true
        continueButton.isHidden = true
        glowCircleView.isHidden = true
        
        NSLayoutConstraint.activate([
            bgImage.topAnchor.constraint(equalTo: view.topAnchor),
            bgImage.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bgImage.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bgImage.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            iconView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 80),
            iconView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 180),
            iconView.heightAnchor.constraint(equalToConstant: 180),
            
            resultLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 40),
            resultLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            resultLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            
            subtitleLabel.topAnchor.constraint(equalTo: resultLabel.bottomAnchor, constant: 20),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            playAgainButton.bottomAnchor.constraint(equalTo: exitButton.topAnchor, constant: -20),
            playAgainButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playAgainButton.widthAnchor.constraint(equalToConstant: 260),
            playAgainButton.heightAnchor.constraint(equalToConstant: 60),
            
            exitButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            exitButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            exitButton.widthAnchor.constraint(equalToConstant: 260),
            exitButton.heightAnchor.constraint(equalToConstant: 60)
        ])
        
        playAgainButton.addTarget(self, action: #selector(playAgainTapped), for: .touchUpInside)
        exitButton.addTarget(self, action: #selector(exitTapped), for: .touchUpInside)
    }
    
    private func configureImposterLost() {
        iconView.image = UIImage(named: "Mafia") ?? UIImage(systemName: "xmark.circle.fill")
        iconView.tintColor = .red
        
        resultLabel.text = "YOU LOSE!"
        resultLabel.textColor = UIColor(red: 255/255, green: 72/255, blue: 72/255, alpha: 1)
        
        subtitleLabel.text = "The crew caught you!\nBetter luck next time."
        subtitleLabel.isHidden = false
    }
    
    // ════════════════════════════════════════════════════════════════════
    // MARK: - Imposter Won UI (for imposter)
    // ════════════════════════════════════════════════════════════════════
    
    private func setupImposterWonUI() {
        view.backgroundColor = UIColor(red: 10/255, green: 20/255, blue: 45/255, alpha: 1)
        
        view.addSubview(bgImage)
        view.addSubview(iconView)
        view.addSubview(resultLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(playAgainButton)
        view.addSubview(exitButton)
        
        // Hide other elements
        badgeBackground.isHidden = true
        titleBadgeLabel.isHidden = true
        largeAvatarView.isHidden = true
        eliminatedAvatarView.isHidden = true
        eliminatedLabel.isHidden = true
        continueButton.isHidden = true
        glowCircleView.isHidden = true
        
        NSLayoutConstraint.activate([
            bgImage.topAnchor.constraint(equalTo: view.topAnchor),
            bgImage.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bgImage.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bgImage.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            iconView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 80),
            iconView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 180),
            iconView.heightAnchor.constraint(equalToConstant: 180),
            
            resultLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 40),
            resultLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            resultLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            
            subtitleLabel.topAnchor.constraint(equalTo: resultLabel.bottomAnchor, constant: 20),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            playAgainButton.bottomAnchor.constraint(equalTo: exitButton.topAnchor, constant: -20),
            playAgainButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playAgainButton.widthAnchor.constraint(equalToConstant: 260),
            playAgainButton.heightAnchor.constraint(equalToConstant: 60),
            
            exitButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            exitButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            exitButton.widthAnchor.constraint(equalToConstant: 260),
            exitButton.heightAnchor.constraint(equalToConstant: 60)
        ])
        
        playAgainButton.addTarget(self, action: #selector(playAgainTapped), for: .touchUpInside)
        exitButton.addTarget(self, action: #selector(exitTapped), for: .touchUpInside)
    }
    
    private func configureImposterWon() {
        iconView.image = UIImage(named: "Mafia") ?? UIImage(systemName: "crown.fill")
        iconView.tintColor = .red
        
        resultLabel.text = "VICTORY!"
        resultLabel.textColor = UIColor(red: 255/255, green: 72/255, blue: 72/255, alpha: 1)
        
        subtitleLabel.text = "You fooled everyone!\nMaster of deception!"
        subtitleLabel.isHidden = false
    }
    
    // ════════════════════════════════════════════════════════════════════
    // MARK: - Crewmate Lost UI (for crewmates when imposter wins)
    // ════════════════════════════════════════════════════════════════════
    
    private func setupCrewmateLostUI() {
        view.backgroundColor = UIColor(red: 10/255, green: 20/255, blue: 45/255, alpha: 1)
        
        view.addSubview(bgImage)
        view.addSubview(iconView)
        view.addSubview(resultLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(playAgainButton)
        view.addSubview(exitButton)
        
        // Hide other elements
        badgeBackground.isHidden = true
        titleBadgeLabel.isHidden = true
        largeAvatarView.isHidden = true
        eliminatedAvatarView.isHidden = true
        eliminatedLabel.isHidden = true
        continueButton.isHidden = true
        glowCircleView.isHidden = true
        
        NSLayoutConstraint.activate([
            bgImage.topAnchor.constraint(equalTo: view.topAnchor),
            bgImage.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bgImage.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bgImage.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            iconView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 80),
            iconView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 180),
            iconView.heightAnchor.constraint(equalToConstant: 180),
            
            resultLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 40),
            resultLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            resultLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            
            subtitleLabel.topAnchor.constraint(equalTo: resultLabel.bottomAnchor, constant: 20),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            playAgainButton.bottomAnchor.constraint(equalTo: exitButton.topAnchor, constant: -20),
            playAgainButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playAgainButton.widthAnchor.constraint(equalToConstant: 260),
            playAgainButton.heightAnchor.constraint(equalToConstant: 60),
            
            exitButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            exitButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            exitButton.widthAnchor.constraint(equalToConstant: 260),
            exitButton.heightAnchor.constraint(equalToConstant: 60)
        ])
        
        playAgainButton.addTarget(self, action: #selector(playAgainTapped), for: .touchUpInside)
        exitButton.addTarget(self, action: #selector(exitTapped), for: .touchUpInside)
    }
    
    private func configureCrewmateLost() {
        iconView.image = UIImage(systemName: "xmark.circle.fill")
        iconView.tintColor = .red
        
        resultLabel.text = "YOU LOSE!"
        resultLabel.textColor = UIColor(red: 255/255, green: 72/255, blue: 72/255, alpha: 1)
        
        subtitleLabel.text = "The imposter won!\nTry to be more careful next time."
        subtitleLabel.isHidden = false
    }
    
    // ════════════════════════════════════════════════════════════════════
    // MARK: - Wrong Elimination UI (Game Continues)
    // ════════════════════════════════════════════════════════════════════
    
    private func setupWrongEliminationUI() {
        view.backgroundColor = UIColor(red: 10/255, green: 20/255, blue: 45/255, alpha: 1)
        
        view.addSubview(bgImage)
        view.addSubview(glowCircleView)
        view.addSubview(largeAvatarView)
        view.addSubview(resultLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(continueButton)
        
        // Show wrong elimination UI elements
        glowCircleView.isHidden = false
        largeAvatarView.isHidden = false
        continueButton.isHidden = false
        subtitleLabel.isHidden = false
        
        // Hide final result UI elements
        iconView.isHidden = true
        badgeBackground.isHidden = true
        titleBadgeLabel.isHidden = true
        eliminatedAvatarView.isHidden = true
        eliminatedLabel.isHidden = true
        playAgainButton.isHidden = true
        exitButton.isHidden = true
        
        NSLayoutConstraint.activate([
            // Background
            bgImage.topAnchor.constraint(equalTo: view.topAnchor),
            bgImage.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bgImage.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bgImage.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            // Red glow circle (behind avatar)
            glowCircleView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            glowCircleView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -80),
            glowCircleView.widthAnchor.constraint(equalToConstant: 300),
            glowCircleView.heightAnchor.constraint(equalToConstant: 300),
            
            // Large avatar (centered)
            largeAvatarView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            largeAvatarView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -80),
            largeAvatarView.widthAnchor.constraint(equalToConstant: 220),
            largeAvatarView.heightAnchor.constraint(equalToConstant: 220),
            
            // Title "IT WASN'T [NAME]"
            resultLabel.topAnchor.constraint(equalTo: largeAvatarView.bottomAnchor, constant: 30),
            resultLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            resultLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            
            // Subtitle "The Imposter is still among you"
            subtitleLabel.topAnchor.constraint(equalTo: resultLabel.bottomAnchor, constant: 12),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            // Continue button
            continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50),
            continueButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            continueButton.widthAnchor.constraint(equalToConstant: 280),
            continueButton.heightAnchor.constraint(equalToConstant: 55)
        ])
        
        continueButton.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)
    }
    
    private func configureWrongElimination() {
        // Set avatar image of eliminated player
        largeAvatarView.image = UIImage(named: eliminatedAvatarImage) ?? UIImage(named: "char1")
        
        // "IT WASN'T [NAME]"
        resultLabel.text = "IT WASN'T \(eliminatedPlayerName.uppercased())"
        resultLabel.textColor = .white
        resultLabel.font = UIFont(name: "Aclonica-Regular", size: 28)
        
        // Subtitle
        subtitleLabel.text = "The Imposter is still among you"
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.8)
    }
    
    private func drawRedGlowCircle() {
        // Remove existing layers
        glowCircleView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        
        let circleLayer = CAShapeLayer()
        let center = CGPoint(x: glowCircleView.bounds.width / 2, y: glowCircleView.bounds.height / 2)
        let radius = min(glowCircleView.bounds.width, glowCircleView.bounds.height) / 2 - 10
        
        circleLayer.path = UIBezierPath(arcCenter: center, radius: radius, startAngle: 0, endAngle: .pi * 2, clockwise: true).cgPath
        circleLayer.fillColor = UIColor.clear.cgColor
        circleLayer.strokeColor = UIColor(red: 255/255, green: 50/255, blue: 50/255, alpha: 0.8).cgColor
        circleLayer.lineWidth = 4
        
        // Add glow effect
        circleLayer.shadowColor = UIColor.red.cgColor
        circleLayer.shadowRadius = 15
        circleLayer.shadowOpacity = 0.8
        circleLayer.shadowOffset = .zero
        
        glowCircleView.layer.addSublayer(circleLayer)
        
        // Add lightning effect
        addLightningEffect()
    }
    
    private func addLightningEffect() {
        let lightningColor = UIColor(red: 255/255, green: 50/255, blue: 50/255, alpha: 0.6).cgColor
        
        // Left lightning
        let leftPath = UIBezierPath()
        leftPath.move(to: CGPoint(x: 20, y: 150))
        leftPath.addLine(to: CGPoint(x: 0, y: 140))
        leftPath.addLine(to: CGPoint(x: 15, y: 130))
        leftPath.addLine(to: CGPoint(x: -10, y: 110))
        
        let leftLayer = CAShapeLayer()
        leftLayer.path = leftPath.cgPath
        leftLayer.strokeColor = lightningColor
        leftLayer.lineWidth = 2
        leftLayer.fillColor = UIColor.clear.cgColor
        glowCircleView.layer.addSublayer(leftLayer)
        
        // Right lightning
        let rightPath = UIBezierPath()
        rightPath.move(to: CGPoint(x: 280, y: 150))
        rightPath.addLine(to: CGPoint(x: 300, y: 140))
        rightPath.addLine(to: CGPoint(x: 285, y: 130))
        rightPath.addLine(to: CGPoint(x: 310, y: 110))
        
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
            UIColor(red: 60/255, green: 100/255, blue: 160/255, alpha: 1).cgColor,
            UIColor(red: 40/255, green: 70/255, blue: 120/255, alpha: 1).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        gradientLayer.frame = continueButton.bounds
        gradientLayer.cornerRadius = 25
        
        continueButton.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    // ════════════════════════════════════════════════════════════════════
    // MARK: - Button Actions
    // ════════════════════════════════════════════════════════════════════
    
    @objc private func continueTapped() {
        guard !hasNavigated else { return }
        hasNavigated = true
        
        print("➡️ Continue tapped - Going to HapticsRoom (Round \(nextRound))")
        
        continueButton.isEnabled = false
        continueButton.alpha = 0.6
        
        let myID = RoomManager.shared.currentUserID
        let myRole: HapticsRoomViewController.PlayerRole =
            (RoomManager.shared.cachedRoles[myID] == "imposter") ? .imposter : .crewmate
        
        let vc = HapticsRoomViewController(
            roomCode: roomCode,
            players: survivingPlayers,
            rumbleCount: nextRumbleCount,
            role: myRole
        )
        vc.currentRound = nextRound
        
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func playAgainTapped() {
        clearGameData()
        
        let vc = RoomLobbyViewController(roomCode: roomCode)
        
        if let nav = navigationController {
            var viewControllers = nav.viewControllers
            if let joinRoomIndex = viewControllers.firstIndex(where: { $0 is JoinRoomViewController }) {
                viewControllers = Array(viewControllers[0...joinRoomIndex])
            }
            viewControllers.append(vc)
            nav.setViewControllers(viewControllers, animated: true)
        }
    }
    
    @objc private func exitTapped() {
        clearGameData()
        
        let vc = JoinRoomViewController()
        
        if let nav = navigationController {
            if let existing = nav.viewControllers.first(where: { $0 is JoinRoomViewController }) {
                nav.popToViewController(existing, animated: true)
            } else {
                nav.setViewControllers([vc], animated: true)
            }
        }
    }
    
    private func clearGameData() {
        let db = Firestore.firestore()
        let roomRef = db.collection("rooms").document(roomCode)
        
        roomRef.collection("guesses").getDocuments { snap, _ in
            guard let docs = snap?.documents else { return }
            for doc in docs { doc.reference.delete() }
        }
        
        roomRef.collection("votes").getDocuments { snap, _ in
            guard let docs = snap?.documents else { return }
            for doc in docs { doc.reference.delete() }
        }
        
        roomRef.updateData([
            "roles": FieldValue.delete(),
            "state": FieldValue.delete(),
            "gameState": FieldValue.delete(),
            "voteResult": FieldValue.delete()
        ])
        
        RoomManager.shared.cachedRoles = [:]
    }
}
