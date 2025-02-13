// internal/presentation/media/AudioMeterViewModel.swift
import Foundation
import Combine
import AVFoundation

class AudioMeterViewModel: ObservableObject {
    @Published var volume: Float = 0.0
    @Published var inputGain: Float = 1.0
    @Published var isMonitoring: Bool = false
    @Published var error: String?
    
    private let audioService: AudioServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(audioService: AudioServiceProtocol = AudioService()) {
        self.audioService = audioService
        setupSubscriptions()
    }
    
    private func setupSubscriptions() {
        // Subscribe to volume updates
        audioService.volumePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] volume in
                self?.volume = volume
            }
            .store(in: &cancellables)
            
        // Subscribe to state updates
        audioService.state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                switch state {
                case .active:
                    self?.isMonitoring = true
                    self?.error = nil
                case .inactive:
                    self?.isMonitoring = false
                    self?.error = nil
                case .error(let error):
                    self?.isMonitoring = false
                    self?.error = error.localizedDescription
                }
            }
            .store(in: &cancellables)
    }
    
    func startMonitoring() {
        Task {
            do {
                try await audioService.startMonitoring()
            } catch {
                DispatchQueue.main.async {
                    self.error = error.localizedDescription
                }
            }
        }
    }
    
    func stopMonitoring() {
        audioService.stopMonitoring()
    }
    
    func updateGain() {
        audioService.updateInputGain(inputGain)
    }
}
