//
//  ScoreLabel.swift
//  PulseProtocol2.0
//
//  Created by Shreyansh on 31/01/26.
//

import SwiftUI

struct ScoreLabel: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(color)

            Text(text)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
        }
    }
}
