import Foundation
import Combine

class WebSocketService: WebSocketServiceProtocol {
    private var client: WebSocketClientProtocol
    private let messageSubject = PassthroughSubject<String, Never>()
    private var cancellables = Set<AnyCancellable>()
    
    var messagePublisher: AnyPublisher<String, Never> {
        messageSubject.eraseToAnyPublisher()
    }
    
    var statePublisher: AnyPublisher<WebSocketState, Never> {
        client.state
    }
    
    init(client: WebSocketClientProtocol) {
        self.client = client
        setupMessageHandling()
    }
    
    private func setupMessageHandling() {
        client.onMessageReceived = { [weak self] message in
            if case .text(let text) = message.type {
                DispatchQueue.main.async {
                    self?.messageSubject.send(text)
                }
            }
        }
    }
    
    func connect() {
        client.connect()
    }
    
    func disconnect() {
        client.disconnect()
    }
    
    func sendMessage(_ message: String) {
        client.sendMessage(message)
    }
}

// MARK: - Factory
class WebSocketServiceFactory {
    static func createService(urlString: String) -> WebSocketService? {
        guard let client = RedisWebSocketClient(urlString: urlString) else {
            return nil
        }
        return WebSocketService(client: client)
    }
}
