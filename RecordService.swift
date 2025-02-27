import ReplayKit
import AVFoundation
import Combine

class RecordingService: NSObject, ObservableObject {
    @Published var isRecording = false
    private let recorder = RPScreenRecorder.shared()
    private var lastRecordingURL: URL?
    
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
        
        // Store the URL for the recording we're about to save
        self.lastRecordingURL = outputURL
        
        recorder.stopRecording(withOutput: outputURL) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Failed to stop recording: \(error.localizedDescription)")
                    // Clear the URL if there was an error
                    self?.lastRecordingURL = nil
                } else {
                    print("Recording saved to: \(outputURL.path)")
                }
                self?.isRecording = false
            }
        }
    }
    
    func getLastRecordingURL() -> URL? {
        // If we have a stored URL and the file exists, return it
        if let url = lastRecordingURL, FileManager.default.fileExists(atPath: url.path) {
            return url
        }
        
        // Fallback: Find the most recent recording in the Documents directory
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: documentsPath,
                includingPropertiesForKeys: [.creationDateKey],
                options: .skipsHiddenFiles
            )
            
            // Filter for mp4 files that match our naming pattern
            let recordings = fileURLs.filter { $0.pathExtension == "mp4" && $0.lastPathComponent.hasPrefix("recording_") }
            
            // Sort by creation date (newest first)
            let sortedRecordings = try recordings.sorted { url1, url2 in
                let date1 = try url1.resourceValues(forKeys: [.creationDateKey]).creationDate ?? Date.distantPast
                let date2 = try url2.resourceValues(forKeys: [.creationDateKey]).creationDate ?? Date.distantPast
                return date1 > date2
            }
            
            // Return the most recent recording
            if let mostRecentURL = sortedRecordings.first {
                // Cache this result
                lastRecordingURL = mostRecentURL
                return mostRecentURL
            }
        } catch {
            print("Error finding recordings: \(error)")
        }
        
        return nil
    }
}
