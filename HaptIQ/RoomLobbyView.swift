//
//  RoomLobbyView.swift
//  HaptIQ
//
//  Created by Shreyansh on 01/11/25.
//

import SwiftUI

struct RoomLobbyView: View {
    let roomCode: String
    
    var body: some View {
        VStack(spacing: 20) {
            Text("🎯 Room Lobby")
                .font(.largeTitle)
                .foregroundColor(.white)
            
            Text("Room Code: \(roomCode)")
                .font(.title)
                .foregroundColor(.white)
            
            Text("Waiting for other players to join...")
                .foregroundColor(.gray)
            
            Spacer()
        }
        .padding()
        .background(Color.black.ignoresSafeArea())
    }
}
