//
//  HapticFeedbackManager.swift
//  VDJ
//
//  Enhanced Haptic Feedback System
//

import Foundation
import UIKit

class HapticFeedbackManager: ObservableObject {
    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    private let selectionFeedback = UISelectionFeedbackGenerator()
    private let notificationFeedback = UINotificationFeedbackGenerator()
    
    private var lastBeatTime: TimeInterval = 0
    private let minBeatInterval: TimeInterval = 0.1
    
    init() {
        impactFeedback.prepare()
        selectionFeedback.prepare()
        notificationFeedback.prepare()
    }
    
    func beatHaptic() {
        let currentTime = CACurrentMediaTime()
        guard (currentTime - lastBeatTime) > minBeatInterval else { return }
        
        impactFeedback.impactOccurred()
        lastBeatTime = currentTime
    }
    
    func selectionHaptic() {
        selectionFeedback.selectionChanged()
    }
    
    func successHaptic() {
        notificationFeedback.notificationOccurred(.success)
    }
    
    func errorHaptic() {
        notificationFeedback.notificationOccurred(.error)
    }
    
    func warningHaptic() {
        notificationFeedback.notificationOccurred(.warning)
    }
}
