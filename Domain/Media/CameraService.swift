// internal/infrastructure/media/CameraService.swift
import AVFoundation
import Combine
import SwiftUI

class CameraService: NSObject, CameraServiceProtocol {
    private let stateSubject = CurrentValueSubject<MediaState, Never>(.inactive)
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    var state: AnyPublisher<MediaState, Never> {
        stateSubject.eraseToAnyPublisher()
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
            }
        }
    }
    
    func stopCapture() {
        guard let captureSession = captureSession else { return }
        
        if captureSession.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                captureSession.stopRunning()
            }
        }
    }
    
    func configurePreviewLayer(for view: NSView) {
        guard let captureSession = captureSession else { return }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer = previewLayer
        view.wantsLayer = true
        self.previewLayer = previewLayer
    }
    
    func updatePreviewFrame(_ bounds: CGRect) {
        previewLayer?.frame = bounds
    }
}
