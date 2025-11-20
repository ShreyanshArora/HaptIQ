import UIKit
import FirebaseFirestore

class EnterNameViewController: UIViewController {
    private let roomCode: String
    private let isCreator: Bool
    private let gradientLayer = CAGradientLayer()

    init(roomCode: String, isCreator: Bool) {
        self.roomCode = roomCode
        self.isCreator = isCreator
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private let nameField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Your name"
        tf.font = UIFont(name: "Aclonica-Regular", size: 22)
        tf.backgroundColor = .white
        tf.layer.cornerRadius = 12
        tf.textAlignment = .center
        tf.textColor = .black
        tf.heightAnchor.constraint(equalToConstant: 48).isActive = true
        tf.widthAnchor.constraint(equalToConstant: 220).isActive = true
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    private let moveButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("MOVE TO LOBBY", for: .normal)
        b.backgroundColor = UIColor(red: 21/255, green: 174/255, blue: 21/255, alpha: 1.0)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = UIFont(name: "Aclonica-Regular", size: 22)
        b.layer.cornerRadius = 18
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBlue
        view.addSubview(nameField)
        view.addSubview(moveButton)
        setupConstraints()
        moveButton.addTarget(self, action: #selector(moveTapped), for: .touchUpInside)
    }

    private func setupConstraints() {
        nameField.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        nameField.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        moveButton.topAnchor.constraint(equalTo: nameField.bottomAnchor, constant: 28).isActive = true
        moveButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    }

    @objc private func moveTapped() {
        guard let name = nameField.text, !name.isEmpty else { return }

        if isCreator {
            // creator should update their existing host player doc (currentUserID was set at createRoom)
            let hostID = RoomManager.shared.currentUserID
            Firestore.firestore()
                .collection("rooms")
                .document(roomCode)
                .collection("players")
                .document(hostID)
                .setData(["name": name, "isHost": true], merge: true) { _ in
                    self.goToLobby()
                }
            return
        }

        // joiner: create new player doc & update currentUserID
        let uid = UUID().uuidString
        RoomManager.shared.currentUserID = uid
        RoomManager.shared.addPlayer(id: uid, name: name, isHost: false, to: roomCode) { _ in
            self.goToLobby()
        }
    }

    private func goToLobby() {
        DispatchQueue.main.async {
            let vc = RoomLobbyViewController(roomCode: self.roomCode)
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
}
