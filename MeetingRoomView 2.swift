import SwiftUI
import Foundation

struct MeetingRoomView: View {
    @StateObject private var viewModel = WebSocketViewModel()
    @State private var noiseImage: NSImage?
    @EnvironmentObject private var urlHandler: URLHandler
    @State private var participants: [Participant] = [
        Participant(id: "1", nickname: "Alice", isOnline: true, isMuted: false, isVideoEnabled: true),
        Participant(id: "2", nickname: "Bob", isOnline: true, isMuted: true, isVideoEnabled: true),
        Participant(id: "3", nickname: "Charlie", isOnline: false, isMuted: false, isVideoEnabled: false)
    ]
    
    var body: some View {
        ZStack {
            // Background Layer
            if let image = noiseImage {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
            }
            
            // User Avatars Grid
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 100, maximum: 150))
            ], spacing: 20) {
                ForEach(participants) { participant in
                    UserAvatarBadge(
                        initial: String(participant.nickname.prefix(1)),
                        isOnline: participant.isOnline
                    )
                }
            }
            .padding(32)
        }
        .onAppear {
            setupInitialState()
        }
    }
    
    private func setupInitialState() {
        noiseImage = loadNoiseImage(from: "background")
        viewModel.connect()
        viewModel.sendMessage("GET PARTICIPANTS")
    }
}
struct UserAvatarBadge: View {
    let initial: String
    let isOnline: Bool
    
    var body: some View {
        ZStack {
            // Main avatar circle with gradient
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.blue.opacity(0.6),
                            Color.blue.opacity(0.8)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 48, height: 48)
                .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
            
            // Inner circle with blur effect
            Circle()
                .strokeBorder(Color.white.opacity(0.2), lineWidth: 2)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .blur(radius: 2)
                )
            
            // User's initial letter
            Text(initial)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            // Online status indicator
            if isOnline {
                Circle()
                    .fill(Color.green)
                    .frame(width: 16, height: 16)
                    .overlay(
                        Circle()
                            .strokeBorder(Color.white, lineWidth: 2)
                    )
                    .offset(x: 16, y: 16)
            }
        }
    }
}
