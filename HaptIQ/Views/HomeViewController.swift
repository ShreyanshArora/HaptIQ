import UIKit

class HomeViewController: UIViewController {
    
    private let gradientLayer = CAGradientLayer()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        setupGradientBackground()
        setupLightningOverlay()
        setupIconImage()
        redirectToNextScreen()

    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds
    }
    private func redirectToNextScreen() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            let vc = HapticHuntLogo()   // next screen
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
    
    // MARK: - Lightning Image
    private func setupLightningOverlay() {
        let lightning = UIImageView(image: UIImage(named: "Thunder"))
//        lightning.image = UIImage(named: "Thunder")?.withRenderingMode(.alwaysTemplate)
//        lightning.tintColor = UIColor(red: 100/255, green: 200/255, blue: 255/255, alpha: 0.8)// add PNG in Assets
        lightning.contentMode = .scaleAspectFit
        lightning.alpha = 0.3
        lightning.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(lightning)
        
        NSLayoutConstraint.activate([
            lightning.centerXAnchor.constraint(equalTo: view.centerXAnchor ,constant: 90),
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

