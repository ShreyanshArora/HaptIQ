//
//  ContentView.swift
//  HaptIQ
//
//  Created by Shreyansh on 31/10/25.
//

import SwiftUI
import FirebaseFirestore

struct ContentView: View {
    var body: some View {
        VStack {
            Text("Firestore Connection Test 🔥")
                .font(.title)
                .padding()
        }
        .onAppear {
            let db = Firestore.firestore()

            let testData: [String: Any] = [
                "timestamp": Date().timeIntervalSince1970,
                "message": "Hello Firestore 🚀"
            ]

            db.collection("testCollection").addDocument(data: testData) { error in
                if let error = error {
                    print("❌ Error writing test data: \(error)")
                } else {
                    print("✅ Test data written successfully!")
                }
            }
        }
    }
}
