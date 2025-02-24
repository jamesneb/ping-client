//
//  RecordService.swift
//  Ping
//
//  Created by James Nebeker on 2/23/25.
//

import Foundation
import ScreenCaptureKit
import AVFoundation

class RecordingService: ObservableObject {
        
   func startVideoCapture() async {
        do {
            let sc = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            guard let window = sc.windows.first(where: { $0.owningApplication?.bundleIdentifier == Bundle.main.bundleIdentifier }) else {
                    print("No window found")
                    return
            }
            let filter = SCContentFilter(desktopIndependentWindow: window)
        } catch {
            
        }
    }
}
