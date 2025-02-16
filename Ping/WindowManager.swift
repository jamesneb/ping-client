import SwiftUI
import Foundation

class WindowManager: ObservableObject {
    func openMeetingRoom(nickname: String, passcode: String) {
        // Create a new window for the meeting room
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.center()
        window.setFrameAutosaveName("Meeting Room")
        window.title = "Meeting Room"
        window.isReleasedWhenClosed = false
        
        // Create and set up the meeting room view
        let meetingView = MeetingRoomView(
          
        )
        
        window.contentView = NSHostingView(rootView: meetingView)
        window.makeKeyAndOrderFront(nil)
    }
}
