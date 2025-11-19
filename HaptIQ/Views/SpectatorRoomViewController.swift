//
//  SpectatorRoomViewController.swift
//  HaptIQ
//
//  Created by Shreyansh on 18/11/25.
//

import UIKit

final class SpectatorViewController: UIViewController {

    private let bgImage: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "bghex"))
        iv.contentMode = .scaleAspectFill
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "ELIMINATED"
        l.font = UIFont(name: "WinniePERSONALUSE", size: 48)
        l.textAlignment = .center
        l.textColor = .white
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.text = "You are now spectating the game."
        l.font = UIFont(name: "WinniePERSONALUSE", size: 24)
        l.textAlignment = .center
        l.textColor = .white
        l.numberOfLines = 2
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let iconView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "Mafia")) // use any icon
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        navigationItem.hidesBackButton = true   // can't go back
    }

    private func setupUI() {
        view.addSubview(bgImage)
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(iconView)

        NSLayoutConstraint.activate([
            bgImage.topAnchor.constraint(equalTo: view.topAnchor),
            bgImage.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bgImage.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bgImage.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            iconView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40),
            iconView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 150),
            iconView.heightAnchor.constraint(equalToConstant: 150),

            subtitleLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 40),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30)
        ])
    }
}
