import UIKit

class Instructions: UIViewController {
    
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        setupScrollView()
        setupContent()
    }
    
    // MARK: - ScrollView Setup
    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        contentStack.axis = .vertical
        contentStack.spacing = 40
        contentStack.alignment = .center
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 30),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -30),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }
    
    // MARK: - Build Screen Content
    private func setupContent() {
        
        // TITLE
        let titleLabel = UILabel()
        titleLabel.text = "HOW TO PLAY !!"
        titleLabel.textColor = UIColor(red: 0xE8/255, green: 0x6E/255, blue: 0x28/255, alpha: 1)
        titleLabel.font = UIFont(name: "Aclonica-Regular", size: 34)
        titleLabel.textAlignment = .center
        contentStack.addArrangedSubview(titleLabel)
        
        // SUBTITLE
        let subtitle = UILabel()
        subtitle.text = """
Find out who’s lying — or bluff
your way out of trouble
"""
        subtitle.numberOfLines = 0
        subtitle.textAlignment = .center
        subtitle.textColor = .white
        subtitle.font = UIFont(name: "Aclonica-Regular", size: 19)
        contentStack.addArrangedSubview(subtitle)
        
        // STEP 1 -----------------------
        contentStack.addArrangedSubview(makeStepCard(
            step: "Step 1",
            iconName: "person.text.rectangle",
            title: "Get your role",
            descriptionTop: "Each player gets a secret role",
            civilianText: "Get the haptics in the same pattern",
            imposterText: "Don’t get any haptics"
        ))
        
        // STEP 2 -----------------------
        contentStack.addArrangedSubview(makeStepCard(
            step: "Step 2",
            iconName: "eye.fill",
            title: "Pay attention",
            descriptionTop: "Identify who is reacting differently",
            civilianText: ":Civilian sitting near the imposter will get stronger haptics",
            imposterText: ":must blend in and avoid detection"
        ))
        
        // STEP 3 -----------------------
        contentStack.addArrangedSubview(makeStepCard(
            step: "Step 3",
            iconName: "person.3.sequence.fill",
            title: "Vote wisely",
            descriptionTop: "Discuss  to determine who you believe might be the imposter among civilians",
            civilianText: "Vote as a group to eliminate one player",
            imposterText: "Roles are secret - No one knows who is who"
        ))
       // step 4
        contentStack.addArrangedSubview(makeStepCard(
            step: "Step 4",
            iconName: "person.3.sequence.fill",
            title: "Winning",
            descriptionTop: "Discuss  to determine who you believe might be the imposter among civilians",
            civilianText: ": must fake it and try to save imposter",
            imposterText: ":only one civilian remains"
        ))
    }
    
    // MARK: - CARD BUILDER
    private func makeStepCard(
        step: String,
        iconName: String,
        title: String,
        descriptionTop: String,
        civilianText: String,
        imposterText: String
    ) -> UIView {
        
        let card = UIView()
        card.backgroundColor = UIColor(red: 40/255, green: 40/255, blue: 40/255, alpha: 1)
        card.layer.cornerRadius = 30
        card.translatesAutoresizingMaskIntoConstraints = false
        card.widthAnchor.constraint(equalToConstant: 340).isActive = true
        card.heightAnchor.constraint(greaterThanOrEqualToConstant: 500).isActive = true
        
        // Step Label
        let stepLabel = UILabel()
        stepLabel.text = step
        stepLabel.font = UIFont(name: "Aclonica-Regular", size: 32)
        stepLabel.textColor = UIColor(red: 0.95, green: 0.4, blue: 0.2, alpha: 1)
        stepLabel.textAlignment = .center
        
        // ICON (SF Symbols)
        let icon = UIImageView(image: UIImage(systemName: iconName))
        icon.contentMode = .scaleAspectFit
        icon.tintColor = UIColor(red: 0.95, green: 0.4, blue: 0.2, alpha: 1)
        icon.heightAnchor.constraint(equalToConstant: 140).isActive = true
        
        // Title
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont(name: "Aclonica-Regular", size: 30)
        titleLabel.textAlignment = .center
        titleLabel.textColor = UIColor(red: 0.95, green: 0.4, blue: 0.2, alpha: 1)
        
        // Description Top
        let descTop = UILabel()
        descTop.text = descriptionTop
        descTop.font = UIFont(name: "Aclonica-Regular", size: 22)
        descTop.textColor = UIColor(red: 170/255, green: 200/255, blue: 255/255, alpha: 1)
        descTop.textAlignment = .center
        descTop.numberOfLines = 0
        
        // CIVILIAN --------------------------
        let civTitle = UILabel()
        civTitle.text = "CIVILIAN"
        civTitle.textColor = .white
        civTitle.font = UIFont(name: "Aclonica-Regular", size: 22)
        
        let civDesc = UILabel()
        civDesc.text = civilianText
        civDesc.textColor = .white
        civDesc.font = UIFont(name: "Aclonica-Regular", size: 20)
        civDesc.numberOfLines = 0
        civDesc.textAlignment = .left
        
        let civRow = UIStackView(arrangedSubviews: [civTitle, civDesc])
        civRow.axis = .horizontal
        civRow.spacing = 16
        civRow.alignment = .fill
        
        // IMPOSTER --------------------------
        let impTitle = UILabel()
        impTitle.text = "IMPOSTER"
        impTitle.textColor = .white
        impTitle.font = UIFont(name: "Aclonica-Regular", size: 22)
        
        let impDesc = UILabel()
        impDesc.text = imposterText
        impDesc.textColor = .white
        impDesc.font = UIFont(name: "Aclonica-Regular", size: 20)
        impDesc.numberOfLines = 0
        impDesc.textAlignment = .left
        
        let impRow = UIStackView(arrangedSubviews: [impTitle, impDesc])
        impRow.axis = .horizontal
        impRow.spacing = 16
        impRow.alignment = .fill
        
        // FINAL STACK -------------------------
        let innerStack = UIStackView(arrangedSubviews: [
            stepLabel,
            icon,
            titleLabel,
            descTop,
            civRow,
            impRow
        ])
        
        innerStack.axis = .vertical
        innerStack.spacing = 22
        innerStack.alignment = .center
        innerStack.translatesAutoresizingMaskIntoConstraints = false
        
        card.addSubview(innerStack)
        
        NSLayoutConstraint.activate([
            innerStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 25),
            innerStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -25),
            innerStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 25),
            innerStack.bottomAnchor.constraint(lessThanOrEqualTo: card.bottomAnchor, constant: -25)
        ])
        
        return card
    }
}

