import UIKit

class Instructions: UIViewController {
    
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    
    // MARK: - Background (matches JoinRoomViewController)
    private let backgroundImage: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "bghex"))
        iv.contentMode = .scaleAspectFill
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    // MARK: - Close Button
    private let closeButton: UIButton = {
        let b = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        let image = UIImage(systemName: "xmark.circle.fill", withConfiguration: config)
        b.setImage(image, for: .normal)
        b.tintColor = UIColor.white.withAlphaComponent(0.8)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()
    
    // MARK: - Colors
    private let accentBlue = UIColor(red: 90/255, green: 150/255, blue: 255/255, alpha: 1)
    private let cardBg = UIColor(red: 30/255, green: 30/255, blue: 40/255, alpha: 0.85)
    private let subtitleBlue = UIColor(red: 170/255, green: 200/255, blue: 255/255, alpha: 1)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        setupBackground()
        setupScrollView()
        setupContent()
        setupCloseButton()
    }
    
    // MARK: - Background Setup
    private func setupBackground() {
        view.addSubview(backgroundImage)
        NSLayoutConstraint.activate([
            backgroundImage.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImage.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImage.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImage.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // MARK: - Close Button Setup
    private func setupCloseButton() {
        view.addSubview(closeButton)
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 36),
            closeButton.heightAnchor.constraint(equalToConstant: 36)
        ])
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
    }
    
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
    
    // MARK: - ScrollView Setup
    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        
        contentStack.axis = .vertical
        contentStack.spacing = 20
        contentStack.alignment = .fill
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -40),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40)
        ])
    }
    
    // MARK: - Build Screen Content
    private func setupContent() {
        
        // TITLE
        let titleLabel = UILabel()
        titleLabel.text = "HOW TO PLAY"
        titleLabel.textColor = accentBlue
        titleLabel.font = UIFont(name: "Aclonica-Regular", size: 32)
        titleLabel.textAlignment = .center
        contentStack.addArrangedSubview(titleLabel)
        
        // SUBTITLE
        let subtitle = UILabel()
        subtitle.text = "Find the imposter before it's too late!"
        subtitle.numberOfLines = 0
        subtitle.textAlignment = .center
        subtitle.textColor = subtitleBlue
        subtitle.font = UIFont(name: "Aclonica-Regular", size: 16)
        contentStack.addArrangedSubview(subtitle)
        
        // Spacer
        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        spacer.heightAnchor.constraint(equalToConstant: 8).isActive = true
        contentStack.addArrangedSubview(spacer)
        
        // Cards Stack
        let cardsStack = UIStackView()
        cardsStack.axis = .vertical
        cardsStack.spacing = 20
        cardsStack.alignment = .fill
        contentStack.addArrangedSubview(cardsStack)
        
        // STEP 1
        cardsStack.addArrangedSubview(makeStepCard(
            stepNumber: "1",
            iconName: "door.left.hand.open",
            title: "Create or Join a Room",
            bullets: [
                "Tap Create Room or Join Room",
                "Enter the room code to play with friends"
            ]
        ))
        
        // STEP 2
        cardsStack.addArrangedSubview(makeStepCard(
            stepNumber: "2",
            iconName: "person.crop.circle.badge.checkmark",
            title: "Enter the Game",
            bullets: [
                "Enter your name",
                "Choose your avatar",
                "Wait for all players to join"
            ]
        ))
        
        // STEP 3
        cardsStack.addArrangedSubview(makeStepCard(
            stepNumber: "3",
            iconName: "play.circle.fill",
            title: "Start the Game",
            bullets: [
                "The host taps Start Game",
                "The game begins for all players"
            ]
        ))
        
        // STEP 4 — Roles
        cardsStack.addArrangedSubview(makeRoleCard())
        
        // STEP 5
        cardsStack.addArrangedSubview(makeStepCard(
            stepNumber: "5",
            iconName: "iphone.radiowaves.left.and.right",
            title: "Feel the Clue",
            bullets: [
                "All players hold their own device",
                "A vibration will play:",
                "✔ Players feel a haptic signal",
                "❌ Imposter feels nothing"
            ]
        ))
        
        // STEP 6
        cardsStack.addArrangedSubview(makeStepCard(
            stepNumber: "6",
            iconName: "eye.fill",
            title: "Identify the Imposter",
            bullets: [
                "Discuss with other players",
                "Observe reactions and behavior",
                "The imposter tries to blend in"
            ]
        ))
        
        // STEP 7
        cardsStack.addArrangedSubview(makeStepCard(
            stepNumber: "7",
            iconName: "questionmark.circle.fill",
            title: "Imposter Guess Phase",
            bullets: [
                "The imposter gets limited chances to guess the hidden clue",
                "If the imposter guesses correctly → Imposter Wins",
                "If the imposter guesses wrong multiple times → move to voting"
            ]
        ))
        
        // STEP 8
        cardsStack.addArrangedSubview(makeStepCard(
            stepNumber: "8",
            iconName: "hand.raised.fill",
            title: "Voting Round",
            bullets: [
                "All players vote for who they think is the imposter",
                "Each player gets one vote"
            ]
        ))
        
        // STEP 9
        cardsStack.addArrangedSubview(makeStepCard(
            stepNumber: "9",
            iconName: "trophy.fill",
            title: "Elimination & Result",
            bullets: [
                "The most voted player is revealed and eliminated",
                "If the imposter is caught → Players Win 🎉",
                "If not → the game continues or ends based on rules"
            ]
        ))
    }
    
    // MARK: - Standard Step Card Builder
    private func makeStepCard(
        stepNumber: String,
        iconName: String,
        title: String,
        bullets: [String]
    ) -> UIView {
        
        let card = UIView()
        card.backgroundColor = cardBg
        card.layer.cornerRadius = 20
        card.layer.borderColor = UIColor.white.withAlphaComponent(0.08).cgColor
        card.layer.borderWidth = 1
        card.translatesAutoresizingMaskIntoConstraints = false
        
        // Step number badge
        let badge = makeStepBadge(stepNumber)
        
        // Icon
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 28, weight: .medium)
        let icon = UIImageView(image: UIImage(systemName: iconName, withConfiguration: iconConfig))
        icon.contentMode = .scaleAspectFit
        icon.tintColor = accentBlue
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.heightAnchor.constraint(equalToConstant: 36).isActive = true
        icon.widthAnchor.constraint(equalToConstant: 36).isActive = true
        
        // Header row (badge + icon + title)
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont(name: "Aclonica-Regular", size: 18)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 0
        
        let headerRow = UIStackView(arrangedSubviews: [badge, icon, titleLabel])
        headerRow.axis = .horizontal
        headerRow.spacing = 10
        headerRow.alignment = .center
        
        // Bullet list
        let bulletStack = UIStackView()
        bulletStack.axis = .vertical
        bulletStack.spacing = 8
        bulletStack.alignment = .leading
        
        for bullet in bullets {
            let row = makeBulletRow(bullet)
            bulletStack.addArrangedSubview(row)
        }
        
        // Inner stack
        let innerStack = UIStackView(arrangedSubviews: [headerRow, bulletStack])
        innerStack.axis = .vertical
        innerStack.spacing = 14
        innerStack.translatesAutoresizingMaskIntoConstraints = false
        
        card.addSubview(innerStack)
        
        NSLayoutConstraint.activate([
            innerStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
            innerStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18),
            innerStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 18),
            innerStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -18),
            
            headerRow.leadingAnchor.constraint(equalTo: innerStack.leadingAnchor),
            headerRow.trailingAnchor.constraint(equalTo: innerStack.trailingAnchor)
        ])
        
        return card
    }
    
    // MARK: - Role Assignment Card (Step 4 — special layout)
    private func makeRoleCard() -> UIView {
        let card = UIView()
        card.backgroundColor = cardBg
        card.layer.cornerRadius = 20
        card.layer.borderColor = UIColor.white.withAlphaComponent(0.08).cgColor
        card.layer.borderWidth = 1
        card.translatesAutoresizingMaskIntoConstraints = false
        
        let badge = makeStepBadge("4")
        
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 28, weight: .medium)
        let icon = UIImageView(image: UIImage(systemName: "person.fill.questionmark", withConfiguration: iconConfig))
        icon.contentMode = .scaleAspectFit
        icon.tintColor = accentBlue
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.heightAnchor.constraint(equalToConstant: 36).isActive = true
        icon.widthAnchor.constraint(equalToConstant: 36).isActive = true
        
        let titleLabel = UILabel()
        titleLabel.text = "Roles Are Assigned"
        titleLabel.font = UIFont(name: "Aclonica-Regular", size: 18)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 0
        
        let headerRow = UIStackView(arrangedSubviews: [badge, icon, titleLabel])
        headerRow.axis = .horizontal
        headerRow.spacing = 10
        headerRow.alignment = .center
        
        let descLabel = UILabel()
        descLabel.text = "Each player secretly gets a role:"
        descLabel.font = UIFont(name: "Aclonica-Regular", size: 14)
        descLabel.textColor = subtitleBlue
        descLabel.numberOfLines = 0
        
        // Imposter role box
        let imposterBox = makeRoleBox(
            emoji: "🟥",
            roleName: "Imposter",
            roleDesc: "You receive NO haptic clue",
            borderColor: UIColor(red: 1, green: 0.3, blue: 0.3, alpha: 0.5)
        )
        
        // Player role box
        let playerBox = makeRoleBox(
            emoji: "🟦",
            roleName: "Player",
            roleDesc: "You receive a haptic vibration clue",
            borderColor: UIColor(red: 0.3, green: 0.5, blue: 1, alpha: 0.5)
        )
        
        let rolesRow = UIStackView(arrangedSubviews: [imposterBox, playerBox])
        rolesRow.axis = .horizontal
        rolesRow.spacing = 10
        rolesRow.distribution = .fillEqually
        
        // Warning
        let warningLabel = UILabel()
        warningLabel.text = "⚠️ Keep your role secret!"
        warningLabel.font = UIFont(name: "Aclonica-Regular", size: 15)
        warningLabel.textColor = UIColor(red: 1, green: 0.85, blue: 0.3, alpha: 1)
        warningLabel.textAlignment = .center
        
        let innerStack = UIStackView(arrangedSubviews: [headerRow, descLabel, rolesRow, warningLabel])
        innerStack.axis = .vertical
        innerStack.spacing = 14
        innerStack.translatesAutoresizingMaskIntoConstraints = false
        
        card.addSubview(innerStack)
        
        NSLayoutConstraint.activate([
            innerStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
            innerStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18),
            innerStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 18),
            innerStack.bottomAnchor.constraint(lessThanOrEqualTo: card.bottomAnchor, constant: -18),
            
            headerRow.leadingAnchor.constraint(equalTo: innerStack.leadingAnchor),
            headerRow.trailingAnchor.constraint(equalTo: innerStack.trailingAnchor)
        ])
        
        return card
    }
    
    // MARK: - Helpers
    
    private func makeStepBadge(_ number: String) -> UIView {
        let badge = UIView()
        badge.backgroundColor = accentBlue
        badge.layer.cornerRadius = 16
        badge.translatesAutoresizingMaskIntoConstraints = false
        badge.widthAnchor.constraint(equalToConstant: 32).isActive = true
        badge.heightAnchor.constraint(equalToConstant: 32).isActive = true
        
        let label = UILabel()
        label.text = number
        label.font = UIFont(name: "Aclonica-Regular", size: 16)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        badge.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: badge.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: badge.centerYAnchor)
        ])
        
        return badge
    }
    
    private func makeBulletRow(_ text: String) -> UIView {
        let dot = UILabel()
        dot.text = "•"
        dot.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        dot.textColor = accentBlue
        dot.setContentHuggingPriority(.required, for: .horizontal)
        dot.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        let label = UILabel()
        label.text = text
        label.font = UIFont(name: "Aclonica-Regular", size: 14)
        label.textColor = UIColor.white.withAlphaComponent(0.9)
        label.numberOfLines = 0
        
        let row = UIStackView(arrangedSubviews: [dot, label])
        row.axis = .horizontal
        row.spacing = 8
        row.alignment = .top
        
        return row
    }
    
    private func makeRoleBox(emoji: String, roleName: String, roleDesc: String, borderColor: UIColor) -> UIView {
        let box = UIView()
        box.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        box.layer.cornerRadius = 14
        box.layer.borderColor = borderColor.cgColor
        box.layer.borderWidth = 1.5
        box.translatesAutoresizingMaskIntoConstraints = false
        
        let emojiLabel = UILabel()
        emojiLabel.text = emoji
        emojiLabel.font = UIFont.systemFont(ofSize: 28)
        emojiLabel.textAlignment = .center
        
        let nameLabel = UILabel()
        nameLabel.text = roleName
        nameLabel.font = UIFont(name: "Aclonica-Regular", size: 15)
        nameLabel.textColor = .white
        nameLabel.textAlignment = .center
        
        let descLabel = UILabel()
        descLabel.text = roleDesc
        descLabel.font = UIFont(name: "Aclonica-Regular", size: 11)
        descLabel.textColor = UIColor.white.withAlphaComponent(0.7)
        descLabel.textAlignment = .center
        descLabel.numberOfLines = 0
        
        let stack = UIStackView(arrangedSubviews: [emojiLabel, nameLabel, descLabel])
        stack.axis = .vertical
        stack.spacing = 6
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        box.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: box.leadingAnchor, constant: 10),
            stack.trailingAnchor.constraint(equalTo: box.trailingAnchor, constant: -10),
            stack.topAnchor.constraint(equalTo: box.topAnchor, constant: 14),
            stack.bottomAnchor.constraint(equalTo: box.bottomAnchor, constant: -14)
        ])
        
        return box
    }
}
