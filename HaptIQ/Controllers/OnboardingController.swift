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
    
    // MARK: - Pages
    private let pages: [OnboardingPage] = [
        OnboardingPage(imageName: "Rect1", text: "Trust no one. Outsmart your friends"),
        OnboardingPage(imageName: "Rect2", text: "Feel the clues. Catch the imposter."),
        OnboardingPage(imageName: "Rect3", text: "Every vibration hides a secret."),
        OnboardingPage(imageName: "Rect4", text: "One wrong guess... everyone loses.")
    ]
    
    private lazy var controllers: [UIViewController] = {
        pages.map { OnboardingPageVC(page: $0) }
    }()
    
    
    // MARK: - PageControl (the dots)
    private let pageControl: UIPageControl = {
        let pc = UIPageControl()
        pc.numberOfPages = 4
        pc.currentPage = 0
        pc.currentPageIndicatorTintColor = .white
        pc.pageIndicatorTintColor = UIColor(white: 0.6, alpha: 1.0)
        pc.translatesAutoresizingMaskIntoConstraints = false
        return pc
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dataSource = self
        delegate = self
        
        setViewControllers([controllers[0]], direction: .forward, animated: true)
        
        setupPageControl()
    }
    
    
    // MARK: - Add PageControl
    private func setupPageControl() {
        view.addSubview(pageControl)
        
        NSLayoutConstraint.activate([
            pageControl.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    
    // MARK: - Swipe Back
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        guard let index = controllers.firstIndex(of: viewController),
              index > 0 else { return nil }
        
        return controllers[index - 1]
    }
    
    
    // MARK: - Swipe Forward
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        guard let index = controllers.firstIndex(of: viewController) else { return nil }
        
        // If last page → go to JoinRoomViewController
        if index == controllers.count - 1 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                let vc = JoinRoomViewController()
                self.navigationController?.setViewControllers([vc], animated: true)
            }
            return nil
        }
        
        return controllers[index + 1]
    }
    
    // MARK: - Update dots on swipe
    func pageViewController(_ pageViewController: UIPageViewController,
                            didFinishAnimating finished: Bool,
                            previousViewControllers: [UIViewController],
                            transitionCompleted completed: Bool) {

        if completed,
           let visibleVC = pageViewController.viewControllers?.first,
           let index = controllers.firstIndex(of: visibleVC) {
            pageControl.currentPage = index
        }
    }
}
