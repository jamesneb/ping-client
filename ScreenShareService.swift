//
//  ScreenShareService.swift
//  Ping
//
//  Created by James Nebeker on 2/18/25.
//

import Foundation
import ScreenCaptureKit
import AppKit

// ✅ Correct delegate implementation using an actor
class ScreenStreamHandler: NSObject, SCStreamDelegate, SCStreamOutput {
    weak var viewModel: ScreenCaptureViewModel?

    init(viewModel: ScreenCaptureViewModel) {
        self.viewModel = viewModel
    }

    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of outputType: SCStreamOutputType) {
        print("🔍 Received sample buffer: \(outputType)") // Debug log

        guard outputType == .screen, let imageBuffer = sampleBuffer.imageBuffer else {
            print("❌ Invalid sample buffer or wrong output type")
            return
        }

        print("✅ Processing frame...")

        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        let rep = NSCIImageRep(ciImage: ciImage)
        let nsImage = NSImage(size: rep.size)
        nsImage.addRepresentation(rep)

        DispatchQueue.main.async {
            self.viewModel?.latestFrame = nsImage
            print("🖼 Updated viewModel with new frame")
        }
    }
}



class ScreenCaptureViewModel: NSObject, ObservableObject { // Added NSObject
    @Published var latestFrame: NSImage?
    @Published var isShowingSelection = false
    @Published var availableContent: SCShareableContent?
    private var stream: SCStream?

    func startScreenCapture() {
        Task {
            do {
                let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
                await MainActor.run {
                    self.availableContent = content
                    self.isShowingSelection = true
                }
            } catch {
                print("Failed to get shareable content: \(error)")
            }
        }
    }

    func startCaptureWithSelection(display: SCDisplay?, window: SCWindow?) {
        Task {
            do {
                let filter: SCContentFilter
                if let display = display {
                    filter = SCContentFilter(display: display, excludingWindows: [])
                } else if let window = window {
                    filter = SCContentFilter(desktopIndependentWindow: window)
                } else {
                    return
                }

                let configuration = SCStreamConfiguration()
                configuration.width = 1920
                configuration.height = 1080
                configuration.minimumFrameInterval = CMTime(value: 1, timescale: 60)

                stream = SCStream(filter: filter, configuration: configuration, delegate: nil)
                try stream?.startCapture()
                try stream?.addStreamOutput(self, type: .screen, sampleHandlerQueue: .main)
            } catch {
                print("Failed to start capture: \(error)")
            }
        }
    }
}

extension ScreenCaptureViewModel: SCStreamOutput {
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let ciImage = CIImage(cvImageBuffer: imageBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }
        let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: 1920, height: 1080))
        DispatchQueue.main.async {
            self.latestFrame = nsImage
        }
    }
}
