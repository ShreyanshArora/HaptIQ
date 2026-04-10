import UIKit
import FirebaseFirestore

final class TapGuessViewController: UIViewController, GuessEvaluationDelegate {

    // MARK: - Properties
    private let roomCode: String
    private let rumbleCount: Int
    private let myRole: HapticsRoomViewController.PlayerRole
    private var players: [RoomManager.Player]
    private var currentRound: Int
    private let selectedAvatar: AvatarPage?

    private var myTapCount = 0
    private let db = Firestore.firestore()
    private var hasSubmitted = false
    
    /// Manages all host evaluation, Firebase sync, and navigation
    private var evaluationManager: GuessEvaluationManager?

    // MARK: - UI Components
    private let bgImage: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "tapScreenBg"))
        iv.contentMode = .scaleAspectFill
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Tap Round"
        l.font = UIFont(name: "Aclonica-Regular", size: 36)
        l.textColor = .white
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.text = "Trust your touch, tap every haptics you feel"
        l.font = UIFont(name: "Aclonica-Regular", size: 14)
        l.textColor = UIColor.white.withAlphaComponent(0.8)
        l.textAlignment = .center
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let circlesContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let profileImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.layer.cornerRadius = 60
        iv.layer.borderWidth = 3
        iv.layer.borderColor = UIColor.cyan.cgColor
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.image = UIImage(named: "defaultProfile") ?? UIImage(systemName: "person.circle.fill")
        iv.tintColor = .white
        return iv
    }()
    
    private let counterContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let decrementButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("−", for: .normal)
        b.titleLabel?.font = UIFont.systemFont(ofSize: 40, weight: .light)
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        b.layer.cornerRadius = 30
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()
    
    private let counterLabel: UILabel = {
        let l = UILabel()
        l.text = "0"
        l.font = UIFont(name: "Aclonica-Regular", size: 48)
        l.textColor = .white
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let incrementButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("+", for: .normal)
        b.titleLabel?.font = UIFont.systemFont(ofSize: 40, weight: .light)
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        b.layer.cornerRadius = 30
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private let submitButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Next", for: .normal)
        b.titleLabel?.font = UIFont(name: "Aclonica-Regular", size: 22)
        b.backgroundColor = UIColor(red: 21/255, green: 174/255, blue: 21/255, alpha: 1)
        b.setTitleColor(.white, for: .normal)
        b.layer.cornerRadius = 27.5
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    // MARK: - Initializer
    init(roomCode: String,
         rumbleCount: Int,
         myRole: HapticsRoomViewController.PlayerRole,
         players: [RoomManager.Player],
         currentRound: Int = 1,
         selectedAvatar: AvatarPage? = nil) {
        self.roomCode = roomCode
        self.rumbleCount = rumbleCount
        self.myRole = myRole
        self.players = players
        self.currentRound = currentRound
        self.selectedAvatar = selectedAvatar
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) not allowed") }

    deinit {
        evaluationManager?.cleanup()
        evaluationManager = nil
        print("🗑️ TapGuessViewController deallocated")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        
        layoutUI()
        setupButtonActions()
        loadUserProfile()
        
        print("📱 TapGuessViewController loaded - Round \(currentRound), Players: \(players.count), Expected: \(rumbleCount)")
        print("👑 Am I host? \(RoomManager.shared.isHost)")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        evaluationManager?.cleanup()
        print("🛑 TapGuessViewController will disappear")
    }
    
    // MARK: - Profile Loading
    private func loadUserProfile() {
        if let avatar = selectedAvatar, let img = UIImage(named: avatar.imageName) {
            profileImageView.image = img
        } else if let avatar = selectedAvatar, let img = UIImage(named: avatar.lobbyImageName) {
            profileImageView.image = img
        }
    }
    
    // MARK: - Button Setup
    private func setupButtonActions() {
        incrementButton.addTarget(self, action: #selector(incrementTapped), for: .touchUpInside)
        decrementButton.addTarget(self, action: #selector(decrementTapped), for: .touchUpInside)
        submitButton.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(profileTapped))
        profileImageView.addGestureRecognizer(tapGesture)
        profileImageView.isUserInteractionEnabled = true
    }

    // MARK: - UI Layout
    private func layoutUI() {
        view.addSubview(bgImage)
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(circlesContainer)
        view.addSubview(counterContainer)
        view.addSubview(submitButton)
        
        circlesContainer.addSubview(profileImageView)
        counterContainer.addSubview(decrementButton)
        counterContainer.addSubview(counterLabel)
        counterContainer.addSubview(incrementButton)

        NSLayoutConstraint.activate([
            bgImage.topAnchor.constraint(equalTo: view.topAnchor),
            bgImage.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bgImage.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bgImage.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),

            circlesContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            circlesContainer.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 40),
            circlesContainer.widthAnchor.constraint(equalToConstant: 380),
            circlesContainer.heightAnchor.constraint(equalToConstant: 380),
            
            profileImageView.centerXAnchor.constraint(equalTo: circlesContainer.centerXAnchor),
            profileImageView.centerYAnchor.constraint(equalTo: circlesContainer.centerYAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 120),
            profileImageView.heightAnchor.constraint(equalToConstant: 120),
            
            counterContainer.topAnchor.constraint(equalTo: circlesContainer.bottomAnchor, constant: 15),
            counterContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            counterContainer.heightAnchor.constraint(equalToConstant: 60),
            
            decrementButton.leadingAnchor.constraint(equalTo: counterContainer.leadingAnchor),
            decrementButton.centerYAnchor.constraint(equalTo: counterContainer.centerYAnchor),
            decrementButton.widthAnchor.constraint(equalToConstant: 60),
            decrementButton.heightAnchor.constraint(equalToConstant: 60),
            
            counterLabel.centerXAnchor.constraint(equalTo: counterContainer.centerXAnchor),
            counterLabel.centerYAnchor.constraint(equalTo: counterContainer.centerYAnchor),
            counterLabel.leadingAnchor.constraint(equalTo: decrementButton.trailingAnchor, constant: 30),
            counterLabel.trailingAnchor.constraint(equalTo: incrementButton.leadingAnchor, constant: -30),
            
            incrementButton.trailingAnchor.constraint(equalTo: counterContainer.trailingAnchor),
            incrementButton.centerYAnchor.constraint(equalTo: counterContainer.centerYAnchor),
            incrementButton.widthAnchor.constraint(equalToConstant: 60),
            incrementButton.heightAnchor.constraint(equalToConstant: 60),

            submitButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            submitButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            submitButton.widthAnchor.constraint(equalToConstant: 340),
            submitButton.heightAnchor.constraint(equalToConstant: 55)
        ])
    }

    // MARK: - Button Actions
    @objc private func incrementTapped() {
        myTapCount += 1
        counterLabel.text = "\(myTapCount)"
        HapticsEngineManager.shared.playRumble()
    }
    
    @objc private func decrementTapped() {
        guard myTapCount > 0 else { return }
        myTapCount -= 1
        counterLabel.text = "\(myTapCount)"
        HapticsEngineManager.shared.playRumble()
    }
    
    @objc private func profileTapped() {
        myTapCount += 1
        counterLabel.text = "\(myTapCount)"
        HapticsEngineManager.shared.playRumble()
    }

    // MARK: - Submit Guess
    @objc private func submitTapped() {
        guard !hasSubmitted else { return }
        hasSubmitted = true
        
        let uid = RoomManager.shared.currentUserID
        
        print("🔵 SUBMIT - User: \(String(uid.prefix(8))), Taps: \(myTapCount), Expected: \(rumbleCount)")
        
        submitButton.isEnabled = false
        submitButton.alpha = 0.6
        submitButton.setTitle("Waiting...", for: .normal)
        
        let waitingSince = Date().timeIntervalSince1970

        db.collection("rooms")
            .document(roomCode)
            .collection("guesses")
            .document(uid)
            .setData([
                "tapCount": myTapCount,
                "playerID": uid,
                "round": currentRound,
                "timestamp": FieldValue.serverTimestamp()
            ]) { [weak self] error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Submit error: \(error)")
                    self.hasSubmitted = false
                    self.submitButton.isEnabled = true
                    self.submitButton.alpha = 1.0
                    self.submitButton.setTitle("Next", for: .normal)
                    return
                }
                
                print("✅ Guess submitted")
                
                // Hand off to the evaluation manager
                self.evaluationManager = GuessEvaluationManager(
                    roomCode: self.roomCode,
                    rumbleCount: self.rumbleCount,
                    players: self.players,
                    currentRound: self.currentRound,
                    myRole: self.myRole,
                    selectedAvatar: self.selectedAvatar,
                    navigationController: self.navigationController
                )
                self.evaluationManager?.delegate = self
                self.evaluationManager?.startListening(waitingSince: waitingSince)
            }
    }
    
    // MARK: - GuessEvaluationDelegate
    func evaluationDidNavigate() {
        // Manager has handled navigation — nothing to do here
        print("✅ Evaluation manager handled navigation")
    }
}
