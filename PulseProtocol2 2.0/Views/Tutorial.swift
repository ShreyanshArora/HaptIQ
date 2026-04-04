//
//  Tutorial.swift
//  PulseProtocol2.0
//
//  Created by Claude on 02/02/26.
//

import SwiftUI

// MARK: - Tutorial Phase
enum TutorialPhase: Equatable {
    case welcome
    case introShort
    case practiceShort
    case feedbackShort
    case introMedium
    case practiceMedium
    case feedbackMedium
    case introLong
    case practiceLong
    case feedbackLong
    case completion
}

// MARK: - Tutorial State
class TutorialState: ObservableObject {
    @Published var phase: TutorialPhase = .welcome
    @Published var userInputs: [UserInput] = []
    @Published var currentPattern: HapticType?
    @Published var score: Int = 0
    @Published var activePopup: ScorePopup?
    @Published var attempts: Int = 0
    
    private let hapticEngine = HapticEngine.shared
    private var tapStartTime: Date?
    
    // Tutorial sequences
    let shortSequence: [HapticType] = [.short, .short, .short]
    let mediumSequence: [HapticType] = [.medium, .medium, .medium]
    let longSequence: [HapticType] = [.long, .long, .long]
    
    // MARK: - Play Tutorial Pattern
    func playTutorialPattern(type: HapticType, completion: @escaping () -> Void) {
        let sequence = HapticSequence(patterns: [type, type, type], difficulty: 0,isBonus: false)
        
        hapticEngine.playSequence(sequence) {
            DispatchQueue.main.async {
                completion()
            }
        }
    }
    
    // MARK: - Handle Tap
    func onTapDown(type: HapticType) {
        tapStartTime = Date()
        hapticEngine.playPattern(type)
    }
    
    func onTapUp(type: HapticType) {
        guard let start = tapStartTime else { return }
        
        let held = Date().timeIntervalSince(start)
        tapStartTime = nil
        
        print("👆 Tutorial \(type.rawValue) held \(String(format: "%.3f", held))s")
        
        // Record input
        userInputs.append(UserInput(
            type: type,
            timestamp: Date().timeIntervalSince1970,
            duration: held
        ))
        
        // Score this tap
        if let points = PatternMatcher.score(userDuration: held, expected: type) {
            score += points
            triggerPopup(points)
        } else {
            triggerPopup(-5)
        }
        
        attempts += 1
    }
    
    // MARK: - Progress Tutorial
    func nextPhase() {
        userInputs = []
        attempts = 0
        
        switch phase {
        case .welcome:
            phase = .introShort
        case .introShort:
            phase = .practiceShort
        case .practiceShort:
            phase = .feedbackShort
        case .feedbackShort:
            phase = .introMedium
        case .introMedium:
            phase = .practiceMedium
        case .practiceMedium:
            phase = .feedbackMedium
        case .feedbackMedium:
            phase = .introLong
        case .introLong:
            phase = .practiceLong
        case .practiceLong:
            phase = .feedbackLong
        case .feedbackLong:
            phase = .completion
        case .completion:
            break
        }
    }
    
    func reset() {
        phase = .welcome
        userInputs = []
        currentPattern = nil
        score = 0
        activePopup = nil
        attempts = 0
    }
    
    private func triggerPopup(_ delta: Int) {
        let text = delta >= 0 ? "+\(delta)" : "\(delta)"
        activePopup = ScorePopup(text: text, isPositive: delta >= 0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.activePopup = nil
        }
    }
}

// MARK: - Tutorial View
struct TutorialView: View {
    @StateObject private var tutorialState = TutorialState()
    @Environment(\.dismiss) private var dismiss
    
    var onComplete: () -> Void
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(hex: "0A0E27"), Color(hex: "1A1F3A")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Content
            VStack(spacing: 30) {
                switch tutorialState.phase {
                case .welcome:
                    WelcomeView(onContinue: {
                        tutorialState.nextPhase()
                    })
                    
                case .introShort:
                    IntroView(
                        title: "Short Tap",
                        description: "Feel the SHORT haptic pattern.\nQuick and crisp vibrations.",
                        icon: "bolt.fill",
                        color: Color(hex: "4FACFE"),
                        onContinue: {
                            tutorialState.currentPattern = .short
                            tutorialState.playTutorialPattern(type: .short) {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    tutorialState.nextPhase()
                                }
                            }
                        }
                    )
                    
                case .practiceShort:
                    PracticeView(
                        tutorialState: tutorialState,
                        patternType: .short,
                        title: "Practice Short Taps",
                        description: "Tap and hold for about 0.4 seconds.\nMatch the rhythm you felt!",
                        requiredCount: 3,
                        isBonus: false
                    )
                    
                case .feedbackShort:
                    FeedbackView(
                        title: "Great Job!",
                        message: "You've mastered SHORT taps.\nLet's move to the next level.",
                        score: tutorialState.score,
                        onContinue: {
                            tutorialState.nextPhase()
                        }
                    )
                    
                case .introMedium:
                    IntroView(
                        title: "Medium Tap",
                        description: "Feel the MEDIUM haptic pattern.\nA bit longer and smoother.",
                        icon: "waveform",
                        color: Color(hex: "00F2FE"),
                        onContinue: {
                            tutorialState.currentPattern = .medium
                            tutorialState.playTutorialPattern(type: .medium) {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    tutorialState.nextPhase()
                                }
                            }
                        }
                    )
                    
