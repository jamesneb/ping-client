import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func application(_ application: NSApplication, open urls: [URL]) {
        if let url = urls.first {
            NotificationCenter.default.post(name: NSNotification.Name("HandleURL"), object: url)
        }
    }
}
