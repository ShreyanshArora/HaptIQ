//
//  InputView.swift
//  PulseProtocol2.0
//

import SwiftUI

struct InputView: View {

    @ObservedObject var controller: GameController

    @State private var isPressed = false
    @State private var holdDuration: TimeInterval = 0
    @State private var timer: Timer?

    // GAME FEEL
    @State private var streak = 0
    @State private var feedbackText = ""
    @State private var feedbackColor: Color = .white
    @State private var showFeedback = false
    @State private var isBonus = false

    var body: some View {
        ZStack {
            backgroundView

            VStack(spacing: 28) {
                headerView

                if streak > 1 {
                    streakView
                }

                Spacer()

                if showFeedback {
                    feedbackView
                }

                Spacer()

                tapAreaView
                    .padding(.bottom, 60)
            }
            .padding(.horizontal, 12) // ⭐ Edge balance fix
        }
        .onChange(of: controller.session.activePopup?.id) {
            handlePopupChange()
        }
        .onChange(of: controller.session.currentSequence?.isBonus) {
            isBonus = controller.session.currentSequence?.isBonus ?? false
        }
        .onAppear {
            isBonus = controller.session.currentSequence?.isBonus ?? false
        }
        .gesture(tapGesture)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
    }

    // MARK: - Background
    private var backgroundView: some View {
        ZStack {
            Image("gScreen")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            if isBonus {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
            }

            // ⭐ Soft side fade polish
            LinearGradient(
                colors: [
                    Color.black.opacity(0.25),
                    Color.clear,
                    Color.clear,
                    Color.black.opacity(0.15)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .ignoresSafeArea()
            .blendMode(.overlay)
        }
    }

    // MARK: - Header
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("SCORE")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.5))

                Text("\(controller.session.currentScore)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if isBonus {
                    Text("🎁 BONUS")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.yellow, Color.orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                } else {
                    Text("ROUND")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.5))
                }

                Text("\(controller.session.currentRound)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(isBonus ? .yellow : .white)
            }
        }
        .padding(.horizontal, 32) // ⭐ Alignment polish
        .padding(.top, 24)
    }

    // MARK: - Streak
    private var streakView: some View {
        Text("🔥 \(streak) STREAK")
            .font(.custom("Aclonica-Regular", size: 20))
            .foregroundColor(.orange)
            .transition(.scale)
    }

    // MARK: - Feedback
    private var feedbackView: some View {
        Text(feedbackText)
            .font(.custom("Aclonica-Regular", size: 44))
            .foregroundColor(feedbackColor)
            .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Tap Area
    private var tapAreaView: some View {
        ZStack {

            // Glow ring
            Circle()
                .stroke(glowColor, lineWidth: isPressed ? 8 : 4)
                .frame(width: 220, height: 220)
                .blur(radius: isPressed ? 12 : 0)
                .animation(.easeOut(duration: 0.2), value: isPressed)

            // Base circle
            Circle()
                .fill(baseGradient)
                .frame(width: 190, height: 190)
                .shadow(color: glowShadowColor, radius: isPressed ? 20 : 10)

            tapContentView
        }
    }

    private var tapContentView: some View {
        VStack(spacing: 10) {
            if isPressed {
                Text(String(format: "%.2fs", holdDuration))
                    .font(.system(size: 34, weight: .bold, design: .monospaced))
                    .foregroundColor(isBonus ? .black : .white)

                Text("MATCH TIMING")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(isBonus ? .black.opacity(0.7) : .white.opacity(0.7))
            } else {
                Image(systemName: isBonus ? "star.fill" : "hand.tap.fill")
                    .font(.system(size: 42))
                    .foregroundColor(isBonus ? .black.opacity(0.85) : .white.opacity(0.85))

                Text("PRESS & HOLD")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isBonus ? .black.opacity(0.6) : .white.opacity(0.6))
            }
        }
    }

    // MARK: - Styles
    private var glowColor: AnyShapeStyle {
        if isBonus {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [Color.yellow, Color.orange],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .opacity(isPressed ? 0.9 : 0.3)
            )
        } else {
            return AnyShapeStyle(feedbackColor.opacity(isPressed ? 0.9 : 0.3))
        }
    }

    private var baseGradient: LinearGradient {
        if isBonus {
            return LinearGradient(
                colors: isPressed
                    ? [Color.yellow, Color.orange]
                    : [Color.yellow.opacity(0.4), Color.orange.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: isPressed
                    ? [Color(hex: "4FACFE"), Color(hex: "00F2FE")]
                    : [Color(hex: "4FACFE").opacity(0.4), Color(hex: "00F2FE").opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var glowShadowColor: Color {
        isBonus
            ? Color.yellow.opacity(0.4)
            : feedbackColor.opacity(0.4)
    }

    // MARK: - Gesture
    private var tapGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in
                handleTapDown()
            }
            .onEnded { _ in
                handleTapUp()
            }
    }

    // MARK: - Handlers
    private func handlePopupChange() {
        guard let popup = controller.session.activePopup else { return }

        if popup.isPositive {
            streak += 1

            if popup.text.contains("10") {
                feedbackText = "PERFECT"
                feedbackColor = isBonus ? .yellow : .green
            } else if popup.text.contains("8") {
                feedbackText = "GREAT"
                feedbackColor = isBonus ? .orange : .blue
            } else {
                feedbackText = "GOOD"
                feedbackColor = .yellow
            }
        } else {
            streak = 0
            feedbackText = "MISS"
            feedbackColor = .red
        }

        showFeedback = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            showFeedback = false
        }
    }

    private func handleTapDown() {
        if !isPressed && controller.session.phase == .waitingForInput {
            isPressed = true
            holdDuration = 0

            let index = controller.session.userInputs.count
            let expected = controller.session.currentSequence!.patterns[index]

            controller.onTapDown(type: expected)

            timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
                holdDuration += 0.01
            }
        }
    }

    private func handleTapUp() {
        if isPressed {
            isPressed = false
            timer?.invalidate()
            timer = nil

            let index = controller.session.userInputs.count
            let expected = controller.session.currentSequence!.patterns[index]

            controller.onTapUp(type: expected)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                holdDuration = 0
            }
        }
    }
}

#Preview {
    InputView(controller: GameController())
}