                case .practiceMedium:
                    PracticeView(
                        tutorialState: tutorialState,
                        patternType: .medium,
                        title: "Practice Medium Taps",
                        description: "Tap and hold for about 0.6 seconds.\nFeel the difference!",
                        requiredCount: 3,
                        isBonus: false
                    )
                    
                case .feedbackMedium:
                    FeedbackView(
                        title: "You're Doing Great!",
                        message: "MEDIUM taps unlocked.\nOne more to go!",
                        score: tutorialState.score,
                        onContinue: {
                            tutorialState.nextPhase()
                        }
                    )
                    
                case .introLong:
                    IntroView(
                        title: "Long Tap",
                        description: "Feel the LONG haptic pattern.\nDeep and sustained vibrations.",
                        icon: "waveform.path",
                        color: Color.purple,
                        onContinue: {
                            tutorialState.currentPattern = .long
                            tutorialState.playTutorialPattern(type: .long) {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    tutorialState.nextPhase()
                                }
                            }
                        }
                    )
                    
                case .practiceLong:
                    PracticeView(
                        tutorialState: tutorialState,
                        patternType: .long,
                        title: "Practice Long Taps",
                        description: "Tap and hold for about 0.8 seconds.\nFeel that power!",
                        requiredCount: 3,
                        isBonus: false
                    )
                    
                case .feedbackLong:
                    FeedbackView(
                        title: "Tutorial Complete!",
                        message: "You've mastered all tap types.\nReady for the real challenge?",
                        score: tutorialState.score,
                        onContinue: {
                            tutorialState.nextPhase()
                        }
                    )
                    
                case .completion:
                    CompletionView(
                        score: tutorialState.score,
                        onStartGame: {
                            onComplete()
                        },
                        onSkip: {
                            dismiss()
                        }
                    )
                }
            }
            .padding()
            
            // Score popup
            if let popup = tutorialState.activePopup {
                ScorePopupView(popup: popup)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
            }
        }
        .navigationBarBackButtonHidden(true)
        .animation(.easeOut(duration: 0.3), value: tutorialState.activePopup?.id)
    }
}

// MARK: - Welcome View
struct WelcomeView: View {
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: "4FACFE").opacity(0.3),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 40,
                            endRadius: 100
                        )
                    )
                    .frame(width: 180, height: 180)
                
                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "4FACFE"), Color(hex: "00F2FE")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 16) {
                Text("Let's Start!")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Learn to play PulseProtocol")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            VStack(spacing: 20) {
                InfoRow(icon: "hand.tap.fill", text: "Tap and hold to match rhythms")
                InfoRow(icon: "waveform", text: "Feel different vibration patterns")
                InfoRow(icon: "target", text: "Match timing for higher scores")
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            Button(action: onContinue) {
                HStack(spacing: 12) {
                    Text("BEGIN TUTORIAL")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 18, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "4FACFE"), Color(hex: "00F2FE")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
            }
            .padding(.horizontal, 30)
            
            Spacer()
        }
    }
}

// MARK: - Intro View
struct IntroView: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            Image(systemName: icon)
                .font(.system(size: 80))
                .foregroundColor(color)
                .shadow(color: color.opacity(0.5), radius: 20)
            
            VStack(spacing: 16) {
                Text(title)
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
            }
            .padding(.horizontal, 30)
            
            Spacer()
            
            Button(action: onContinue) {
                HStack(spacing: 10) {
                    Text("FEEL THE PATTERN")
                        .font(.system(size: 18, weight: .bold))
                    Image(systemName: "waveform.circle.fill")
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(color)
                .cornerRadius(16)
            }
            .padding(.horizontal, 30)
            
            Spacer()
        }
    }
}

// MARK: - Practice View
struct PracticeView: View {
    @ObservedObject var tutorialState: TutorialState
    let patternType: HapticType
    let title: String
    let description: String
    let requiredCount: Int
    let isBonus: Bool
    
