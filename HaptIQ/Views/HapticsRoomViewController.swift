//
//  HapticsRoomViewController.swift
//  HaptIQ
//
//  Created by Shreyansh on 15/11/25.
//

import UIKit

final class HapticsRoomViewController: UIViewController {
    
    enum PlayerRole {
        case crewmate
        case imposter
    }
    
    var role: PlayerRole = .crewmate
    private var sentRumbles: Int = 0
    
    private var timer: Timer?
    private var secondsLeft = 10
    
    // UI ----------------------------------------------
    private let roleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "WinniePERSONALUSE", size: 40)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "WinniePERSONALUSE", size: 26)
        label.textColor = UIColor.white.withAlphaComponent(0.85)
        label.textAlignment = .center
        label.numberOfLines = 3
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let timerLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "WinniePERSONALUSE", size: 50)
        label.textColor = .yellow
        label.textAlignment = .center
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let continueButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("CONTINUE", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = UIColor(red: 21/255, green: 174/255, blue: 21/255, alpha: 1)
        btn.layer.cornerRadius = 20
        btn.titleLabel?.font = UIFont(name: "WinniePERSONALUSE", size: 26)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.isHidden = true
        return btn
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startHapticsRound()
    }
    
    private func setupUI() {
        view.addSubview(roleLabel)
        view.addSubview(statusLabel)
        view.addSubview(timerLabel)
        view.addSubview(continueButton)
        
        NSLayoutConstraint.activate([
            roleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            roleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.topAnchor.constraint(equalTo: roleLabel.bottomAnchor, constant: 20),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            
            timerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            timerLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            continueButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            continueButton.widthAnchor.constraint(equalToConstant: 200),
            continueButton.heightAnchor.constraint(equalToConstant: 55)
        ])
        
        continueButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
    }
    
    // MARK: - GAME LOGIC
    private func startHapticsRound() {
        timerLabel.isHidden = false
        secondsLeft = 10
        startRoundTimer()
        
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
    }
    
    // MARK: - 10s TIMER
    private func startRoundTimer() {
        timerLabel.text = "\(secondsLeft)"
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.secondsLeft -= 1
            self.timerLabel.text = "\(self.secondsLeft)"
            
            if self.secondsLeft <= 0 {
                self.timer?.invalidate()
                self.finishRound()
            }
        }
    }
    
    // MARK: - SPACED RUMBLES
    private func scheduleCrewmateRumbles() {
        let rumbleCount = Int.random(in: 2...5)
        sentRumbles = rumbleCount
        
        // total window: 10 seconds
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
