import ReplayKit
import AVFoundation
import Combine

class RecordingService: NSObject, ObservableObject {
    @Published var isRecording = false
    private let recorder = RPScreenRecorder.shared()
    
    override init() {
        super.init()
        recorder.isMicrophoneEnabled = true
    }
    
    func startCapture() {
        guard !isRecording else { return }
        
        recorder.startRecording { [weak self] error in
            if let error = error {
                print("Failed to start recording: \(error.localizedDescription)")
                return
            }
            
            DispatchQueue.main.async {
                self?.isRecording = true
                print("Recording started")
            }
        }
    }
    
    func stopCapture() {
        guard isRecording else { return }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = dateFormatter.string(from: Date())
        let outputURL = documentsPath.appendingPathComponent("recording_\(timestamp).mp4")
        
        recorder.stopRecording(withOutput: outputURL) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Failed to stop recording: \(error.localizedDescription)")
                } else {
                    print("Recording saved to: \(outputURL.path)")
                }
                self?.isRecording = false
            }
        }
    }
}
