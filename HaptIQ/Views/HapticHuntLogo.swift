import UIKit

class HapticHuntLogo: UIViewController {
    
    private let gradientLayer = CAGradientLayer()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        setupGradientBackground()
        setupLightningOverlay()
        setupIconImage()
        setupTiltedHapticHuntLogo()
        redirectToNextScreen()

    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds
    }
    private func redirectToNextScreen() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            let vc = OnboardingController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)   // next screen
            vc.modalPresentationStyle = .fullScreen
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }

    // MARK: - Gradient Background
    private func setupGradientBackground() {
        gradientLayer.colors = [
            UIColor(red: 5/255, green: 10/255, blue: 35/255, alpha: 1).cgColor,
            UIColor(red: 20/255, green: 45/255, blue: 120/255, alpha: 1).cgColor
        ]
        gradientLayer.locations = [0, 1]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        
        view.layer.insertSublayer(gradientLayer, at: 0)
        
        // Rounded screen corners
        view.layer.cornerRadius = 40
        view.layer.masksToBounds = true
    }
    
    private func setupTiltedHapticHuntLogo() {

        let logoView = UIView()
        logoView.translatesAutoresizingMaskIntoConstraints = false
        logoView.layer.cornerRadius = 30
        logoView.layer.masksToBounds = true

        logoView.layer.shadowColor = UIColor.black.cgColor
        logoView.layer.shadowOpacity = 0.4
        logoView.layer.shadowRadius = 10
        logoView.layer.shadowOffset = CGSize(width: 0, height: 6)

        let gradient = CAGradientLayer()
        gradient.colors = [
               UIColor(red: 10/255, green: 20/255, blue: 60/255, alpha: 1).cgColor,  // dark navy
               UIColor(red: 40/255, green: 80/255, blue: 200/255, alpha: 1).cgColor, // mid blue
               UIColor(red: 120/255, green: 170/255, blue: 255/255, alpha: 1).cgColor // bright sky blue
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint   = CGPoint(x: 1, y: 0.5)
        gradient.cornerRadius = 30
        gradient.frame = CGRect(x: 0, y: 0, width: 300, height: 70) // temporary
        logoView.layer.insertSublayer(gradient, at: 0)

        let title = UILabel()
        title.translatesAutoresizingMaskIntoConstraints = false
        title.text = "HaPtIc HuNt"
        title.textAlignment = .center
        title.textColor = .white
        title.font = UIFont(name: "Aclonica-Regular", size: 39) // your font

        // Add views
        view.addSubview(logoView)
        logoView.addSubview(title)

        // Constraints (Position + Size)
        NSLayoutConstraint.activate([
            logoView.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 10), // slight right
            logoView.topAnchor.constraint(equalTo: view.centerYAnchor, constant: 30),

            logoView.widthAnchor.constraint(equalToConstant: 280),
            logoView.heightAnchor.constraint(equalToConstant: 70),

            title.centerXAnchor.constraint(equalTo: logoView.centerXAnchor),
            title.centerYAnchor.constraint(equalTo: logoView.centerYAnchor)
        ])

        // 5️⃣ Tilt the entire capsule
        logoView.transform = CGAffineTransform(rotationAngle: -8 * (.pi / 180))
    }

    private func setupLightningOverlay() {
        let lightning = UIImageView(image: UIImage(named: "Thunder"))
//        lightning.image = UIImage(named: "Thunder")?.withRenderingMode(.alwaysTemplate)
//        lightning.tintColor = UIColor(red: 100/255, green: 200/255, blue: 255/255, alpha: 0.8)// add PNG in Assets
        lightning.contentMode = .scaleAspectFit
        lightning.alpha = 0.3
        lightning.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(lightning)
        
        NSLayoutConstraint.activate([
            lightning.centerXAnchor.constraint(equalTo: view.centerXAnchor ,constant: 80),
            lightning.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 10),
            lightning.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9),
            lightning.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.7)
        ])
    }
    
    // MARK: - App Icon
    private func setupIconImage() {
        let icon = UIImageView(image: UIImage(named: "Logo")) // add your skull icon here
        icon.contentMode = .scaleAspectFit
        icon.clipsToBounds = true
        icon.layer.cornerRadius = 28
        
        icon.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(icon)
        
        NSLayoutConstraint.activate([
            icon.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -60),
            icon.widthAnchor.constraint(equalToConstant: 200),
            icon.heightAnchor.constraint(equalToConstant: 180)
        ])
    }
}


