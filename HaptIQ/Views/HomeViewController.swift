import UIKit

class HomeViewController: UIViewController {
    
    // MARK: - UI Components
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(named: "Mafia")
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = UIColor(red: 0.8, green: 0.1, blue: 0.1, alpha: 1.0)
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Haptic Hunt"
        label.font = UIFont(name: "WinniePERSONALUSE", size: 65)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Trust no one. Outsmart your friends"
        label.font = UIFont(name: "WinniePERSONALUSE", size: 25)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let progressView: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .default)
        progress.trackTintColor = UIColor.white.withAlphaComponent(0.3)
        progress.progressTintColor = .white
        progress.translatesAutoresizingMaskIntoConstraints = false
        progress.layer.cornerRadius = 4
        progress.clipsToBounds = true
        progress.transform = CGAffineTransform(scaleX: 1.0, y: 2.0)
        return progress
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.text = "Scanning for imposter..."
        label.font = UIFont(name: "WinniePERSONALUSE", size: 20)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Properties
    private var progressTimer: Timer?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        startLoadingAnimation()
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        // Gradient background
        let gradient = CAGradientLayer()
        gradient.frame = view.bounds
        gradient.colors = [
            UIColor(red: 1.0, green: 0.5, blue: 0.3, alpha: 1.0).cgColor,
            UIColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 1.0).cgColor
        ]
        gradient.startPoint = CGPoint(x: 0.5, y: 0)
        gradient.endPoint = CGPoint(x: 0.5, y: 1)
        view.layer.insertSublayer(gradient, at: 0)
        
        // Add subviews
        [iconImageView, titleLabel, subtitleLabel, progressView, statusLabel].forEach { view.addSubview($0) }
        
        // Constraints
        NSLayoutConstraint.activate([
            iconImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            iconImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 80),
            iconImageView.widthAnchor.constraint(equalToConstant: 150),
            iconImageView.heightAnchor.constraint(equalToConstant: 150),
            
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 40),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            subtitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            progressView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            progressView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 40),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 60),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -60),
            progressView.heightAnchor.constraint(equalToConstant: 8),
            
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 20),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
        ])
    }
    
    private func startLoadingAnimation() {
        progressView.progress = 0.0
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { [weak self] timer in
            guard let self = self else { timer.invalidate(); return }
            if self.progressView.progress < 1.0 {
                self.progressView.progress += 0.01
            } else {
                timer.invalidate()
                self.loadingComplete()
            }
        }
        
        // Pulse icon
        let pulse = CABasicAnimation(keyPath: "transform.scale")
        pulse.duration = 1.5
        pulse.fromValue = 1.0
        pulse.toValue = 1.1
        pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        pulse.autoreverses = true
        pulse.repeatCount = .infinity
        iconImageView.layer.add(pulse, forKey: "pulse")
        
        // Fade status label
        UIView.animate(withDuration: 1.0, delay: 0, options: [.repeat, .autoreverse]) {
            self.statusLabel.alpha = 0.6
        }
    }
    
    private func loadingComplete() {
        statusLabel.text = "Ready to hunt!"
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Navigate to main screen after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.showMainScreen()
        }
    }
    
    private func showMainScreen() {
        // Replace this with your actual main view controller
        let mainVC = UIViewController()
        mainVC.view.backgroundColor = .systemBackground
        mainVC.title = "Main Screen"
        
      
        navigationController?.setViewControllers([mainVC], animated: true)
    }
    
    // MARK: - Cleanup
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        progressTimer?.invalidate()
        progressTimer = nil
    }
    
    deinit {
        progressTimer?.invalidate()
    }
}

