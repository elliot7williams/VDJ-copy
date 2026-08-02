//
//  VDJApp.swift
//  VDJ
//
//  Created by Elliot Williams on 2025-06-24.
//

import SwiftUI
import AVFoundation

@main
struct VDJApp: App {
    @StateObject private var audioEngine = AudioEngine()
    @StateObject private var hapticManager = HapticFeedbackManager()
    
    init() {
        configureAudioSession()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(audioEngine)
                .environmentObject(hapticManager)
                .onAppear {
                    configureAudioSession()
                }
        }
    }
    
    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)
        } catch {
            print("Failed to configure audio session: \(error.localizedDescription)")
        }
    }
}
