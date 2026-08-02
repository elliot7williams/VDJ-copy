//
//  VisualizerView.swift
//  VDJ
//
//  Advanced Audio-Reactive Visualizer
//

import SwiftUI
import simd

struct VisualizerView: View {
    @Binding var frequencyData: [Float]
    @State private var animationPhase: Double = 0
    
    var body: some View {
        Canvas { context, size in
            context.fill(
                Path(ellipseIn: CGRect(origin: .zero, size: size)),
                with: .radialGradient(
                    Gradient(colors: [Color.black, Color.blue.opacity(0.3), Color.clear]),
                    center: CGPoint(x: size.width/2, y: size.height/2),
                    startRadius: 0,
                    endRadius: max(size.width, size.height)/2
                )
            )
            
            drawFrequencyBars(context: context, size: size)
            drawParticles(context: context, size: size)
            drawWaveform(context: context, size: size)
        }
        .onReceive(Timer.publish(every: 0.016, on: .main, in: .common).autoconnect()) { _ in
            animationPhase += 0.1
        }
    }
    
    private func drawFrequencyBars(context: GraphicsContext, size: CGSize) {
        let barCount = min(frequencyData.count, 64)
        let barWidth = size.width / CGFloat(barCount)
        
        for i in 0..<barCount {
            let frequency = frequencyData[i]
            let barHeight = CGFloat(frequency) * size.height * 0.8
            let x = CGFloat(i) * barWidth
            let y = size.height - barHeight
            
            let hue = Double(i) / Double(barCount)
            let color = Color(hue: hue, saturation: 0.8, brightness: 0.9)
            
            let rect = CGRect(x: x, y: y, width: barWidth * 0.8, height: barHeight)
            context.fill(
                Path(rect),
                with: .color(color.opacity(0.7))
            )
            
            // Add glow effect (simplified for iOS compatibility)
            context.fill(
                Path(rect),
                with: .color(color.opacity(0.3))
            )
        }
    }
    
    private func drawParticles(context: GraphicsContext, size: CGSize) {
        let particleCount = 50
        
        for i in 0..<particleCount {
            let phase = animationPhase + Double(i) * 0.1
            let radius = 30.0 + sin(phase) * 20.0
            
            let x = size.width/2 + cos(phase) * radius
            let y = size.height/2 + sin(phase * 1.3) * radius
            
            let particleSize = 2.0 + sin(phase * 2) * 1.0
            let alpha = 0.3 + sin(phase * 1.5) * 0.2
            
            let rect = CGRect(
                x: x - particleSize/2,
                y: y - particleSize/2,
                width: particleSize,
                height: particleSize
            )
            
            context.fill(
                Path(ellipseIn: rect),
                with: .color(.white.opacity(alpha))
            )
        }
    }
    
