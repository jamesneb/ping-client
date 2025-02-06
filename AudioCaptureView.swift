import SwiftUI
import AVFoundation
import AppKit

struct AudioCaptureView: NSViewRepresentable {
    @Binding var inputGain: Float
    
    class Coordinator: NSObject {
        var captureSession: AVCaptureSession?
        var audioOutput: AVCaptureAudioDataOutput?
        var inputGain: Float = 1.0
        
        override init() {
            super.init()
            captureSession = AVCaptureSession()
        }
        
        func setupAudio(in view: NSView) {
            guard let captureSession = captureSession else { return }
            
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                guard granted else {
                    print("Error: Microphone access denied")
                    return
                }
                
                DispatchQueue.main.async {
                    self.configureMicrophone(captureSession)
                }
            }
        }
        
        private func configureMicrophone(_ captureSession: AVCaptureSession) {
            guard let audioDevice = AVCaptureDevice.default(for: .audio) else {
                print("Error: Microphone not found")
                return
            }
            
            do {
                let audioInput = try AVCaptureDeviceInput(device: audioDevice)
                if captureSession.canAddInput(audioInput) {
                    captureSession.addInput(audioInput)
                } else {
                    print("Error: Unable to add audio input to session")
                    return
                }
                
                let audioOutput = AVCaptureAudioDataOutput()
                if captureSession.canAddOutput(audioOutput) {
                    captureSession.addOutput(audioOutput)
                    self.audioOutput = audioOutput
                    
                    let queue = DispatchQueue(label: "audio.capture.queue")
                    audioOutput.setSampleBufferDelegate(self, queue: queue)
                } else {
                    print("Error: Unable to add audio output to session")
                    return
                }
                
                captureSession.startRunning()
                
            } catch {
                print("Error: Unable to access microphone - \(error)")
            }
        }
        
        func updateInputGain(_ gain: Float) {
            self.inputGain = gain
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        DispatchQueue.main.async {
            context.coordinator.setupAudio(in: view)
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.updateInputGain(inputGain)
    }
}

extension AudioCaptureView.Coordinator: AVCaptureAudioDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let audioBuffer = try? sampleBuffer.audioBufferList() else { return }
        
        // Get the first buffer (assuming mono audio)
        let buffer = audioBuffer.mBuffers
        
        guard let data = buffer.mData else { return }
        let length = Int(buffer.mDataByteSize) / MemoryLayout<Float>.size
        
        // Apply gain to the samples
        let ptr = data.assumingMemoryBound(to: Float.self)
        for i in 0..<length {
            ptr[i] *= inputGain
        }
    }
}

extension CMSampleBuffer {
    func audioBufferList() throws -> AudioBufferList {
        var audioBufferList = AudioBufferList()
        var blockBuffer: CMBlockBuffer?
        
        let status = CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(
            self,
            bufferListSizeNeededOut: nil,
            bufferListOut: &audioBufferList,
            bufferListSize: MemoryLayout<AudioBufferList>.size,
            blockBufferAllocator: nil,
            blockBufferMemoryAllocator: nil,
            flags: kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment,
            blockBufferOut: &blockBuffer
        )
        
        guard status == noErr else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
        }
        
        return audioBufferList
    }
}
