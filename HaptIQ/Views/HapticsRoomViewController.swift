//
//  HapticsRoomViewController.swift
//  HaptIQ
//
//  Created by Shreyansh on 15/11/25.
//

import UIKit

final class HapticsRoomViewController: UIViewController {
    
    enum PlayerRole { case crewmate, imposter }
    
    var role: PlayerRole = .crewmate
    private var sentRumbles: Int = 0
    
    private var timer: Timer?
    private var secondsLeft = 10
    
    // MARK: - UI
    private let bgImage: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "bgHex"))
        iv.contentMode = .scaleAspectFill
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let roleCard: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.white.withAlphaComponent(0.12)
        v.layer.cornerRadius = 22
        v.layer.borderWidth = 2
        v.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let roleLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "WinniePERSONALUSE", size: 48)
        l.textColor = .white
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        l.alpha = 0
        return l
    }()
    
    private let statusLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "WinniePERSONALUSE", size: 26)
        l.textColor = UIColor.white.withAlphaComponent(0.85)
        l.textAlignment = .center
        l.numberOfLines = 3
        l.translatesAutoresizingMaskIntoConstraints = false
        l.alpha = 0
        return l
    }()
    
    private let timerLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "WinniePERSONALUSE", size: 54)
        l.textColor = .yellow
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        l.alpha = 0
        return l
    }()
    
    private let continueButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("CONTINUE", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = UIColor(red: 21/255, green: 174/255, blue: 21/255, alpha: 1)
        b.layer.cornerRadius = 22
        b.titleLabel?.font = UIFont(name: "WinniePERSONALUSE", size: 26)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.isHidden = true
        return b
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        animateUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startHapticsRound()
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        
        view.addSubview(bgImage)
        view.addSubview(roleCard)
        view.addSubview(roleLabel)
        view.addSubview(statusLabel)
        view.addSubview(timerLabel)
        view.addSubview(continueButton)
        
        NSLayoutConstraint.activate([
            
            // Background
            bgImage.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bgImage.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bgImage.topAnchor.constraint(equalTo: view.topAnchor),
            bgImage.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Role card
            roleCard.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            roleCard.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            roleCard.widthAnchor.constraint(equalToConstant: 250),
            roleCard.heightAnchor.constraint(equalToConstant: 80),
            
            // Role label inside card
            roleLabel.centerXAnchor.constraint(equalTo: roleCard.centerXAnchor),
            roleLabel.centerYAnchor.constraint(equalTo: roleCard.centerYAnchor),
            
            // Status text
            statusLabel.topAnchor.constraint(equalTo: roleCard.bottomAnchor, constant: 25),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            
            // Timer
            timerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            timerLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            // Continue
            continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            continueButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            continueButton.widthAnchor.constraint(equalToConstant: 220),
            continueButton.heightAnchor.constraint(equalToConstant: 55)
        ])
        
        continueButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
    }
    
    // MARK: UI Animation
    private func animateUI() {
        UIView.animate(withDuration: 1.0) {
            self.roleLabel.alpha = 1
            self.statusLabel.alpha = 1
            self.timerLabel.alpha = 1
        }
    }
    
    // MARK: - GAME LOGIC
    private func startHapticsRound() {
        
        secondsLeft = 10
        timerLabel.text = "10"
        
        switch role {
        case .crewmate:
            roleLabel.text = "CREWMATE"
            statusLabel.text = "Receiving haptics..."
            scheduleCrewmateRumbles()
        case .imposter:
            roleLabel.text = "IMPOSTER"
            statusLabel.text = "Stay silent.\nNo haptics for imposters."
            sentRumbles = 0
        }
        
        startRoundTimer()
    }
    
    // MARK: - TIMER
    private func startRoundTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.secondsLeft -= 1
            self.timerLabel.text = "\(self.secondsLeft)"
            
            if self.secondsLeft <= 0 {
                self.timer?.invalidate()
                self.finishRound()
            }
        }
    }
    
    // MARK: - CREWMATE RUMBLES
    private func scheduleCrewmateRumbles() {
        let rumbleCount = Int.random(in: 2...5)
        sentRumbles = rumbleCount
        
        let gap = 10.0 / Double(rumbleCount + 1)
        
        for i in 1...rumbleCount {
            DispatchQueue.main.asyncAfter(deadline: .now() + gap * Double(i)) {
                HapticsEngineManager.shared.playRumble()
            }
        }
    }
    
    private func finishRound() {
        statusLabel.text = "Your haptics count:\n\(sentRumbles)"
        continueButton.isHidden = false
    }
    
    @objc private func nextTapped() {
        print("➡️ Move to guessing screen with count:", sentRumbles)
    }
}
