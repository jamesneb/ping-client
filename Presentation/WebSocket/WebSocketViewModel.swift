import Foundation
import Combine
import SwiftUI

class WebSocketViewModel: ObservableObject {
    @Published var receivedMessage: String = "No users in call..."
    @Published var connectionState: WebSocketState = .disconnected
    
    private let webSocketService: WebSocketServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(urlString: String = "ws://127.0.0.1:8080/ws") {
        guard let service = WebSocketServiceFactory.createService(urlString: urlString) else {
            self.webSocketService = MockWebSocketService()
            return
        }
        self.webSocketService = service
        setupSubscriptions()
    }
    
    private func setupSubscriptions() {
        // Subscribe to messages
        webSocketService.messagePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.receivedMessage = message
            }
            .store(in: &cancellables)
        
        // Subscribe to connection state
        webSocketService.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.connectionState = state
            }
            .store(in: &cancellables)
    }
    
    func connect() {
        webSocketService.connect()
    }
    
    func disconnect() {
        webSocketService.disconnect()
    }
    
    func sendMessage(_ message: String) {
        webSocketService.sendMessage(message)
    }
}

// MARK: - Mock Service for Preview and Testing
private class MockWebSocketService: WebSocketServiceProtocol {
    private let messageSubject = PassthroughSubject<String, Never>()
    private let stateSubject = CurrentValueSubject<WebSocketState, Never>(.disconnected)
    
    var messagePublisher: AnyPublisher<String, Never> {
        messageSubject.eraseToAnyPublisher()
    }
    
    var statePublisher: AnyPublisher<WebSocketState, Never> {
        stateSubject.eraseToAnyPublisher()
    }
    
    func connect() {
        stateSubject.send(.connected)
    }
    
    func disconnect() {
        stateSubject.send(.disconnected)
    }
    
    func sendMessage(_ message: String) {
        messageSubject.send("Mock response to: \(message)")
    }
}

// MARK: - State Convenience Properties
extension WebSocketViewModel {
    var isConnected: Bool {
        if case .connected = connectionState {
            return true
        }
        return false
    }
    
    var isConnecting: Bool {
        if case .connecting = connectionState {
            return true
        }
        return false
    }
    
    var connectionError: String? {
        if case .error(let error) = connectionState {
            return error.localizedDescription
        }
        return nil
    }
}
