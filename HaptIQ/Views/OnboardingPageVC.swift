import UIKit

class OnboardingPageVC: UIViewController {

    private let page: OnboardingPage
    
    init(page: OnboardingPage) {
        self.page = page
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("") }
    
    private let imgView = UIImageView()
    private let label = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Let the content go under the notch
        self.edgesForExtendedLayout = .all
        self.extendedLayoutIncludesOpaqueBars = true
        
        view.backgroundColor = .black
        setupUI()
    }
    
    private func setupUI() {
        // IMAGE VIEW
        imgView.translatesAutoresizingMaskIntoConstraints = false
        imgView.image = UIImage(named: page.imageName)
        imgView.contentMode = .scaleAspectFill
        imgView.clipsToBounds = true
        
        // LABEL
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = page.text
        label.font = UIFont(name: "Aclonica-Regular", size: 22)
        label.textColor = .white
        label.numberOfLines = 0
        label.textAlignment = .center
        
        view.addSubview(imgView)
        view.addSubview(label)
        
        NSLayoutConstraint.activate([
            // IMAGE FULL TOP
            imgView.topAnchor.constraint(equalTo: view.topAnchor),          
            imgView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imgView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imgView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.55),

            // LABEL AT BOTTOM
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            label.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -130)
        ])
    }
}

