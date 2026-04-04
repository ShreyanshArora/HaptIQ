import SwiftUI

// MARK: - Game View
struct GameView: View {
    @StateObject private var controller = GameController()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // Background with hex pattern
            ZStack {
                Image("bghex")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .opacity(0.3)
                
                LinearGradient(
                    colors: [Color(hex: "0A0E27"), Color(hex: "1A1F3A")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .opacity(0.85)
                .ignoresSafeArea()
            }

            // Phase-based content
            VStack(spacing: 40) {
                switch controller.session.phase {
                case .menu:            menuView
                case .playingPattern:  listeningView
                case .waitingForInput: InputView(controller: controller)
                case .correct:         correctView
                case .bonusUnlocked:   bonusUnlockedView
                case .gameOver:        gameOverView
                case .instructions:    instructionsView
                }
            }
            .padding()

            // Score popup floats on top of everything
            if let popup = controller.session.activePopup {
                ScorePopupView(popup: popup)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal:   .move(edge: .top).combined(with: .opacity)
                    ))
            }
        }
        .navigationBarBackButtonHidden(true)
        .animation(.easeOut(duration: 0.3), value: controller.session.activePopup?.id)
    }

    // ─────────────────────────────────────
    // MARK: - Menu
    // ─────────────────────────────────────
    private var menuView: some View {
        VStack(spacing: 30) {
            Spacer()

            Text("PulseProtocol")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text("Feel the Rhythm")
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.7))

            Spacer()

            // High Score
            VStack(spacing: 10) {
                Text("HIGH SCORE")
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.6))
                Text("\(controller.session.highScore)")
                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
            .padding(20)
            .background(RoundedRectangle(cornerRadius: 20).fill(Color.white.opacity(0.1)))

            Spacer()

            // Start
            Button(action: { controller.startGame() }) {
                Text("START GAME")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))
            }
            .padding(.horizontal)

            // Back
            Button(action: { dismiss() }) {
                Text("BACK")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.top, 10)

            Spacer()
        }
    }

    // ─────────────────────────────────────
    // MARK: - Listening (pattern playing)
    // ─────────────────────────────────────
    private var listeningView: some View {
        VStack(spacing: 40) {
            Spacer()

            if let seq = controller.session.currentSequence, seq.isBonus {
                BonusPulsingCircle()
            } else {
                PulsingCircle()
            }

            if let seq = controller.session.currentSequence {
                if seq.isBonus {
                    VStack(spacing: 12) {
                        Text("🎁 BONUS ROUND \(controller.session.currentRound) 🎁")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.yellow, Color.orange],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        Text("Feel the Pattern…")
                            .font(.system(size: 20, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("\(seq.patterns.count) taps coming")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(.yellow.opacity(0.7))
                    }
                } else {
                    VStack(spacing: 12) {
                        Text("Feel the Pattern…")
                            .font(.system(size: 24, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("\(seq.patterns.count) taps coming")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.45))
                    }
                }
            }

            Spacer()
        }
    }

    // ─────────────────────────────────────
    // MARK: - Correct
    // ─────────────────────────────────────
    
    private var correctView: some View {
        VStack {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)

            if let seq = controller.session.currentSequence, seq.isBonus {
                Text("Bonus Round \(controller.session.currentRound) Complete!")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.yellow, Color.orange],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            } else {
                Text("Round \(controller.session.currentRound) Complete!")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }

            Spacer()
        }
    }
    
    
    // ─────────────────────────────────────
    // MARK: - Bonus Unlocked
    // ─────────────────────────────────────
    private var bonusUnlockedView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Animated star
            ZStack {
                ForEach(0..<3, id: \.self) { index in
                    Image(systemName: "sparkles")
                        .font(.system(size: 100))
                        .foregroundColor(.yellow)
                        .opacity(0.6)
                        .scaleEffect(1.5)
                        .rotationEffect(.degrees(Double(index) * 120))
                }
                
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 120))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.yellow, Color.orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .yellow, radius: 30)
            }
            
            VStack(spacing: 16) {
                Text("🎊 BONUS UNLOCKED! 🎊")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.yellow, Color.orange, Color.yellow],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text("Perfect Round!")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Get ready for the challenge...")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
        }
    }

    // ─────────────────────────────────────
    // MARK: - Game Over
    // ─────────────────────────────────────
    private var gameOverView: some View {
        VStack(spacing: 30) {
            Spacer()

            let reachedBonus = controller.session.currentRound >= 6

            if reachedBonus {
                Text("🏆 Amazing Run! 🏆")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.yellow, Color.orange],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            } else {
                Text("Game Over")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }

            VStack(spacing: 15) {
                Text("FINAL SCORE")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))

                Text("\(controller.session.currentScore)")
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)

                if controller.session.currentScore == controller.session.highScore
                    && controller.session.currentScore > 0 {
                    Text("🏆 NEW HIGH SCORE!")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.yellow)
                }
            }
            .padding(30)
            .background(RoundedRectangle(cornerRadius: 20).fill(Color.white.opacity(0.1)))

            if reachedBonus {
                Text("Reached Bonus Round \(controller.session.currentRound)!")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.yellow, Color.orange],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            } else {
                Text("Reached Round \(controller.session.currentRound)")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()

            VStack(spacing: 15) {
                Button(action: { controller.restartGame() }) {
                    Text("PLAY AGAIN")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))
                }

                Button(action: { controller.returnToMenu() }) {
                    Text("MENU")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(RoundedRectangle(cornerRadius: 16).stroke(Color.white, lineWidth: 2))
                }
            }
            .padding(.horizontal)

            Spacer()
        }
    }

    // ─────────────────────────────────────
    // MARK: - Instructions
    // ─────────────────────────────────────
    private var instructionsView: some View {
        VStack {
            Text("Instructions")
                .font(.title)
                .foregroundColor(.white)
        }
    }
}

