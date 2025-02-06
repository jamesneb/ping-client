import Foundation
import Combine

// MARK: - WebSocket Client
class RedisClient: NSObject, URLSessionWebSocketDelegate {
    private var webSocket: URLSessionWebSocketTask?
    private var session: URLSession?

    var onMessageReceived: ((String) -> Void)?

    init(url: URL) {
        super.init()

        session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        self.webSocket = session?.webSocketTask(with: url)
        self.webSocket?.resume()

        print("🔗 WebSocket connecting to \(url.absoluteString)")
        
        listenForMessages()
    }

    // ✅ Listen for messages continuously
    private func listenForMessages() {
        webSocket?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    print("📩 Received message: \(text)")
                    self?.onMessageReceived?(text)
                default:
                    print("❓ Received unknown message type")
                }
            case .failure(let error):
                print("❌ WebSocket error: \(error.localizedDescription)")
            }

            // ✅ Keep listening for new messages
            self?.listenForMessages()
        }
    }

    // ✅ Send a message over WebSocket
    func sendMessage(_ message: String) {
        guard let webSocket = webSocket else {
            print("❌ WebSocket is nil, cannot send message")
            return
        }

        let wsMessage = URLSessionWebSocketTask.Message.string(message)
        webSocket.send(wsMessage) { error in
            if let error = error {
                print("❌ Failed to send message: \(error.localizedDescription)")
            } else {
                print("✅ Message sent: \(message)")
            }
        }
    }

    // ✅ Close WebSocket connection
    func closeConnection() {
        webSocket?.cancel(with: .goingAway, reason: nil)
        print("🔴 WebSocket connection closed")
    }

    // ✅ WebSocket connection successful
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("🟢 WebSocket connected successfully!")
    }

    // ✅ WebSocket connection closed
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("🔴 WebSocket disconnected. Reason: \(String(describing: reason))")
    }
}

// MARK: - WebSocket ViewModel
class WebSocketViewModel: ObservableObject {
    @Published var receivedMessage: String = "No users in call..."
    private var redisClient: RedisClient?

    init() {
        connect()
    }

    func connect() {
        guard let url = URL(string: "ws://127.0.0.1:8080/ws") else {
            print("❌ Invalid WebSocket URL")
            return
        }
        redisClient = RedisClient(url: url)

        // Listen for new messages and update @Published property
        redisClient?.onMessageReceived = { [weak self] message in
            DispatchQueue.main.async {
                self?.receivedMessage = message
            }
        }
    }

    func sendMessage(_ message: String) {
        redisClient?.sendMessage(message)
    }

    func disconnect() {
        redisClient?.closeConnection()
    }
}
