import Foundation
import SwiftUI

import SwiftUI


struct Participant: Identifiable, Equatable, Decodable {
    let id: String
    let nickname: String
    let isOnline: Bool
    var isMuted: Bool
    var isVideoEnabled: Bool
    
    // Custom decoding can be added if your server's JSON keys don't match exactly
    enum CodingKeys: String, CodingKey {
        case id
        case nickname
        case isOnline = "is_online"      // Example if server uses snake_case
        case isMuted = "is_muted"
        case isVideoEnabled = "is_video_enabled"
    }
    
    // Custom decoding initialization if needed
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        nickname = try container.decode(String.self, forKey: .nickname)
        isOnline = try container.decode(Bool.self, forKey: .isOnline)
        isMuted = try container.decode(Bool.self, forKey: .isMuted)
        isVideoEnabled = try container.decode(Bool.self, forKey: .isVideoEnabled)
    }
    
    // Keep the original initializer for creating instances in code
    init(id: String, nickname: String, isOnline: Bool, isMuted: Bool, isVideoEnabled: Bool) {
        self.id = id
        self.nickname = nickname
        self.isOnline = isOnline
        self.isMuted = isMuted
        self.isVideoEnabled = isVideoEnabled
    }
}



public class UserData: ObservableObject {
    // Use static shared instance for singleton pattern
    static let shared = UserData()
    
    // Published property that will notify observers of changes
    @Published var nickname: String {
        didSet {
            // Save to UserDefaults whenever the value changes
            UserDefaults.standard.set(nickname, forKey: "userNickname")
        }
    }
    
    public init() {
        // Load saved nickname from UserDefaults, or use empty string if none exists
        self.nickname = UserDefaults.standard.string(forKey: "userNickname") ?? ""
    }
}


