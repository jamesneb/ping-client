import SwiftUI

@main
struct PingApp: App {
    @StateObject private var urlHandler = URLHandler()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            SignupView()
                .environmentObject(urlHandler)
                .onAppear {
                    NotificationCenter.default.addObserver(forName: NSNotification.Name("HandleURL"), object: nil, queue: .main) { notification in
                        if let url = notification.object as? URL {
                            urlHandler.handleURL(url)
                        }
                    }
                }
        }
        .handlesExternalEvents(matching: Set(arrayLiteral: "*"))
    }
}


class URLHandler: ObservableObject {
    @Published var currentRoute: Route = .login
    
    enum Route {
        case login
        case signup
        case lobby
        case meeting
    }
    
    func handleURL(_ url: URL) {
        guard url.scheme == "ping_app" else { return }
        
        switch url.host {
        case "signup":
            currentRoute = .signup
        case "lobby":
            currentRoute = .lobby
        case "meeting":
            currentRoute = .meeting
        case "login":
            currentRoute = .login
        default:
            currentRoute = .login
        }
    }
}
