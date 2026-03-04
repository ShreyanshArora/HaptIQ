import UIKit

final class AvatarSelectionController: UIPageViewController {

    // MARK: - Data with separate images for selection and lobby
    private let pages: [AvatarPage] = [
        AvatarPage(lobbyImageName: "char1_lobby", imageName: "char1", title: "Shadow Hacker"),
        AvatarPage(lobbyImageName: "char2_lobby", imageName: "char2", title: "Cyber Tank"),
        AvatarPage(lobbyImageName: "char3_lobby", imageName: "char3", title: "Blade Dancer"),
        AvatarPage(lobbyImageName: "char4_lobby", imageName: "char4", title: "Tech Genius"),
        AvatarPage(lobbyImageName: "char5_lobby", imageName: "char5", title: "Stealth Ninja"),
        AvatarPage(lobbyImageName: "char6_lobby", imageName: "char6", title: "Mecha Beast")
    ]

    private lazy var controllers: [AvatarPageVC] = pages.map { AvatarPageVC(page: $0) }

    // MARK: - UI Components
    private let titleLabel = UILabel()
    private let pageControl = UIPageControl()
    private let leftButton = UIButton(type: .system)
    private let rightButton = UIButton(type: .system)
    private let continueButton = UIButton(type: .system)
    private let gradientLayer = CAGradientLayer()
    private let leftDecorImageView = UIImageView()
    private let rightDecorImageView = UIImageView()

    var onContinue: ((AvatarPage) -> Void)?
    
    // MARK: - Initialization
    init() {
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
    }
    
    required init?(coder: NSCoder) {
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
    }

    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        dataSource = self
        delegate = self