// ═══════════════════════════════════════════
// MARK: - Pulsing Circle
// ═══════════════════════════════════════════
struct PulsingCircle: View {
    @State private var animating = false

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.15))
                .frame(width: 140, height: 140)

            Circle()
                .stroke(Color.white, lineWidth: 2)
                .frame(width: 140, height: 140)
                .scaleEffect(animating ? 1.7 : 1.0)
                .opacity(animating ? 0.0 : 0.7)
                .animation(
                    .easeOut(duration: 1.2).repeatForever(autoreverses: false),
                    value: animating
                )
        }
        .onAppear { animating = true }
    }
}

// ═══════════════════════════════════════════
// MARK: - Bonus Pulsing Circle
// ═══════════════════════════════════════════
struct BonusPulsingCircle: View {
    @State private var animating = false
    @State private var rotating = false

    var body: some View {
        ZStack {
            // Multiple pulse rings for bonus effect
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color.yellow, Color.orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 140, height: 140)
                    .scaleEffect(animating ? 1.7 + CGFloat(index) * 0.3 : 1.0)
                    .opacity(animating ? 0.0 : 0.8)
                    .animation(
                        .easeOut(duration: 1.2)
                        .repeatForever(autoreverses: false)
                        .delay(Double(index) * 0.2),
                        value: animating
                    )
            }
            
            // Center filled circle with stars
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.yellow.opacity(0.6),
                                Color.orange.opacity(0.3)
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 70
                        )
                    )
                    .frame(width: 140, height: 140)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(rotating ? 360 : 0))
                    .animation(
                        .linear(duration: 3)
                        .repeatForever(autoreverses: false),
                        value: rotating
                    )
            }
        }
        .onAppear {
            animating = true
            rotating = true
        }
    }
}

// ═══════════════════════════════════════════
// MARK: - Score Popup (+10 / -5)
// ═══════════════════════════════════════════
struct ScorePopupView: View {
    let popup  : ScorePopup
    @State private var offset  : CGFloat = 0
    @State private var opacity : Double  = 1.0

    var body: some View {
        Text(popup.text)
            .font(.system(size: 38, weight: .bold, design: .rounded))
            .foregroundColor(popup.isPositive ? .green : .red)
            .shadow(color: .black.opacity(0.5), radius: 6, x: 0, y: 2)
            .offset(y: offset)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 0.9)) {
                    offset  = -130
                    opacity =  0.0
                }
            }
    }
}

// ═══════════════════════════════════════════
#Preview {
    GameView()
}
