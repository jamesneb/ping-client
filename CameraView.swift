import SwiftUI
import AVFoundation
import AppKit

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
            
            self.previewLayer = previewLayer // Store reference for resizing
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

