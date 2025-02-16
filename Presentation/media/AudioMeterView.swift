// internal/presentation/media/AudioMeterView.swift
import SwiftUI

struct AudioMeterView: View {
    @StateObject private var viewModel = AudioMeterViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            volumeMeter
            controlsSection
            errorDisplay
        }
        .modifier(BaseContainer())
        .onAppear { viewModel.startMonitoring() }
        .onDisappear { viewModel.stopMonitoring() }
    }
    
    private var volumeMeter: some View {
        HStack(alignment: .bottom, spacing: 3) {
            ForEach(0..<15) { i in
                let threshold = Float(i) / 15.0
                Rectangle()
                    .fill(viewModel.volume >= threshold ?
                          getBarColor(level: threshold) :
                          AppColors.inputBorder.opacity(0.3))
                    .frame(width: 4, height: 36 * CGFloat(1 - threshold))
            }
        }
        .frame(height: 36)
        .animation(.linear(duration: 0.1), value: viewModel.volume)
    }
    
    private var controlsSection: some View {
        HStack(spacing: 16) {
            micToggleButton
            gainControl
        }
    }
    
    private var micToggleButton: some View {
        Button(action: {
            viewModel.isMonitoring ? viewModel.stopMonitoring() : viewModel.startMonitoring()
        }) {
            HStack(spacing: 4) {
                Image(systemName: viewModel.isMonitoring ? "mic.fill" : "mic.slash.fill")
                Text(viewModel.isMonitoring ? "Mute" : "Unmute")
                    .font(.system(size: 12, weight: .medium))
            }
        }
        .buttonStyle(PlainButtonStyle())
        .modifier(BaseButton(
            gradient: viewModel.isMonitoring ?
                AppColors.toggleMicrophonePressedGradient :
                AppColors.toggleMicrophoneGradient,
            pressedGradient: AppColors.toggleMicrophonePressedGradient
        ))
    }
    
    private var gainControl: some View {
        HStack(spacing: 8) {
            Image(systemName: "speaker.wave.3.fill")
                .foregroundColor(AppColors.textSecondary)
            Slider(value: $viewModel.inputGain, in: 0...2, onEditingChanged: { _ in
                viewModel.updateGain()
            })
            .frame(width: 100)
            Text("\(Int(viewModel.inputGain * 100))%")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppColors.textSecondary)
        }
        .modifier(BaseInput())
    }
    
    private var errorDisplay: some View {
        Group {
            if let error = viewModel.error {
                Text(error)
                    .font(.system(size: 12))
                    .foregroundColor(.red)
                    .padding(.top, 8)
            }
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
