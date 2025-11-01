import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        for family in UIFont.familyNames {
            print("Family: \(family)")
            for name in UIFont.fontNames(forFamilyName: family) {
                print("   \(name)")
            }
        }
        
        let label = UILabel()
        label.text = "Hello, Custom Font!"
        label.font = UIFont(name: "WinniePERSONALUSE", size: 28)
        label.textColor = .systemPink
        label.frame = CGRect(x: 40, y: 100, width: 350, height: 50)
        view.addSubview(label)
    }
}

