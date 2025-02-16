// internal/presentation/theme/AppColors.swift
import SwiftUI

struct AppColors {
    static let backgroundGradient = Gradient(colors: [
        Color(red: 0.98, green: 0.98, blue: 0.98),
        Color(red: 0.95, green: 0.95, blue: 0.95)
    ])
    
   
    
    static let cameraGradient = Gradient(colors: [
           Color(NSColor(red: 0.2, green: 0.4, blue: 1.0, alpha: 1)),
           Color(NSColor(red: 0.3, green: 0.5, blue: 1.0, alpha: 1))
       ])
       
       static let cameraPressedGradient = Gradient(colors: [
           Color(NSColor(red: 0.15, green: 0.35, blue: 0.9, alpha: 1)),
           Color(NSColor(red: 0.25, green: 0.45, blue: 0.9, alpha: 1))
       ])
    
    static let toggleMicrophoneGradient = Gradient(colors: [
        Color(red: 0.87, green: 0.0, blue: 0.0),
        Color(red: 0.78, green: 0.0, blue: 0.0)
    ])
    
    static let toggleMicrophonePressedGradient = Gradient(colors: [
        Color(red: 0.78, green: 0.0, blue: 0.0),
        Color(red: 0.69, green: 0.0, blue: 0.0)
    ])
    
    static let badgeGradient = Gradient(colors: [
        Color(red: 0.0, green: 0.0, blue: 0.0),
        Color(red: 0.4, green: 0.4, blue: 0.4)
    ])
    static let primaryGradient = Gradient(colors: [Color.blue, Color.purple])
    static let messageBackground = Color.white.opacity(0.95)
    static let inputBackground = Color(red: 0.98, green: 0.98, blue: 0.98)
    static let inputBorder = Color(red: 0.9, green: 0.9, blue: 0.9)
    static let textPrimary = Color(red: 0.2, green: 0.2, blue: 0.2)
    static let textSecondary = Color(red: 0.4, green: 0.4, blue: 0.4)
    static let focusedBorder = Color(red: 0.0, green: 0.47, blue: 0.87)
}
