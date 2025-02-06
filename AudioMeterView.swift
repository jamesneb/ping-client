import SwiftUI
import AVFoundation
import AppKit

class AudioMeterViewModel: ObservableObject {
    @Published var volume: Float = 0.0
    @Published var inputGain: Float = 1.0 {
        didSet {
            updateInputGain()
        }
    }
    
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    
    init() {
        requestMicrophoneAccess()
    }
    
    private func requestMicrophoneAccess() {
        AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
            if granted {
                DispatchQueue.main.async {
                    self?.setupAudioEngine()
                }
            } else {
                print("Microphone access denied")
            }
        }
    }
    
    private func updateInputGain() {
        guard let inputNode = audioEngine?.inputNode else { return }
        // Adjust the volume multiplier in the audio processing
        // This will be applied to the incoming audio samples
    }
    
    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else { return }
        
        inputNode = audioEngine.inputNode
        guard let inputNode = inputNode else { return }
        
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, time in
            guard let self = self else { return }
            
            let channelData = buffer.floatChannelData?[0]
            let frameLength = UInt(buffer.frameLength)
            
            var sum: Float = 0
            for i in 0..<frameLength {
                let sample = (channelData?[Int(i)] ?? 0) * self.inputGain // Apply gain to incoming samples
                sum += sample * sample
            }
            
            let rms = sqrt(sum / Float(frameLength))
            
            DispatchQueue.main.async {
                self.volume = min(1.0, rms * 10)
            }
        }
        
        do {
            try audioEngine.start()
            print("Audio engine started successfully")
        } catch {
            print("Error starting audio engine: \(error)")
        }
    }
    
    func stopMonitoring() {
        inputNode?.removeTap(onBus: 0)
        audioEngine?.stop()
    }
    
    deinit {
        stopMonitoring()
    }
}

struct AudioMeterView: View {
    @StateObject private var viewModel = AudioMeterViewModel()
    
    var body: some View {
        VStack(spacing: 16) {
            // Volume bars visualization
            HStack(alignment: .bottom, spacing: 2) {
                ForEach(0..<15) { i in
                    let threshold = Float(i) / 15.0
                    Rectangle()
                        .fill(viewModel.volume >= threshold ? getBarColor(level: threshold) : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 40 * CGFloat(1 - threshold))
                }
            }
            .frame(height: 40)
            .animation(.linear(duration: 0.1), value: viewModel.volume)
            
            HStack {
                Image(systemName: "mic.fill")
                    .foregroundColor(.gray)
                Slider(value: $viewModel.inputGain, in: 0...2)
                    .frame(width: 150)
                Text("\(Int(viewModel.inputGain * 100))%")
                    .foregroundColor(.gray)
                    .frame(width: 40, alignment: .trailing)
            }
            .padding(.horizontal)
            
            // Debug text
            HStack {
                Text("Gain: \(String(format: "%.0f", viewModel.inputGain * 100))%")
                Text("Level: \(String(format: "%.2f", viewModel.volume))")
            }
            .font(.caption)
            .foregroundColor(.gray)
        }
        .padding()
        .background(
            ZStack {
                ToggleMicrophoneButton().frame(width: 160)
                    .offset(x: 0, y: 0) // Adjust these values to fine-tune position
                // Base layer - slightly translucent white
                Color.white.opacity(0.5)
                
                // Subtle top highlight
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.3),
                        Color.white.opacity(0.0)
                    ]),
                    startPoint: .top,
                    endPoint: .center
                )
                
                // Extremely subtle diagonal sheen
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.1),
                        Color.clear,
                        Color.white.opacity(0.1)
                    ]),
                    startPoint: UnitPoint(x: 0, y: 0.2),
                    endPoint: UnitPoint(x: 1, y: 0.8)
                )
                
                // Very soft shadow at the bottom
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        Color.black.opacity(0.03)
                    ]),
                    startPoint: .center,
                    endPoint: .bottom
                )
            }
        )
        .cornerRadius(8)
        // Add a subtle outer glow
        .shadow(color: Color.white.opacity(0.2), radius: 1, x: 0, y: 0)
    }
    
    private func getBarColor(level: Float) -> Color {
        switch level {
        case 0..<0.5:
            return Color.green
        case 0.5..<0.8:
            return Color.yellow
        default:
            return Color.red
        }
    }
}

struct ToggleMicrophoneButton: View {
    @State private var isHovering = false
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            // Action goes here
        }) {
            HStack(spacing: 8) {
                Image(systemName: "mic.slash")
                    

                if isHovering {
                    Text("Disable Mic")
                        .transition(.opacity)
                }
            }
            .padding()
            .background(
                LinearGradient(
                    gradient: isPressed ? AppColors.toggleMicrophonePressedGradient : AppColors.toggleMicrophoneGradient,
                    startPoint: .top,
                    endPoint: .bottom
                )
            ).opacity(0.8)
                .border(Color.gray, width: 1)
            .cornerRadius(12)
            .foregroundColor(.white)
            .animation(.easeInOut(duration: 0.2), value: isHovering)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHovering = hovering
        }
        .pressAction(onPress: {
            isPressed = true
        }, onRelease: {
            isPressed = false
        })
    }
}
