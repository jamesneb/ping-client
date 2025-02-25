import SwiftUI
import ScreenCaptureKit

class ScreenCaptureViewModel: NSObject, ObservableObject {
    @Published var latestFrame: NSImage?
    @Published var availableContent: SCShareableContent?
    @Published var isShowingSelection = false
    private var stream: SCStream?

    override init() {
        self.latestFrame = nil
        self.availableContent = nil
        self.isShowingSelection = false
        self.stream = nil
        
        super.init()
        
        Task { await self.fetchAvailableContent() }
    }

    func fetchAvailableContent() async {
        do {
            availableContent = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)
        } catch {
            print("Failed to fetch content: \(error)")
        }
    }

    func startScreenCapture() {
        Task { await beginStream() }
    }

    func startCaptureWithSelection(display: SCDisplay?, window: SCWindow?) {
        Task { await beginStream(display: display, window: window) }
    }

    func stopScreenCapture() {
        Task {
            do {
                try await stream?.stopCapture()
                stream = nil
            } catch {
                print("Failed to stop stream: \(error)")
            }
        }
    }

    private func beginStream(display: SCDisplay? = nil, window: SCWindow? = nil) async {
        do {
            let filter: SCContentFilter
            if let display = display {
                filter = SCContentFilter(display: display, excludingWindows: [])
            } else if let window = window {
                filter = SCContentFilter(desktopIndependentWindow: window)
            } else {
                guard let display = availableContent?.displays.first else { return }
                filter = SCContentFilter(display: display, excludingWindows: [])
            }

            let config = SCStreamConfiguration()
            config.width = 1920
            config.height = 1080
            config.minimumFrameInterval = CMTime(value: 1, timescale: 60)
            config.capturesAudio = true
            config.excludesCurrentProcessAudio = false

            stream = SCStream(filter: filter, configuration: config, delegate: nil)
            try stream?.addStreamOutput(self, type: .screen, sampleHandlerQueue: .main)
            try stream?.addStreamOutput(self, type: .audio, sampleHandlerQueue: .main)
            try await stream?.startCapture()
        } catch {
            print("Failed to start stream: \(error)")
        }
    }
}

extension ScreenCaptureViewModel: SCStreamOutput {
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        switch type {
        case .screen:
            guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            let ciImage = CIImage(cvImageBuffer: imageBuffer)
            let context = CIContext()
            if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
                let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: 1920, height: 1080))
                DispatchQueue.main.async {
                    self.latestFrame = nsImage
                }
            }
        case .audio:
            break
        @unknown default:
            break
        }
    }
}
