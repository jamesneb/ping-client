import SwiftUI




@main
struct PingApp: App {
    @StateObject private var urlHandler = URLHandler()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            Group {
                switch urlHandler.currentRoute {
                case .login:
                    LoginView()
                        .frame(minWidth: 400, minHeight: 300)
                case .signup:
                    SignupView()
                        .frame(minWidth: 400, minHeight: 300)
                case .lobby:
                    ContentView()
                        .frame(minWidth: 800, minHeight: 800)
                case .meeting:
                    MeetingRoomView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .onAppear {
                            if let window = NSApplication.shared.windows.first {
                                window.toggleFullScreen(nil)
                            }
                        }
                case .controlPanel:
                    ControlPanelView()
                        .frame(minWidth: 500, minHeight: 400)
                }
            }
            .environmentObject(urlHandler)
            .onAppear {
                NotificationCenter.default.addObserver(forName: NSNotification.Name("HandleURL"), object: nil, queue: .main) { notification in
                    if let url = notification.object as? URL {
                        urlHandler.handleURL(url)
                    }
                }
            }
        }
        .windowStyle(.hiddenTitleBar)
        .handlesExternalEvents(matching: Set(arrayLiteral: "*"))
    }
}
// Rest of your URLHandler code remains the same

class URLHandler: ObservableObject {
    @Published var currentRoute: Route = .lobby
    
    enum Route {
        case login
        case signup
        case lobby
        case meeting
        case controlPanel
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
        case "controlPanel":
            currentRoute = .controlPanel
        default:
            currentRoute = .lobby
        }
    }
}
