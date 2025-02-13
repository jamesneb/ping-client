import SwiftUI
import AVFoundation
import AppKit

// MARK: - Press Action Modifier
struct PressAction: ViewModifier {
    let onPress: () -> Void
    let onRelease: () -> Void
    
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in onPress() }
                    .onEnded { _ in onRelease() }
            )
    }
}

extension View {
    func pressAction(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        self.modifier(PressAction(onPress: onPress, onRelease: onRelease))
    }
}

// MARK: - Camera View
struct CameraView: NSViewRepresentable {
    class Coordinator: NSObject {
        var captureSession: AVCaptureSession?
        var previewLayer: AVCaptureVideoPreviewLayer?
        
        override init() {
            super.init()
            captureSession = AVCaptureSession()
        }
        
        func setupCamera(in view: NSView) {
            guard let captureSession = captureSession else { return }
            
            guard let device = AVCaptureDevice.default(for: .video) else {
                print("Error: Camera not found")
                return
            }
            
            do {
                let input = try AVCaptureDeviceInput(device: device)
                if captureSession.canAddInput(input) {
                    captureSession.addInput(input)
                } else {
                    print("Error: Unable to add camera input to session")
                }
            } catch {
                print("Error: Unable to access camera - \(error)")
            }
            
            let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.frame = view.bounds
            view.layer = previewLayer
            view.wantsLayer = true
            
            self.previewLayer = previewLayer
            captureSession.startRunning()
        }
        
        func updateFrame(to bounds: CGRect) {
            previewLayer?.frame = bounds
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        DispatchQueue.main.async {
            context.coordinator.setupCamera(in: view)
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            context.coordinator.updateFrame(to: nsView.bounds)
        }
    }
}

// MARK: - Camera Control Button
struct CameraControlButton: View {
    let icon: String
    let text: String
    var gradient: Gradient = AppColors.cameraGradient
    let action: () -> Void
    @State private var isHovering = false
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .imageScale(.medium)
                
                if isHovering {
                    Text(text)
                        .font(.system(size: 14, weight: .medium))
                        .transition(.opacity)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                LinearGradient(
                    gradient: isPressed ? AppColors.cameraPressedGradient : gradient,
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 2)
            .foregroundColor(.white)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
        .pressAction(onPress: {
            isPressed = true
        }, onRelease: {
            isPressed = false
        })
    }
}

// MARK: - Disable Camera Button
struct DisableCameraButton: View {
    @State private var isDisabled = false
    
    var body: some View {
        CameraControlButton(
            icon: "camera.circle.fill",
            text: isDisabled ? "Enable Camera" : "Disable Camera",
            gradient: isDisabled ? AppColors.primaryGradient : AppColors.cameraGradient
        ) {
            isDisabled.toggle()
        }
    }
}

// MARK: - Connect Button
struct ConnectButton: View {
    @State private var showNoiseView = false
    
    var body: some View {
        CameraControlButton(
            icon: "wifi",
            text: "Connect",
            gradient: AppColors.primaryGradient
        ) {
            showNoiseView = true
        }
        .sheet(isPresented: $showNoiseView) {
            PerlinBackgroundView()
                .frame(width: 1024, height: 768)
        }
    }
}

// MARK: - Camera Container
struct CameraContainer: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ZStack(alignment: .bottom) {
                CameraView()
                    .frame(width: 360, height: 240)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppColors.inputBorder, lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                
                HStack(spacing: 12) {
                    DisableCameraButton()
                    ConnectButton()
                }
                .padding(.bottom, 12)
            }
        }
        .padding(16)
        .background(AppColors.messageBackground.opacity(0.95))
        .cornerRadius(16)
    }
}


