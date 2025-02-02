//
//  websocket.swift
//  Ping
//
//  Created by James Nebeker on 2/2/25.
//

import Foundation

public enum WebSocketConnectionError: Error {
    case connectionError
    case transportError
    case encodingError
    case decodingError
    case disconnected
    case closed
}

public final class WebSocketConnection<Incoming: Decodable & Sendable, Outgoing: Encodable & Sendable>: NSObject, Sendable {
    
    private let webSocketTask: URLSessionWebSocketTask
    
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    
    internal init(webSocketTask: URLSessionWebSocketTask, encoder: JSONEncoder, decoder: JSONDecoder) {
        self.webSocketTask = webSocketTask
        self.encoder = encoder
        self.decoder = decoder
        
        super.init()
        
        webSocketTask.resume()
    }
    
    deinit {
        // Make sure to cancel the WebSocket task (if not already closed)
        
        webSocketTask.cancel(with: .goingAway, reason: nil)
    }
    
    private func receiveSingleMessage() async throws -> Incoming {
        switch try await webSocketTask.receive() {
        case let .data(messageData):
            guard let message = try? decoder.decode(Incoming.self, from: messageData) else {
                throw WebSocketConnectionError.decodingError
            }
            return message
            
        case let .string(text): // Corrected this line
            guard
                let messageData = text.data(using: .utf8),
                let message = try? decoder.decode(Incoming.self, from: messageData)
            else {
                throw WebSocketConnectionError.decodingError
            }
            return message

        @unknown default:
            assertionFailure("unknown message type")
            webSocketTask.cancel(with: .unsupportedData, reason: nil)
            throw WebSocketConnectionError.decodingError
        }
    }


   
}

// MARK: Public Interface

extension WebSocketConnection {
    func send(_ message: Outgoing) async throws {
        guard let messageData = try? encoder.encode(message) else {
            throw WebSocketConnectionError.encodingError
        }
        
        do {
            try await  webSocketTask.send(.data(messageData))
        } catch {
            switch webSocketTask.closeCode {
            case .invalid:
                throw WebSocketConnectionError.connectionError
                
            case .goingAway:
                throw WebSocketConnectionError.disconnected
                
            case .normalClosure:
                throw WebSocketConnectionError.closed
            default:
                throw WebSocketConnectionError.transportError
            }
        }
        
    }
    
    func receiveOnce() async throws -> Incoming {
        do {
            return try await receiveSingleMessage()
        } catch let error as WebSocketConnectionError {
            throw error
        } catch  {
            switch webSocketTask.closeCode {
            case .invalid:
                throw WebSocketConnectionError.connectionError
            case .goingAway:
                throw WebSocketConnectionError.disconnected
            case .normalClosure:
                throw WebSocketConnectionError.closed
            default:
                throw WebSocketConnectionError.transportError
            }
        }
    }
    
    func receive() ->   AsyncThrowingStream<Incoming, Error> {
        AsyncThrowingStream { [weak self] in
        
            guard let self else {
                return nil
            }
            
            let message = try await self.receiveOnce()
            
            return Task.isCancelled ? nil : message
        }
        
    }
    
    func close() {
        webSocketTask.cancel(with: .normalClosure, reason: nil)
    }
}