        setupGradient()
        setupInitialPage()
        setupTitleLabel()
        setupDecorativeImages()
        setupPageControl()
        setupButtons()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds
    }

    // MARK: - Gradient
    private func setupGradient() {
        gradientLayer.colors = [
            UIColor(red: 6/255, green: 27/255, blue: 53/255, alpha: 1).cgColor,
            UIColor(red: 18/255, green: 57/255, blue: 99/255, alpha: 1).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        view.layer.insertSublayer(gradientLayer, at: 0)
    }

    // MARK: - Setup Initial Page
    private func setupInitialPage() {
        setViewControllers([controllers[0]], direction: .forward, animated: false)
        pageControl.numberOfPages = pages.count
        pageControl.currentPage = 0
    }

    // MARK: - Title Label
    private func setupTitleLabel() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Select Your Avatar"
        titleLabel.font = UIFont(name: "Aclonica-Regular", size: 28)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        
        view.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    // MARK: - Decorative Images
    private func setupDecorativeImages() {
        leftDecorImageView.translatesAutoresizingMaskIntoConstraints = false
        leftDecorImageView.image = UIImage(named: "square")
        leftDecorImageView.contentMode = .scaleAspectFit
        leftDecorImageView.alpha = 1
        
        rightDecorImageView.translatesAutoresizingMaskIntoConstraints = false
        rightDecorImageView.image = UIImage(named: "square1")
        rightDecorImageView.contentMode = .scaleAspectFit
        rightDecorImageView.alpha = 1
        
        view.addSubview(leftDecorImageView)
        view.addSubview(rightDecorImageView)
        
        NSLayoutConstraint.activate([
            leftDecorImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: -25),
            leftDecorImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            leftDecorImageView.widthAnchor.constraint(equalToConstant: 90),
            leftDecorImageView.heightAnchor.constraint(equalToConstant: 90),
            
            rightDecorImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 25),
            rightDecorImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 80),
            rightDecorImageView.widthAnchor.constraint(equalToConstant: 90),
            rightDecorImageView.heightAnchor.constraint(equalToConstant: 90)
        ])
    }

    // MARK: - Page Control
    private func setupPageControl() {
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        pageControl.currentPageIndicatorTintColor = .white
        pageControl.pageIndicatorTintColor = UIColor.white.withAlphaComponent(0.3)

        view.addSubview(pageControl)

        NSLayoutConstraint.activate([
            pageControl.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    // MARK: - Buttons
    private func setupButtons() {
        leftButton.translatesAutoresizingMaskIntoConstraints = false
        rightButton.translatesAutoresizingMaskIntoConstraints = false
        continueButton.translatesAutoresizingMaskIntoConstraints = false

        leftButton.setTitle("‹", for: .normal)
        leftButton.titleLabel?.font = UIFont.systemFont(ofSize: 34, weight: .bold)
        leftButton.tintColor = .white
        leftButton.addTarget(self, action: #selector(goPrevious), for: .touchUpInside)

        rightButton.setTitle("›", for: .normal)
        rightButton.titleLabel?.font = UIFont.systemFont(ofSize: 34, weight: .bold)
        rightButton.tintColor = .white
        rightButton.addTarget(self, action: #selector(goNext), for: .touchUpInside)

        continueButton.setTitle("Continue", for: .normal)
        continueButton.setTitleColor(.white, for: .normal)
        continueButton.backgroundColor = UIColor(red: 0.10, green: 0.45, blue: 1.0, alpha: 1)
        continueButton.layer.cornerRadius = 20
        continueButton.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)

        view.addSubview(leftButton)
        view.addSubview(rightButton)
        view.addSubview(continueButton)

        NSLayoutConstraint.activate([
            leftButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            leftButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),

            rightButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            rightButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),

            continueButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            continueButton.bottomAnchor.constraint(equalTo: pageControl.topAnchor, constant: -20),
            continueButton.widthAnchor.constraint(equalToConstant: 220),
            continueButton.heightAnchor.constraint(equalToConstant: 46)
        ])
    }

    // MARK: - Helpers
    private func currentIndex() -> Int {
        guard let vc = viewControllers?.first as? AvatarPageVC else { return 0 }
        return controllers.firstIndex(of: vc) ?? 0
    }

    // MARK: - Button Actions
    @objc private func goPrevious() {
        let idx = currentIndex()
        let newIdx = idx == 0 ? controllers.count - 1 : idx - 1
        setViewControllers([controllers[newIdx]], direction: .reverse, animated: true)
        pageControl.currentPage = newIdx
    }

    @objc private func goNext() {
        let idx = currentIndex()
        let newIdx = idx == controllers.count - 1 ? 0 : idx + 1
        setViewControllers([controllers[newIdx]], direction: .forward, animated: true)
        pageControl.currentPage = newIdx
    }

    @objc private func continueTapped() {
        let idx = currentIndex()
        let selectedAvatar = pages[idx]
        
        // Save LOBBY image name to UserDefaults (this will be shown in room lobby)
        UserDefaults.standard.set(selectedAvatar.lobbyImageName, forKey: "selectedAvatarImage")
        UserDefaults.standard.set(selectedAvatar.title, forKey: "selectedAvatarTitle")
        
        // Navigate to the next screen
        let nextVC = JoinRoomViewController()
        navigationController?.pushViewController(nextVC, animated: true)
    }
}

// MARK: - Data Source
extension AvatarSelectionController: UIPageViewControllerDataSource {

    func pageViewController(_ pvc: UIPageViewController,
                            viewControllerBefore vc: UIViewController) -> UIViewController? {
        guard let current = vc as? AvatarPageVC,
              let idx = controllers.firstIndex(of: current) else { return nil }
        
        if idx == 0 {
            return controllers[controllers.count - 1]
        }
        return controllers[idx - 1]
    }

    func pageViewController(_ pvc: UIPageViewController,
                            viewControllerAfter vc: UIViewController) -> UIViewController? {
        guard let current = vc as? AvatarPageVC,
              let idx = controllers.firstIndex(of: current) else { return nil }
        
        if idx == controllers.count - 1 {
            return controllers[0]
        }
        return controllers[idx + 1]
    }
}

// MARK: - Delegate
extension AvatarSelectionController: UIPageViewControllerDelegate {

    func pageViewController(_ pvc: UIPageViewController,
                            didFinishAnimating finished: Bool,
                            previousViewControllers: [UIViewController],
                            transitionCompleted completed: Bool) {

        if completed {
            pageControl.currentPage = currentIndex()
        }
    }
}
