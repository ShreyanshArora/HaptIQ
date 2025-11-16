//
//  UIView+Gradient.swift
//  HaptIQ
//
//  Created by Shreyansh on 15/11/25.
//


//
//  UIView+Gradient.swift
//  HaptIQ
//
//  Created by Shreyansh on 15/11/25.
//

import UIKit

extension UIView {
    func applyGradient(
        colors: [UIColor],
        startPoint: CGPoint = CGPoint(x: 0.5, y: 0.0),
        endPoint: CGPoint = CGPoint(x: 0.5, y: 1.0),
        cornerRadius: CGFloat = 0
    ) {
        layer.sublayers?.removeAll(where: { $0 is CAGradientLayer })

        let gradient = CAGradientLayer()
        gradient.frame = bounds
        gradient.colors = colors.map { $0.cgColor }
        gradient.startPoint = startPoint
        gradient.endPoint = endPoint
        gradient.cornerRadius = cornerRadius

        layer.insertSublayer(gradient, at: 0)
    }
}
