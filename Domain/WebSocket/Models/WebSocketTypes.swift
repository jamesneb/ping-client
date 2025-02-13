// WebSocketTypes.swift
import Foundation
import Combine

enum WebSocketMessageType {
    case text(String)
    case data(Data)
    case unknown
}

struct WebSocketMessage {
    let type: WebSocketMessageType
    let timestamp: Date
    
    init(type: WebSocketMessageType, timestamp: Date = Date()) {
        self.type = type
        self.timestamp = timestamp
    }
}

enum WebSocketState: Equatable {
    case disconnected
    case connecting
    case connected
    case error(WebSocketError)
    
    static func == (lhs: WebSocketState, rhs: WebSocketState) -> Bool {
        switch (lhs, rhs) {
        case (.disconnected, .disconnected),
             (.connecting, .connecting),
             (.connected, .connected):
            return true
        case (.error(let lhsError), .error(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}

enum WebSocketError: Error, Equatable {
    case invalidURL
    case connectionFailed(Error)
    case messageFailed(Error)
    case disconnected(Error?)
    
    static func == (lhs: WebSocketError, rhs: WebSocketError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL):
            return true
        case (.connectionFailed(let lhsError), .connectionFailed(let rhsError)),
             (.messageFailed(let lhsError), .messageFailed(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        case (.disconnected(let lhsError), .disconnected(let rhsError)):
            return lhsError?.localizedDescription == rhsError?.localizedDescription
        default:
            return false
        }
    }
}

protocol WebSocketClientProtocol {
    var onMessageReceived: ((WebSocketMessage) -> Void)? { get set }
    var state: AnyPublisher<WebSocketState, Never> { get }
    func connect()
    func disconnect()
    func sendMessage(_ message: String)
}

protocol WebSocketServiceProtocol {
    var messagePublisher: AnyPublisher<String, Never> { get }
    var statePublisher: AnyPublisher<WebSocketState, Never> { get }
    func connect()
    func disconnect()
    func sendMessage(_ message: String)
}
