import SwiftUI

struct ContentView2: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showTutorial = false
    @State private var navigateToGame = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // New HaptIQ Game Background
                Image("gScreen")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                
                VStack(spacing: 50) {
                    Spacer()
                    
                    // Logo & Title
                    VStack(spacing: 20) {
                        // Animated Pulse Icon
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            Color(hex: "4FACFE").opacity(0.3),
                                            Color.clear
                                        ],
                                        center: .center,
                                        startRadius: 30,
                                        endRadius: 80
                                    )
                                )
                                .frame(width: 160, height: 160)
                            
                            Image(systemName: "waveform.circle.fill")
                                .font(.system(size: 100))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color(hex: "4FACFE"), Color(hex: "00F2FE")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: Color(hex: "4FACFE").opacity(0.5), radius: 20)
                        }
                        
                        VStack(spacing: 8) {
                            Text("PULSE PROTOCOL")
                                .font(.custom("Aclonica-Regular", size: 34))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.5), radius: 2, y: 2)
                            
                            Text("Feel. Remember. Repeat.")
                                .font(.custom("Aclonica-Regular", size: 16))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    
                    Spacer()
                    
                    // Features
                    VStack(spacing: 16) {
                        FeatureRow(icon: "hand.tap.fill", text: "Tap-based gameplay")
                        FeatureRow(icon: "brain.head.profile", text: "Test your memory")
                        FeatureRow(icon: "chart.line.uptrend.xyaxis", text: "Beat your high score")
                    }
                    .padding(.horizontal, 40)
                    
                    Spacer()
                    
                    // Start Button - checks if tutorial is needed
                    Button(action: {
                        if UserDefaultsManager.shared.hasTutorialCompleted() {
                            navigateToGame = true
                        } else {
                            showTutorial = true
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 20, weight: .bold))
                            Text("START GAME")
                                .font(.custom("Aclonica-Regular", size: 22))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 22)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0/255, green: 150/255, blue: 255/255), Color(red: 0/255, green: 100/255, blue: 255/255)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(25)
                        .shadow(color: Color(red: 0/255, green: 150/255, blue: 255/255).opacity(0.5), radius: 10, y: 5)
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 40)
                    
                    // Optional: Show tutorial again button if already completed
                    if UserDefaultsManager.shared.hasTutorialCompleted() {
                        Button(action: {
                            showTutorial = true
                        }) {
                            Text("REPLAY TUTORIAL")
                                .font(.custom("Aclonica-Regular", size: 16))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    
                    Spacer()
                        .frame(height: 50)
                }
                
                // Back button overlay
                VStack {
                    HStack {
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(Color.white.opacity(0.15))
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                        )
                                )
                        }
                        .padding(.leading, 20)
                        .padding(.top, 50)
                        
                        Spacer()
                    }
                    Spacer()
                }
            }
            .navigationDestination(isPresented: $showTutorial) {
                TutorialView(onComplete: {
                    UserDefaultsManager.shared.setTutorialCompleted(true)
                    showTutorial = false
                    navigateToGame = true
                })
            }
            .navigationDestination(isPresented: $navigateToGame) {
                GameView()
            }
        }
    }
}


#Preview {
    ContentView()
}
