import UIKit

class RoomCodeEntryViewController: UIViewController {

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
        l.font = UIFont(name: "WinniePERSONALUSE", size: 40)
        l.textColor = .white
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        l.transform = CGAffineTransform(rotationAngle: -0.2)
        return l
    }()

    // MARK: - Card Container
    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 10/255, green: 30/255, blue: 60/255, alpha: 0.95)
        v.layer.cornerRadius = 30
        v.layer.borderWidth = 3
        v.layer.borderColor = UIColor.white.cgColor
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let roomCodeLabel: UILabel = {
        let l = UILabel()
        l.text = "Room Code"
        l.font = UIFont(name: "WinniePERSONALUSE", size: 36)
        l.textColor = .white
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let codeTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "8a2c9"
        tf.font = UIFont(name: "WinniePERSONALUSE", size: 32)
        tf.textAlignment = .center
        tf.textColor = UIColor(red: 10/255, green: 30/255, blue: 60/255, alpha: 1)
        tf.backgroundColor = UIColor(red: 100/255, green: 180/255, blue: 255/255, alpha: 1)
        tf.layer.cornerRadius = 20
        tf.layer.borderWidth = 3
        tf.layer.borderColor = UIColor.white.cgColor
        tf.autocapitalizationType = .allCharacters
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    private let nextButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Next", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = UIFont(name: "WinniePERSONALUSE", size: 32)
        b.layer.cornerRadius = 20
        b.layer.borderColor = UIColor.white.cgColor
        b.layer.borderWidth = 3
        b.backgroundColor = UIColor(red: 0/255, green: 200/255, blue: 80/255, alpha: 1)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(false, animated: false)
        setupBackButton()
        setupLayout()
        setupActions()
        
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

    // MARK: - Layout
    private func setupLayout() {
        view.addSubview(backgroundImage)
        view.addSubview(cardView)
        view.addSubview(leftCharacter)
        view.addSubview(rightCharacter)
        view.addSubview(titleBanner)
        view.addSubview(titleLabel)
        
        // Send background to back
        view.sendSubviewToBack(backgroundImage)
        
        cardView.addSubview(roomCodeLabel)
        cardView.addSubview(codeTextField)
        cardView.addSubview(nextButton)

        NSLayoutConstraint.activate([
            // Background
            backgroundImage.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImage.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImage.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImage.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Left Character - bigger size
            leftCharacter.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: -30),
            leftCharacter.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),
            leftCharacter.widthAnchor.constraint(equalToConstant: 280),
            leftCharacter.heightAnchor.constraint(equalToConstant: 460),

            // Right Character - bigger size
            rightCharacter.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 50),
            rightCharacter.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 140),
            rightCharacter.widthAnchor.constraint(equalToConstant: 240),
            rightCharacter.heightAnchor.constraint(equalToConstant: 400),

            // Title banner - smaller and higher
            titleBanner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleBanner.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            titleBanner.widthAnchor.constraint(equalToConstant: 300),
            titleBanner.heightAnchor.constraint(equalToConstant: 110),

            // Title text
            titleLabel.centerXAnchor.constraint(equalTo: titleBanner.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: titleBanner.centerYAnchor),

            // Card View
            cardView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cardView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 50),
            cardView.widthAnchor.constraint(equalToConstant: 340),
            cardView.heightAnchor.constraint(equalToConstant: 340),

            // Room Code Label
            roomCodeLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 30),
            roomCodeLabel.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),

            // Code Text Field
            codeTextField.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            codeTextField.centerYAnchor.constraint(equalTo: cardView.centerYAnchor, constant: 10),
            codeTextField.widthAnchor.constraint(equalToConstant: 260),
            codeTextField.heightAnchor.constraint(equalToConstant: 60),

            // Next Button
            nextButton.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            nextButton.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -30),
            nextButton.widthAnchor.constraint(equalToConstant: 260),
            nextButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }

    // MARK: - Actions
    private func setupActions() {
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
    }

    @objc private func nextTapped() {
        guard let code = codeTextField.text?.trimmingCharacters(in: .whitespaces), !code.isEmpty else {
            showError(message: "Please enter a room code")
            return
        }

        // Validate room code with RoomManager
        RoomManager.shared.joinRoom(withCode: code) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    // Navigate to EnterNameViewController
                    let vc = EnterNameViewController(roomCode: code, isCreator: false)
                    self?.navigationController?.pushViewController(vc, animated: true)
                case .failure(let error):
                    self?.showError(message: "Invalid room code. Please try again.")
                    print("Join Err:", error)
                }
            }
        }
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    private func showError(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
