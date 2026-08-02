//
//  AudioLevelsView.swift
//  VDJ
//
//  Real-time Audio Levels Display
//

import SwiftUI

struct AudioLevelsView: View {
    let bassLevel: Float
    let midLevel: Float
    let trebleLevel: Float
    
    var body: some View {
        HStack(spacing: 4) {
            // Bass Level
            VStack(spacing: 2) {
                Text("B")
                    .font(.caption2)
                    .foregroundColor(.white)
                
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.red)
                    .frame(width: 8, height: CGFloat(bassLevel * 30 + 5))
                    .animation(.easeInOut(duration: 0.1), value: bassLevel)
            }
            
            // Mid Level
            VStack(spacing: 2) {
                Text("M")
                    .font(.caption2)
                    .foregroundColor(.white)
                
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.yellow)
                    .frame(width: 8, height: CGFloat(midLevel * 30 + 5))
                    .animation(.easeInOut(duration: 0.1), value: midLevel)
            }
            
            // Treble Level
            VStack(spacing: 2) {
                Text("T")
                    .font(.caption2)
                    .foregroundColor(.white)
                
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.green)
                    .frame(width: 8, height: CGFloat(trebleLevel * 30 + 5))
                    .animation(.easeInOut(duration: 0.1), value: trebleLevel)
            }
        }
        .padding(8)
        .background(.ultraThinMaterial)
        .cornerRadius(8)
    }
}

#Preview {
    AudioLevelsView(bassLevel: 0.7, midLevel: 0.5, trebleLevel: 0.3)
}
