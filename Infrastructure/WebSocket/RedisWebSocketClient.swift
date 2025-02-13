import Foundation
import Combine

class RedisWebSocketClient: NSObject {
    private var webSocket: URLSessionWebSocketTask?
    private var session: URLSession?
    private let url: URL
    private let stateSubject = CurrentValueSubject<WebSocketState, Never>(.disconnected)
    private var cancellables = Set<AnyCancellable>()
    
    // Protocol properties
    var onMessageReceived: ((WebSocketMessage) -> Void)?
    var state: AnyPublisher<WebSocketState, Never> {
        stateSubject.eraseToAnyPublisher()
    }
    
    init?(urlString: String) {
        guard let url = URL(string: urlString) else {
            return nil
        }
        self.url = url
        super.init()
        setupSession()
    }
}

// Protocol conformance
extension RedisWebSocketClient: WebSocketClientProtocol {
    func connect() {
        guard stateSubject.value == .disconnected else { return }
        
        stateSubject.send(.connecting)
        webSocket = session?.webSocketTask(with: url)
        webSocket?.resume()
        listenForMessages()
    }
    
    func disconnect() {
        webSocket?.cancel(with: .goingAway, reason: nil)
        stateSubject.send(.disconnected)
        print("🔴 WebSocket connection closed")
    }
    
    func sendMessage(_ message: String) {
        let wsMessage = URLSessionWebSocketTask.Message.string(message)
        webSocket?.send(wsMessage) { [weak self] error in
            if let error = error {
                self?.handleError(.messageFailed(error))
                print("❌ Failed to send message: \(error.localizedDescription)")
            } else {
                print("✅ Message sent: \(message)")
            }
        }
    }
}

// WebSocket delegate
extension RedisWebSocketClient: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        DispatchQueue.main.async {
            self.stateSubject.send(.connected)
        }
        print("🟢 WebSocket connected successfully!")
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        DispatchQueue.main.async {
            self.stateSubject.send(.disconnected)
        }
        print("🔴 WebSocket disconnected. Reason: \(String(describing: reason))")
    }
}

// Private helpers
private extension RedisWebSocketClient {
    func setupSession() {
        session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    }
    
    func listenForMessages() {
        webSocket?.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let message):
                self.handleMessage(message)
                // Continue listening if still connected
                if self.stateSubject.value == .connected {
                    self.listenForMessages()
                }
            case .failure(let error):
                self.handleError(.messageFailed(error))
            }
        }
    }
    
    func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        let wsMessage: WebSocketMessage
        switch message {
        case .string(let text):
            wsMessage = WebSocketMessage(type: .text(text))
            print("📩 Received message: \(text)")
        case .data(let data):
            wsMessage = WebSocketMessage(type: .data(data))
            print("📩 Received data message")
        @unknown default:
            wsMessage = WebSocketMessage(type: .unknown)
            print("❓ Received unknown message type")
        }
        
        DispatchQueue.main.async {
            self.onMessageReceived?(wsMessage)
        }
    }
    
    func handleError(_ error: WebSocketError) {
        DispatchQueue.main.async {
            self.stateSubject.send(.error(error))
        }
        print("❌ WebSocket error: \(error)")
    }
}
