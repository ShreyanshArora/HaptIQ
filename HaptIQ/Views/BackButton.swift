import UIKit

extension UIViewController {
    @discardableResult
    func addFigmaBackButton() -> UIButton {
        let back = UIButton(type: .system)
        back.translatesAutoresizingMaskIntoConstraints = false
        back.backgroundColor = UIColor(red: 0.69, green: 0.03, blue: 0.03, alpha: 0.85) 
        back.layer.cornerRadius = 21
        back.tintColor = .white
        back.setImage(UIImage(systemName: "chevron.left"), for: .normal)

        view.addSubview(back)
        NSLayoutConstraint.activate([
            back.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 36),
            back.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            back.widthAnchor.constraint(equalToConstant: 43),
            back.heightAnchor.constraint(equalToConstant: 42)
        ])
        back.addTarget(self, action: #selector(figmaBackTapped), for: .touchUpInside)
        return back
    }

    @objc func figmaBackTapped() {
        if let nav = navigationController, nav.viewControllers.count > 1 {
            nav.popViewController(animated: true)
        } else if presentingViewController != nil {
            dismiss(animated: true)
        } else {
            // root screen: do nothing
        }
    }
}
