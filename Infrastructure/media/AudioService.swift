// internal/infrastructure/media/AudioService.swift
import Foundation
import AVFoundation
import Combine

class AudioService: NSObject, AudioServiceProtocol {
   private let volumeSubject = CurrentValueSubject<Float, Never>(0.0)
   private let stateSubject = CurrentValueSubject<MediaState, Never>(.inactive)
   private var audioEngine: AVAudioEngine?
   private var inputNode: AVAudioInputNode?
   private var currentGain: Float = 1.0
   
   var volumePublisher: AnyPublisher<Float, Never> {
       volumeSubject.eraseToAnyPublisher()
   }
   
   var state: AnyPublisher<MediaState, Never> {
       stateSubject.eraseToAnyPublisher()
   }
   
   func startMonitoring() async throws {
       let audioEngine = AVAudioEngine()
       self.audioEngine = audioEngine
       
       let inputNode = audioEngine.inputNode
       self.inputNode = inputNode
       
       let format = inputNode.outputFormat(forBus: 0)
       inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
           self?.processAudioBuffer(buffer)
       }
       
       do {
           try audioEngine.start()
           stateSubject.send(.active)
       } catch {
           throw MediaError.setupFailed(error)
       }
   }
   
   func stopMonitoring() {
       inputNode?.removeTap(onBus: 0)
       audioEngine?.stop()
       stateSubject.send(.inactive)
   }
   
   func updateInputGain(_ gain: Float) {
       currentGain = gain
   }
   
   private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
       let frameLength = buffer.frameLength
       let arraySize = Int(frameLength)
       var sum: Float = 0.0
       
       if let channelData = buffer.floatChannelData {
           let channelBuffer = channelData[0]
           for i in 0..<arraySize {
               let sample = channelBuffer[i] * currentGain
               sum += sample * sample
           }
       }
       
       let rms = sqrt(sum / Float(frameLength))
       DispatchQueue.main.async {
           self.volumeSubject.send(min(1.0, rms * 10))
       }
   }
   
   deinit {
       stopMonitoring()
   }
}