    @State private var isPressed = false
    @State private var holdDuration: TimeInterval = 0
    @State private var timer: Timer?
    
    var progressText: String {
        "\(tutorialState.userInputs.count) / \(requiredCount)"
    }
    
    var body: some View {
        VStack(spacing: 30) {
            // Header
            VStack(spacing: 12) {
                Text(title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 30)
            .padding(.top, 20)
            
            // Progress
            HStack(spacing: 8) {
                ForEach(0..<requiredCount, id: \.self) { index in
                    Circle()
                        .fill(index < tutorialState.userInputs.count ? Color.green : Color.white.opacity(0.3))
                        .frame(width: 12, height: 12)
                }
            }
            
            Spacer()
            
            // Tap Area
            ZStack {
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color(hex: "4FACFE"), Color(hex: "00F2FE")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ).opacity(isPressed ? 0.9 : 0.3),
                        lineWidth: isPressed ? 10 : 3
                    )
                    .frame(width: 220, height: 220)
                    .blur(radius: isPressed ? 12 : 0)
                
                Circle()
                    .fill(
                        LinearGradient(
                            colors: isPressed
                                ? [Color(hex: "4FACFE"), Color(hex: "00F2FE")]
                                : [Color(hex: "4FACFE").opacity(0.4), Color(hex: "00F2FE").opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 190, height: 190)
                
                VStack(spacing: 10) {
                    if isPressed {
                        Text(String(format: "%.2fs", holdDuration))
                            .font(.system(size: 38, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                        
                        Text("HOLDING...")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white.opacity(0.7))
                    } else {
                        Image(systemName: "hand.tap.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.white.opacity(0.85))
                        
                        Text(progressText)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            
            Spacer()
            
            // Continue button appears when practice is complete
            if tutorialState.userInputs.count >= requiredCount {
                Button(action: {
                    tutorialState.nextPhase()
                }) {
                    HStack(spacing: 10) {
                        Text("CONTINUE")
                            .font(.system(size: 18, weight: .bold))
                        Image(systemName: "arrow.right")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.green)
                    .cornerRadius(16)
                }
                .padding(.horizontal, 30)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            Spacer()
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed && tutorialState.userInputs.count < requiredCount {
                        isPressed = true
                        holdDuration = 0
                        tutorialState.onTapDown(type: patternType)
                        
                        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
                            holdDuration += 0.01
                        }
                    }
                }
                .onEnded { _ in
                    if isPressed {
                        isPressed = false
                        timer?.invalidate()
                        timer = nil
                        
                        tutorialState.onTapUp(type: patternType)
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            holdDuration = 0
                        }
                    }
                }
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .animation(.spring(), value: tutorialState.userInputs.count)
    }
}

// MARK: - Feedback View
struct FeedbackView: View {
    let title: String
    let message: String
    let score: Int
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 90))
                .foregroundColor(.green)
            
            VStack(spacing: 16) {
                Text(title)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(message)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
            }
            .padding(.horizontal, 30)
            
            Spacer()
            
            Button(action: onContinue) {
                HStack(spacing: 10) {
                    Text("NEXT")
                        .font(.system(size: 18, weight: .bold))
                    Image(systemName: "arrow.right")
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "4FACFE"), Color(hex: "00F2FE")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
            }
            .padding(.horizontal, 30)
            
            Spacer()
        }
    }
}

// MARK: - Completion View
struct CompletionView: View {
    let score: Int
    let onStartGame: () -> Void
    let onSkip: () -> Void
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            Image(systemName: "star.circle.fill")
                .font(.system(size: 100))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.yellow, Color.orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .yellow.opacity(0.5), radius: 30)
            
            VStack(spacing: 16) {
                Text("You're Ready!")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Time to test your skills in the real game")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 30)
            
            VStack(spacing: 15) {
                Text("TUTORIAL SCORE")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
                
                Text("\(score)")
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
            .padding(30)
            .background(RoundedRectangle(cornerRadius: 20).fill(Color.white.opacity(0.1)))
            
            Spacer()
            
            VStack(spacing: 15) {
                Button(action: onStartGame) {
                    HStack(spacing: 12) {
                        Text("START GAME")
                            .font(.system(size: 20, weight: .bold))
                        Image(systemName: "play.fill")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "4FACFE"), Color(hex: "00F2FE")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                }
                
                Button(action: onSkip) {
                    Text("BACK TO MENU")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(.horizontal, 30)
            
            Spacer()
        }
    }
}

// MARK: - Info Row
struct InfoRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(Color(hex: "4FACFE"))
                .frame(width: 30)
            
            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
        }
    }
}

#Preview {
    TutorialView(onComplete: {})
}
