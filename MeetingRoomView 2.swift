import SwiftUI
import Foundation

struct MeetingRoomView: View {
    @StateObject private var viewModel = WebSocketViewModel()
    @State private var noiseImage: NSImage?
    @EnvironmentObject private var urlHandler: URLHandler
    @State private var participants: [Participant] = [
        Participant(id: "1", nickname: "Alice", isOnline: true, isMuted: false, isVideoEnabled: true),
        Participant(id: "2", nickname: "Bob", isOnline: true, isMuted: true, isVideoEnabled: true),
        Participant(id: "3", nickname: "Charlie", isOnline: false, isMuted: false, isVideoEnabled: false),
        Participant(id: "4", nickname: "David", isOnline: true, isMuted: false, isVideoEnabled: true),
        Participant(id: "5", nickname: "Eve", isOnline: true, isMuted: true, isVideoEnabled: false)
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
            
            VStack {
                // Participant Section
                ScrollView(.horizontal, showsIndicators: true) {
                    LazyHStack(spacing: 24) {
                        ForEach(participants) { participant in
                            UserAvatarBadge(
                                initial: String(participant.nickname.prefix(1)),
                                isOnline: participant.isOnline
                            )
                            .contextMenu {
                                Button(action: {
                                    // Toggle mute
                                }) {
                                    Label(participant.isMuted ? "Unmute" : "Mute",
                                          systemImage: participant.isMuted ? "mic" : "mic.slash")
                                }
                                
                                Button(action: {
                                    // Toggle video
                                }) {
                                    Label(participant.isVideoEnabled ? "Disable Video" : "Enable Video",
                                          systemImage: participant.isVideoEnabled ? "video.slash" : "video")
                                }
                                
                                Divider()
                                
                                Button(role: .destructive, action: {
                                    // Remove participant
                                }) {
                                    Label("Remove from Call", systemImage: "person.fill.xmark")
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 32)
                }
                .frame(height: 120)
                
                Spacer()
                
                // Command Bar
                CommandBar()
                    .padding(.bottom, 32)
            }
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

struct CommandBar: View {
    @State private var isMuted = false
    @State private var isVideoEnabled = true
    
    var body: some View {
        HStack(spacing: 20) {
            CommandButton(icon: isMuted ? "mic.slash.fill" : "mic.fill",
                         color: isMuted ? .red : Color(hex: "E5625E")) {
                isMuted.toggle()
            }
            
            CommandButton(icon: isVideoEnabled ? "video.fill" : "video.slash.fill",
                         color: isVideoEnabled ? Color(hex: "E5625E") : .red) {
                isVideoEnabled.toggle()
            }
            
            CommandButton(icon: "hand.raise.fill", color: Color(hex: "E5625E")) {
                // Raise hand action
            }
            
            CommandButton(icon: "rectangle.3.group.fill", color: Color(hex: "E5625E")) {
                // Layout action
            }
            
            CommandButton(icon: "arrow.up.left.and.arrow.down.right", color: Color(hex: "E5625E")) {
                // Share screen action
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

struct CommandButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(color)
                        .shadow(color: color.opacity(0.5), radius: 8, x: 0, y: 4)
                )
        }
        .buttonStyle(CommandButtonStyle())
    }
}

struct CommandButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// Keep your existing UserAvatarBadge implementation
// ... [Previous UserAvatarBadge code here]

// Keep your existing Color extension
// ... [Previous Color extension code here]

struct MeetingRoomView_Previews: PreviewProvider {
    static var previews: some View {
        MeetingRoomView()
            .environmentObject(URLHandler())
    }
}
struct UserCommandDock: View {
    var body: some View {
        ZStack {
            HStack {
                Button(action: { }) {
                    Text("Poop")
                }
                .frame(width: 500, height: 50)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.indigo, style: StrokeStyle(lineWidth: 2))
                )
                .buttonStyle(.plain)
                .background(.clear)
            }
        }
    }
}

struct UserAvatarBadge: View {
    let initial: String
    let isOnline: Bool
    
    var body: some View {
        ZStack {
            // Enhanced shadow effect with multiple layers
            Circle()
                .fill(Color.black.opacity(0.1))
                .frame(width: 84, height: 84)
                .blur(radius: 8)
                .offset(y: 4)
            
            // Outer glow effect
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color(hex: "E5625E").opacity(0.3),
                            Color.clear
                        ]),
                        center: .center,
                        startRadius: 35,
                        endRadius: 50
                    )
                )
                .frame(width: 100, height: 100)
            
            // Main avatar circle with gradient
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(hex: "E5625E").opacity(0.8),
                            Color(hex: "E5625E")
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 80, height: 80)
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
            
            // Inner highlight ring
            Circle()
                .strokeBorder(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.6),
                            Color.white.opacity(0.2)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .frame(width: 74, height: 74)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .blur(radius: 2)
                )
            
            // User's initial letter with subtle shadow
            Text(initial)
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(.white)
                .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 2)
            
            // Enhanced online status indicator
            if isOnline {
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(Color(hex: "4AD1B3").opacity(0.3))
                        .frame(width: 32, height: 32)
                        .blur(radius: 4)
                    
                    // Main indicator
                    Circle()
                        .fill(Color(hex: "4AD1B3"))
                        .frame(width: 24, height: 24)
                        .overlay(
                            Circle()
                                .strokeBorder(Color.white, lineWidth: 2)
                        )
                }
                .offset(x: 28, y: 28)
            }
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255.0
        let g = Double((int >> 8) & 0xFF) / 255.0
        let b = Double(int & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Preview Provider
#Preview {
    MeetingRoomView()
        .environmentObject(URLHandler())
}
