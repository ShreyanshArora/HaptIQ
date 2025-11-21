import UIKit
import FirebaseFirestore

class EnterNameViewController: UIViewController {
    private let roomCode: String
    private let isCreator: Bool

    init(roomCode: String, isCreator: Bool) {
        self.roomCode = roomCode
        self.isCreator = isCreator
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    // MARK: - Background
    private let backgroundImage: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "bghex"))
        iv.contentMode = .scaleAspectFill
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Enter Your Name"
        l.font = UIFont(name: "Aclonica-Regular", size: 36)
        l.textColor = .white
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let nameField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "shreyansh"
        tf.font = UIFont(name: "Aclonica-Regular", size: 28)
        tf.backgroundColor = UIColor(red: 100/255, green: 180/255, blue: 255/255, alpha: 1)
        tf.layer.cornerRadius = 20
        tf.layer.borderWidth = 3
        tf.layer.borderColor = UIColor.white.cgColor
        tf.textAlignment = .center
        tf.textColor = UIColor(red: 10/255, green: 30/255, blue: 60/255, alpha: 1)
        tf.translatesAutoresizingMaskIntoConstraints = false
        
        // Add padding
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: tf.frame.height))
        tf.leftView = paddingView
        tf.leftViewMode = .always
        tf.rightView = paddingView
        tf.rightViewMode = .always
        
        return tf
    }()

    private let continueButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Continue", for: .normal)
        b.backgroundColor = UIColor(red: 100/255, green: 180/255, blue: 255/255, alpha: 1)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = UIFont(name: "Aclonica-Regular", size: 32)
        b.layer.cornerRadius = 25
        b.layer.borderWidth = 3
        b.layer.borderColor = UIColor.white.cgColor
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(false, animated: false)
        setupBackButton()
        setupUI()
        setupConstraints()
        continueButton.addTarget(self, action: #selector(moveTapped), for: .touchUpInside)
        
        // Dismiss keyboard on tap
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Back Button
    private func setupBackButton() {
        let backButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )
        backButton.tintColor = .white
        navigationItem.leftBarButtonItem = backButton
    }

    private func setupUI() {
        view.addSubview(backgroundImage)
        view.addSubview(titleLabel)
        view.addSubview(nameField)
        view.addSubview(continueButton)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Background
            backgroundImage.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImage.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImage.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImage.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Title
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 180),
            
            // Name Field
            nameField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            nameField.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50),
            nameField.widthAnchor.constraint(equalToConstant: 320),
            nameField.heightAnchor.constraint(equalToConstant: 60),
            
            // Continue Button
            continueButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -60),
            continueButton.widthAnchor.constraint(equalToConstant: 280),
            continueButton.heightAnchor.constraint(equalToConstant: 70)
        ])
    }

    @objc private func moveTapped() {
        guard let name = nameField.text, !name.isEmpty else {
            showError(message: "Please enter your name")
            return
        }

        // Get selected avatar from UserDefaults
        let avatarImage = UserDefaults.standard.string(forKey: "selectedAvatarImage") ?? "char1"
        let avatarTitle = UserDefaults.standard.string(forKey: "selectedAvatarTitle") ?? "Shadow Hacker"

        if isCreator {
            // creator should update their existing host player doc
            let hostID = RoomManager.shared.currentUserID
            Firestore.firestore()
                .collection("rooms")
                .document(roomCode)
                .collection("players")
                .document(hostID)
                .setData([
                    "name": name,
                    "isHost": true,
                    "avatarImage": avatarImage,
                    "avatarTitle": avatarTitle
                ], merge: true) { _ in
                    self.goToLobby()
                }
            return
        }

        // joiner: create new player doc & update currentUserID
        let uid = UUID().uuidString
        RoomManager.shared.currentUserID = uid
        
        // Updated addPlayer call with avatar data
        Firestore.firestore()
            .collection("rooms")
            .document(roomCode)
            .collection("players")
            .document(uid)
            .setData([
                "name": name,
                "isHost": false,
                "avatarImage": avatarImage,
                "avatarTitle": avatarTitle
            ]) { _ in
                self.goToLobby()
            }
    }

    private func goToLobby() {
        DispatchQueue.main.async {
            let vc = RoomLobbyViewController(roomCode: self.roomCode)
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func showError(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