    private func drawWaveform(context: GraphicsContext, size: CGSize) {
        var path = Path()
        let pointCount = min(frequencyData.count, 200)
        
        for i in 0..<pointCount {
            let x = CGFloat(i) / CGFloat(pointCount) * size.width
            let amplitude = CGFloat(frequencyData[i]) * 100
            let y = size.height/2 + sin(animationPhase + Double(i) * 0.1) * amplitude
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        context.stroke(
            path,
            with: .color(.cyan.opacity(0.6)),
            lineWidth: 2
        )
        
        // Add second waveform with offset
        var path2 = Path()
        for i in 0..<pointCount {
            let x = CGFloat(i) / CGFloat(pointCount) * size.width
            let amplitude = CGFloat(frequencyData[i]) * 80
            let y = size.height/2 + cos(animationPhase * 1.2 + Double(i) * 0.08) * amplitude
            
            if i == 0 {
                path2.move(to: CGPoint(x: x, y: y))
            } else {
                path2.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        context.stroke(
            path2,
            with: .color(.purple.opacity(0.4)),
            lineWidth: 3
        )
    }
}

// MARK: - Advanced 3D Visualizer
struct Advanced3DVisualizerView: View {
    @Binding var frequencyData: [Float]
    @Binding var bassLevel: Float
    @Binding var midLevel: Float
    @Binding var trebleLevel: Float
    @Binding var beatDetected: Bool
    
    @State private var rotationAngle: Double = 0
    @State private var pulseScale: Double = 1.0
    
    var body: some View {
        Canvas { context, size in
            context.translateBy(x: size.width/2, y: size.height/2)
            
            // Draw 3D-like frequency cube
            drawFrequencyCube(context: context, size: size)
            
            // Draw orbital rings
            drawOrbitalRings(context: context, size: size)
            
            // Draw bass pulse
            if beatDetected {
                drawBeatPulse(context: context, size: size)
            }
        }
        .onReceive(Timer.publish(every: 0.016, on: .main, in: .common).autoconnect()) { _ in
            rotationAngle += 1
            pulseScale = beatDetected ? 1.2 : 1.0
        }
        .scaleEffect(pulseScale)
        .animation(.easeOut(duration: 0.1), value: pulseScale)
    }
    
    private func drawFrequencyCube(context: GraphicsContext, size: CGSize) {
        let cubeSize: CGFloat = 100
        let perspective: CGFloat = 0.7
        
        // Front face
        var frontPath = Path()
        frontPath.move(to: CGPoint(x: -cubeSize/2, y: -cubeSize/2))
        frontPath.addLine(to: CGPoint(x: cubeSize/2, y: -cubeSize/2))
        frontPath.addLine(to: CGPoint(x: cubeSize/2, y: cubeSize/2))
        frontPath.addLine(to: CGPoint(x: -cubeSize/2, y: cubeSize/2))
        frontPath.closeSubpath()
        
        context.fill(
            frontPath,
            with: .color(.blue.opacity(Double(bassLevel) * 0.5))
        )
        
        // Right face (isometric projection)
        var rightPath = Path()
        rightPath.move(to: CGPoint(x: cubeSize/2, y: -cubeSize/2))
        rightPath.addLine(to: CGPoint(x: cubeSize/2 + cubeSize * perspective, y: -cubeSize/2 - cubeSize * perspective))
        rightPath.addLine(to: CGPoint(x: cubeSize/2 + cubeSize * perspective, y: cubeSize/2 - cubeSize * perspective))
        rightPath.addLine(to: CGPoint(x: cubeSize/2, y: cubeSize/2))
        rightPath.closeSubpath()
        
        context.fill(
            rightPath,
            with: .color(.purple.opacity(Double(midLevel) * 0.5))
        )
        
        // Top face
        var topPath = Path()
        topPath.move(to: CGPoint(x: -cubeSize/2, y: -cubeSize/2))
        topPath.addLine(to: CGPoint(x: -cubeSize/2 + cubeSize * perspective, y: -cubeSize/2 - cubeSize * perspective))
        topPath.addLine(to: CGPoint(x: cubeSize/2 + cubeSize * perspective, y: -cubeSize/2 - cubeSize * perspective))
        topPath.addLine(to: CGPoint(x: cubeSize/2, y: -cubeSize/2))
        topPath.closeSubpath()
        
        context.fill(
            topPath,
            with: .color(.cyan.opacity(Double(trebleLevel) * 0.5))
        )
    }
    
    private func drawOrbitalRings(context: GraphicsContext, size: CGSize) {
        let ringCount = 5
        
        for i in 0..<ringCount {
            let radius = CGFloat(50 + i * 30)
            let rotation = rotationAngle + Double(i * 30)
            
            // Simplified rotation without saveGState for iOS compatibility
            let centerX = radius * cos(rotation * .pi / 180)
            let centerY = radius * sin(rotation * .pi / 180) / 3
            
            let ringPath = Path(ellipseIn: CGRect(
                x: centerX - radius,
                y: centerY - radius/3,
                width: radius * 2,
                height: radius * 2/3
            ))
            
            let frequency = i < frequencyData.count ? frequencyData[i * 10] : 0
            let opacity = Double(frequency) * 0.8 + 0.2
            
            context.stroke(
                ringPath,
                with: .color(.white.opacity(opacity)),
                lineWidth: 2
            )
        }
    }
    
    private func drawBeatPulse(context: GraphicsContext, size: CGSize) {
        let pulseRadius: CGFloat = 150
        
        let pulsePath = Path(ellipseIn: CGRect(
            x: -pulseRadius,
            y: -pulseRadius,
            width: pulseRadius * 2,
            height: pulseRadius * 2
        ))
        
        context.stroke(
            pulsePath,
            with: .color(.red.opacity(0.6)),
            lineWidth: 4
        )
        
        // Inner pulse
        let innerPulsePath = Path(ellipseIn: CGRect(
            x: -pulseRadius * 0.7,
            y: -pulseRadius * 0.7,
            width: pulseRadius * 1.4,
            height: pulseRadius * 1.4
        ))
        
        context.stroke(
            innerPulsePath,
            with: .color(.yellow.opacity(0.4)),
            lineWidth: 2
        )
    }
}

#Preview {
    VisualizerView(frequencyData: .constant(Array(repeating: 0.5, count: 512)))
}
