import SwiftUI
import AVFoundation


struct CameraView: NSViewRepresentable {
    @EnvironmentObject private var cameraViewModel: CameraViewModel
    
    func makeCoordinator() -> Coordinator {
        Coordinator(cameraViewModel: cameraViewModel)
    }
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        context.coordinator.setupCamera(in: view)
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.updateFrame(to: nsView.bounds)
    }
    
    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        coordinator.stopCaptureSession()
    }
    
    class Coordinator: NSObject {
        private let cameraViewModel: CameraViewModel
        
        init(cameraViewModel: CameraViewModel) {
            self.cameraViewModel = cameraViewModel
        }
        
        func setupCamera(in view: NSView) {
            cameraViewModel.setupCamera { result in
                switch result {
                case .success(let captureSession):
                    DispatchQueue.main.async {
                        self.configurePreviewLayer(session: captureSession, in: view)
                        captureSession.startRunning()
                    }
                case .failure(let error):
                    print("Error setting up camera: \(error)")
                }
            }
        }
        
        func configurePreviewLayer(session: AVCaptureSession, in view: NSView) {
            let previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.frame = view.bounds
            view.layer = previewLayer
            view.wantsLayer = true
        }
        
        func updateFrame(to bounds: CGRect) {
            cameraViewModel.updatePreviewFrame(bounds)
        }
        
        func stopCaptureSession() {
            cameraViewModel.stopCapture()
        }
    }
}
