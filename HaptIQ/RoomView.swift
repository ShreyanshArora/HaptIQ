import SwiftUI

struct RoomView: View {
    @State private var roomCode: String = ""
    @State private var statusMessage: String = ""
    @State private var navigateToLobby = false
    @State private var activeRoomCode: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("🎮 HaptIQ Rooms")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                // ✅ Create Room Button
                Button(action: {
                    RoomManager.shared.createRoom { result in
                        switch result {
                        case .success(let code):
                            statusMessage = "✅ Room created! Code: \(code)"
                            activeRoomCode = code
                            navigateToLobby = true
                            
                        case .failure(let error):
                            statusMessage = "❌ \(error.localizedDescription)"
                        }
                    }
                }) {
                    Text("Create Room")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                
                // ✅ Join Room Section
                VStack(spacing: 10) {
                    TextField("Enter 6-digit code", text: $roomCode)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .padding(.horizontal)
                    
                    Button(action: {
                        guard !roomCode.isEmpty else {
                            statusMessage = "⚠️ Please enter a room code first."
                            return
                        }
                        
                        RoomManager.shared.joinRoom(withCode: roomCode) { result in
                            switch result {
                            case .success():
                                statusMessage = "✅ Joined room \(roomCode)!"
                                activeRoomCode = roomCode
                                navigateToLobby = true
                                
                            case .failure(let error):
                                statusMessage = "❌ \(error.localizedDescription)"
                            }
                        }
                    }) {
                        Text("Join Room")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
                
                // ✅ Status Message
                Text(statusMessage)
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                
                Spacer()
                
                // ✅ Navigation to Lobby
                NavigationLink(destination: RoomLobbyView(roomCode: activeRoomCode), isActive: $navigateToLobby) {
                    EmptyView()
                }
                .hidden()
            }
            .padding()
            .background(Color.black.ignoresSafeArea())
        }
    }
}
