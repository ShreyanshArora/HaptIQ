//
//  PageViewController.swift
//  HaptIQ
//
//  Created by Anuj   on 15/11/25.
//
import UIKit
class OnboardingController: UIPageViewController,
                            UIPageViewControllerDataSource,
                            UIPageViewControllerDelegate {
    
    private let pages: [OnboardingPage] = [
        OnboardingPage(imageName: "Rect1", text: "Trust no one. Outsmart your friends"),
        OnboardingPage(imageName: "Rect2", text: "Feel the clues. Catch the imposter."),
        OnboardingPage(imageName: "Rect3", text: "Every vibration hides a secret."),
        OnboardingPage(imageName: "Rect4", text: "One wrong guess... everyone loses.")
    ]
    
    private lazy var controllers: [UIViewController] = {
        pages.map { OnboardingPageVC(page: $0) }
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = self
        delegate = self
        setViewControllers([controllers[0]], direction: .forward, animated: true)
    }
    
    // Swipe navigation
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = controllers.firstIndex(of: viewController), index > 0 else { return nil }
        return controllers[index - 1]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = controllers.firstIndex(of: viewController), index < controllers.count - 1 else { return nil }
        return controllers[index + 1]
    }
}











