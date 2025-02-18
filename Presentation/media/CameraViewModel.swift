import Foundation
import SwiftUI
import Combine
import AVFoundation

class CameraViewModel: ObservableObject {
    @Published var isCapturing: Bool = false
    @Published var error: String?
    
    private let cameraService: CameraServiceProtocol
    private var cancellables: Set<AnyCancellable> = []
    
    init(cameraService: CameraServiceProtocol = CameraService()) {
        self.cameraService = cameraService
        setupSubscriptions()
    }
    
    func setupSubscriptions() {
        cameraService.state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                switch state {
                case .active:
                    self?.error = nil
                case .inactive:
                    self?.error = nil
                case .error(let error):
                    self?.error = error.localizedDescription
                }
            }
            .store(in: &cancellables)
        
        cameraService.isCapturingPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.isCapturing, on: self)
            .store(in: &cancellables)
    }
    
    func setupCamera(completion: @escaping (Result<AVCaptureSession, Error>) -> Void) {
        Task {
            do {
                try await cameraService.setupCamera()
                if let captureSession = cameraService.captureSession {
                    completion(.success(captureSession))
                } else {
                    completion(.failure(CameraError.captureSessionNotFound))
                }
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func startCapture() {
        cameraService.startCapture()
    }
    
    func stopCapture() {
        cameraService.stopCapture()
    }
    
    func updatePreviewFrame(_ frame: CGRect) {
        cameraService.updatePreviewFrame(frame)
    }
}

enum CameraError: Error {
    case captureSessionNotFound
}
