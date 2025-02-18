//
//  CameraViewModel.swift
//  Ping
//
//  Created by James Nebeker on 2/17/25.
//

import Foundation
import SwiftUI
import Combine
import AVFoundation

class CameraViewModel: ObservableObject {
    @Published var isCapturing: Bool = false
    @Published var error: String?
    
    private let cameraService: CameraServiceProtocol
    private var cancellables: Set<AnyCancellable> = []
    var captureSession: AVCaptureSession?
    var previewLayer = AVCaptureVideoPreviewLayer()
    
    init(cameraService: CameraServiceProtocol = CameraServiceProtocol())
    {
        self.cameraService = cameraService
        setupSubscriptions()
    }
    
    func setupSubscriptions() {
        cameraService.state.receive(on: DispatchQueue.main).sink { [weak self] state in
            switch state {
            case .active:
                self?.isCapturing = true
                self?.error = nil
            case .inactive:
                self?.isCapturing = false
                self?.error = nil
            case .error(let error):
                self?.isCapturing = false
                self?.error = error.localizedDescription
            }
        }
        .store(in: &cancellables)
    }
    
    
}
