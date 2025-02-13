// internal/presentation/media/AudioMeterView.swift
import SwiftUI

struct AudioMeterView: View {
   @StateObject private var viewModel = AudioMeterViewModel()
   @State private var isHovering = false
   
   var body: some View {
       VStack(spacing: 20) {
           // Volume Meter
           HStack(alignment: .bottom, spacing: 3) {
               ForEach(0..<15) { i in
                   let threshold = Float(i) / 15.0
                   Rectangle()
                       .fill(viewModel.volume >= threshold ? getBarColor(level: threshold) : AppColors.inputBorder.opacity(0.3))
                       .frame(width: 4, height: 36 * CGFloat(1 - threshold))
               }
           }
           .frame(height: 36)
           .animation(.linear(duration: 0.1), value: viewModel.volume)
           
           // Controls
           HStack(spacing: 16) {
               // Mic Toggle Button
               Button(action: {
                   if viewModel.isMonitoring {
                       viewModel.stopMonitoring()
                   } else {
                       viewModel.startMonitoring()
                   }
               }) {
                   HStack(spacing: 4) {
                       Image(systemName: viewModel.isMonitoring ? "mic.fill" : "mic.slash.fill")
                           .font(.system(size: 12, weight: .medium))
                       if isHovering {
                           Text(viewModel.isMonitoring ? "Mute" : "Unmute")
                               .font(.system(size: 12, weight: .medium))
                               .transition(.opacity)
                       }
                   }
                   .padding(.horizontal, 10)
                   .padding(.vertical, 6)
                   .background(
                       LinearGradient(
                           gradient: viewModel.isMonitoring ? AppColors.toggleMicrophonePressedGradient : AppColors.toggleMicrophoneGradient,
                           startPoint: .top,
                           endPoint: .bottom
                       )
                   )
                   .cornerRadius(8)
                   .overlay(
                       RoundedRectangle(cornerRadius: 8)
                           .stroke(Color.white.opacity(0.1), lineWidth: 1)
                   )
                   .foregroundColor(.white)
               }
               .buttonStyle(PlainButtonStyle())
               .onHover { hovering in
                   withAnimation(.easeInOut(duration: 0.2)) {
                       isHovering = hovering
                   }
               }
               
               // Gain Control
               HStack(spacing: 8) {
                   Image(systemName: "speaker.wave.3.fill")
                       .foregroundColor(AppColors.textSecondary)
                       .font(.system(size: 12))
                   
                   Slider(value: $viewModel.inputGain, in: 0...2, onEditingChanged: { _ in
                       viewModel.updateGain()
                   })
                   .frame(width: 100)
                   
                   Text("\(Int(viewModel.inputGain * 100))%")
                       .font(.system(size: 12, weight: .medium))
                       .foregroundColor(AppColors.textSecondary)
                       .frame(width: 36, alignment: .trailing)
               }
               .padding(8)
               .background(AppColors.inputBackground)
               .cornerRadius(8)
           }
           
           // Error Display
           if let error = viewModel.error {
               Text(error)
                   .font(.system(size: 12))
                   .foregroundColor(.red)
                   .padding(.top, 8)
           }
       }
       .onAppear {
           viewModel.startMonitoring()
       }
       .onDisappear {
           viewModel.stopMonitoring()
       }
   }
   
   private func getBarColor(level: Float) -> Color {
       switch level {
       case 0..<0.5:
           return Color.green.opacity(0.7)
       case 0.5..<0.8:
           return Color.yellow.opacity(0.7)
       default:
           return Color.red.opacity(0.7)
       }
   }
}
