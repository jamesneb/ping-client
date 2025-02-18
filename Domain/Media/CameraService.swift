import AVFoundation
import Combine
import SwiftUI

class CameraService: NSObject, CameraServiceProtocol {
    private let stateSubject = CurrentValueSubject<MediaState, Never>(.inactive)
    private(set) var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    @Published private(set) var isCapturing: Bool = false
    
    var state: AnyPublisher<MediaState, Never> {
        stateSubject.eraseToAnyPublisher()
    }
    
    var isCapturingPublisher: AnyPublisher<Bool, Never> {
        $isCapturing.eraseToAnyPublisher()
    }
    
    func setupCamera() async throws {
        let captureSession = AVCaptureSession()
        self.captureSession = captureSession
        
        guard let device = AVCaptureDevice.default(for: .video) else {
            throw MediaError.deviceNotFound
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            } else {
                throw MediaError.setupFailed(NSError(domain: "CameraService", code: -1, userInfo: nil))
            }
        } catch {
            throw MediaError.setupFailed(error)
        }
        
        stateSubject.send(.active)
    }
    
    func startCapture() {
        guard let captureSession = captureSession else { return }
        
        if !captureSession.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                captureSession.startRunning()
                DispatchQueue.main.async {
                    self.isCapturing = true
                }
            }
        }
    }
    
    func stopCapture() {
        guard let captureSession = captureSession else { return }
        
        if captureSession.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                captureSession.stopRunning()
                DispatchQueue.main.async {
                    self.isCapturing = false
                }
            }
        }
    }
    
    func updatePreviewFrame(_ frame: CGRect) {
        previewLayer?.frame = frame
    }
}
