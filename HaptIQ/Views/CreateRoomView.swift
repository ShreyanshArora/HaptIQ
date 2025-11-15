////
////  CreateRoomView.swift
////  HaptIQ
////
////  Created by Anuj   on 14/11/25.
////
//import UIKit
//
//class CreateRoomView: UIView {
//
//    let tipLabel = UILabel()
//    let card = UIView()
//    let titleLabel = UILabel()
//    let codeLabel = UILabel()
//    let nextButton = UIButton(type: .system)
//    let copyHint = UILabel()
//
//    let containerStack = UIStackView()
//    let cardStack = UIStackView()
//
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        setupUI()
//        layoutUI()
//    }
//    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }
//
//    private func setupUI() {
//        backgroundColor = .black
//
//        // Tip label
//        tipLabel.text = "Share this code with your friends"
//        tipLabel.textColor = .white
//        tipLabel.font = UIFont(name: "WinniePERSONALUSE", size: 26)
//        tipLabel.textAlignment = .center
//        tipLabel.numberOfLines = 2
//
//        // Card
//        card.backgroundColor = UIColor.white.withAlphaComponent(0.15)
//        card.layer.cornerRadius = 25
//        card.translatesAutoresizingMaskIntoConstraints = false
//
//        // Title
//        titleLabel.text = "CREATE ROOM"
//        titleLabel.textColor = .white
//        titleLabel.textAlignment = .center
//        titleLabel.font = UIFont(name: "WinniePERSONALUSE", size: 30)
//
//        // Code label
//        codeLabel.textAlignment = .center
//        codeLabel.font = UIFont(name: "WinniePERSONALUSE", size: 24)
//        codeLabel.backgroundColor = .white
//        codeLabel.textColor = .orange
//        codeLabel.layer.cornerRadius = 10
//        codeLabel.layer.masksToBounds = true
//        codeLabel.heightAnchor.constraint(equalToConstant: 51).isActive = true
//        codeLabel.widthAnchor.constraint(equalToConstant: 218).isActive = true
//
//        // Next button
//        nextButton.setTitle("NEXT", for: .normal)
//        nextButton.backgroundColor = UIColor(red: 21/255, green: 174/255, blue: 21/255, alpha: 1.0)
//        nextButton.setTitleColor(.white, for: .normal)
//        nextButton.titleLabel?.font = UIFont(name: "WinniePERSONALUSE", size: 32)
//        nextButton.layer.cornerRadius = 20
//        nextButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
//        nextButton.widthAnchor.constraint(equalToConstant: 185).isActive = true
//
//        // Copy Hint
//        copyHint.text = "Tap to copy the code"
//        copyHint.textColor = .white
//        copyHint.font = UIFont(name: "WinniePERSONALUSE", size: 22)
//        copyHint.textAlignment = .center
//    }
//
//    private func layoutUI() {
//
//        containerStack.axis = .vertical
//        containerStack.spacing = 50
//        containerStack.translatesAutoresizingMaskIntoConstraints = false
//        
//        cardStack.axis = .vertical
//        cardStack.spacing = 30
//        cardStack.alignment = .center
//        cardStack.translatesAutoresizingMaskIntoConstraints = false
//        
//        addSubview(containerStack)
//        containerStack.addArrangedSubview(tipLabel)
//        containerStack.addArrangedSubview(card)
//        containerStack.addArrangedSubview(copyHint)
//
//        card.addSubview(cardStack)
//        cardStack.addArrangedSubview(titleLabel)
//        cardStack.addArrangedSubview(codeLabel)
//        cardStack.addArrangedSubview(nextButton)
//
//        NSLayoutConstraint.activate([
//            containerStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 30),
//            containerStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -30),
//            containerStack.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 100),
//
//            cardStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
//            cardStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
//            cardStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 20),
//            cardStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -20)
//        ])
//    }
//}
//
//
