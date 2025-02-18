// internal/domain/media/model.swift
import AVFoundation
import SwiftUI
import Combine

enum MediaError: Error {
    case deviceNotFound
    case accessDenied
    case setupFailed(Error)
    case captureError(Error)
}

enum MediaState {
    case inactive
    case active
    case error(MediaError)
}

protocol CameraServiceProtocol {
    var state: AnyPublisher<MediaState, Never> { get }
    var isCapturingPublisher: AnyPublisher<Bool, Never> { get }
    var captureSession: AVCaptureSession? { get }
    func setupCamera() async throws
    func startCapture()
    func stopCapture()
    func updatePreviewFrame(_ frame: CGRect)
}

protocol AudioServiceProtocol {
    var volumePublisher: AnyPublisher<Float, Never> { get }
    var state: AnyPublisher<MediaState, Never> { get }
    func startMonitoring() async throws
    func stopMonitoring()
    func updateInputGain(_ gain: Float)
}
