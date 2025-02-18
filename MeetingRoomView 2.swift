import SwiftUI
import AVFoundation
import Foundation

struct MeetingRoomView: View {
    @StateObject private var viewModel = WebSocketViewModel()
    @EnvironmentObject private var audioViewModel: AudioMeterViewModel
    @State private var noiseImage: NSImage?
    @EnvironmentObject private var urlHandler: URLHandler
    @StateObject private var cameraViewModel = CameraViewModel()
    @State private var participants: [Participant] = [
        Participant(id: "1", nickname: "Alice", isOnline: true, isMuted: false, isVideoEnabled: true),
        Participant(id: "2", nickname: "Bob", isOnline: true, isMuted: true, isVideoEnabled: true),
        Participant(id: "3", nickname: "Charlie", isOnline: false, isMuted: false, isVideoEnabled: false),
        Participant(id: "4", nickname: "David", isOnline: true, isMuted: false, isVideoEnabled: true),
        Participant(id: "5", nickname: "Eve", isOnline: true, isMuted: true, isVideoEnabled: false),
        Participant(id: "6", nickname: "Frank", isOnline: true, isMuted: false, isVideoEnabled: true),
        Participant(id: "7", nickname: "Grace", isOnline: false, isMuted: true, isVideoEnabled: false),
        Participant(id: "8", nickname: "Henry", isOnline: true, isMuted: false, isVideoEnabled: true),
        Participant(id: "9", nickname: "Ivy", isOnline: true, isMuted: true, isVideoEnabled: false),
        Participant(id: "10", nickname: "Jack", isOnline: false, isMuted: false, isVideoEnabled: true),
        Participant(id: "11", nickname: "Kelly", isOnline: true, isMuted: true, isVideoEnabled: false),
        Participant(id: "12", nickname: "Liam", isOnline: true, isMuted: false, isVideoEnabled: true)
    ]
   
    var body: some View {
        HStack(spacing: 0) {
            ParticipantSidebar(participants: participants)
                .frame(width: 120)
            
            ZStack {
                if let image = noiseImage {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .ignoresSafeArea()
                }
                
                VStack(spacing: 0) {
                    Spacer()
                        .frame(maxHeight: 100)
                    
                    CameraView()
                        .environmentObject(cameraViewModel)
                        .frame(
                            minWidth: 400,
                            idealWidth: 800,
                            maxWidth: 800,
                            minHeight: 300,
                            idealHeight: 450,
                            maxHeight: 450
                        )
                        .layoutPriority(1)
                        .background(
                            ZStack {
                                Color.black.opacity(0.4)
                                LinearGradient(
                                    colors: [
                                        Color(hex: "4338CA").opacity(0.1),
                                        Color.clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            }
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            Color(hex: "4338CA").opacity(0.6),
                                            Color(hex: "4338CA").opacity(0.3)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                        .shadow(color: Color(hex: "4338CA").opacity(0.2), radius: 10, x: 0, y: 4)
                        .padding(.horizontal, 32)
                    
                    Spacer()
                        .frame(minHeight: 50, maxHeight: 200)
                    
                    CommandBar()
                        .environmentObject(cameraViewModel)
                        .padding(.bottom, 32)
                        .padding(.horizontal, 32)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            setupInitialState()
        }
    }
    
    private func setupInitialState() {
        noiseImage = loadNoiseImage(from: "background")
        participants = participants.sorted(by: { $0.nickname < $1.nickname })
        viewModel.connect()
        viewModel.sendMessage("GET PARTICIPANTS")
        audioViewModel.startMonitoring()
        cameraViewModel.startCapture()
    }
}

struct ParticipantSidebar: View {
    let participants: [Participant]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(participants) { participant in
                    ParticipantBadgeWithMenu(participant: participant)
                }
            }
            .padding(.vertical, 16)
        }
        .frame(width: 120)
        .background(
            ZStack {
                Color.black.opacity(0.8)
                    .background(.ultraThinMaterial)
                
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.1),
                        Color.white.opacity(0.05)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        )
        .scrollIndicators(.visible)
        .overlay(
            CustomScrollbar(),
            alignment: .trailing
        )
    }
}

struct CustomScrollbar: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        
        DispatchQueue.main.async {
            if let scrollView = view.enclosingScrollView {
                scrollView.hasVerticalScroller = true
                
                if let scroller = scrollView.verticalScroller {
                    scroller.alphaValue = 0.8
                    scroller.layer?.backgroundColor = NSColor(Color(hex: "4338CA").opacity(0.3)).cgColor
                }
                
                scrollView.drawsBackground = false
                scrollView.backgroundColor = .clear
            }
        }
        
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}

struct ParticipantBadgeWithMenu: View {
    let participant: Participant
    @State private var isHovered = false
    
    var body: some View {
        UserAvatarBadge(
            initial: String(participant.nickname.prefix(1)),
            isOnline: participant.isOnline
        )
        .onTapGesture { }
        .onHover { hovering in
            isHovered = hovering
        }
        .contextMenu {
            Button(action: {}) {
                Label(participant.isMuted ? "Unmute" : "Mute",
                      systemImage: participant.isMuted ? "mic" : "mic.slash")
            }
            
            Button(action: {}) {
                Label(participant.isVideoEnabled ? "Disable Video" : "Enable Video",
                      systemImage: participant.isVideoEnabled ? "video.slash" : "video")
            }
            
            Divider()
            
            Button(role: .destructive, action: {}) {
                Label("Remove from Call", systemImage: "person.fill.xmark")
            }
        }
    }
}

struct CommandBar: View {
    @EnvironmentObject private var audioViewModel: AudioMeterViewModel
    @EnvironmentObject private var cameraViewModel: CameraViewModel
    
    var body: some View {
        HStack(spacing: 20) {
            CommandButton(icon: !audioViewModel.isMonitoring ? "mic.slash.fill" : "mic.fill",
                          color: Color(hex: "34495E")) {
                print("toggling audio")
                if audioViewModel.isMonitoring {
                    audioViewModel.stopMonitoring()
                } else {
                    audioViewModel.startMonitoring()
                }
            }
            
            CommandButton(icon: cameraViewModel.isCapturing ? "video.fill" : "video.slash.fill",
                          color: Color(hex: "34495E")) {
                if cameraViewModel.isCapturing {
                    cameraViewModel.stopCapture()
                } else {
                    cameraViewModel.startCapture()
                }
            }
            
            CommandButton(icon: "hand.raised.fill", color: Color(hex: "34495E")) {
            }
            
            CommandButton(icon: "rectangle.on.rectangle.angled", color: Color(hex: "34495E")) {
            }
            
            CommandButton(icon: "arrow.up.left.and.arrow.down.right", color: Color(hex: "34495E")) {
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "2C3E50"))
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
            ZStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.7))
                    .offset(x: 0.5, y: 0.5)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.white)
            }
            .frame(width: 44, height: 44)
            .background(
                Circle()
                    .fill(color)
                    .overlay(
                        Circle()
                            .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
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

struct UserAvatarBadge: View {
    let initial: String
    let isOnline: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.black.opacity(0.1))
                .frame(width: 84, height: 84)
                .blur(radius: 8)
                .offset(y: 4)
            
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color(hex: "4338CA").opacity(0.3),
                            Color.clear
                        ]),
                        center: .center,
                        startRadius: 35,
                        endRadius: 50
                    )
                )
                .frame(width: 100, height: 100)
            
            Circle()
                .fill(
                    LinearGradient(
                        gradient: AppColors.primaryGradient,
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 50, height: 50)
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)

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
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .blur(radius: 2)
                )
            
            Text(initial)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 2)
            
            if isOnline {
                ZStack {
                    Circle()
                        .fill(Color(hex: "38BDF8").opacity(0.3))
                        .frame(width: 16, height: 16)
                        .blur(radius: 4)
                    
                    Circle()
                        .fill(Color(hex: "A5F3FC"))
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .strokeBorder(Color.white, lineWidth: 2)
                        )
                }
                .offset(x: 20, y: 20)
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

#Preview {
    MeetingRoomView()
        .environmentObject(URLHandler())
        .environmentObject(AudioMeterViewModel())
        .environmentObject(CameraViewModel())
}
