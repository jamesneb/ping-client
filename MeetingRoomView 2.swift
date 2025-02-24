

import Foundation
import AppKit
import SwiftUI
import Combine
import AVFoundation

struct MeetingRoomView: View {
    @StateObject private var screenCaptureModel = ScreenCaptureViewModel()
    @StateObject private var viewModel = WebSocketViewModel()
    @EnvironmentObject private var audioViewModel: AudioMeterViewModel
    @State private var noiseImage: NSImage?
    @EnvironmentObject private var urlHandler: URLHandler
    @StateObject private var cameraViewModel = CameraViewModel()
    @State private var wantsScreenShare: Bool = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                backgroundView(geometry: geometry)
                
                HStack(spacing: 0) {
                    ParticipantSidebar(
                        participants: [
                            Participant(id: "1", nickname: "Alice", isOnline: true, isMuted: false, isVideoEnabled: true),
                            Participant(id: "2", nickname: "Bob", isOnline: true, isMuted: true, isVideoEnabled: true),
                            Participant(id: "3", nickname: "Charlie", isOnline: false, isMuted: false, isVideoEnabled: false),
                            Participant(id: "4", nickname: "David", isOnline: true, isMuted: false, isVideoEnabled: true),
                            Participant(id: "5", nickname: "Eve", isOnline: true, isMuted: true, isVideoEnabled: false),
                            Participant(id: "6", nickname: "Frank", isOnline: true, isMuted: false, isVideoEnabled: true)
                        ]
                    )
                    .frame(width: 210)

                    HStack {
                        Spacer()

                        VStack(spacing: 0) {
                            Spacer().frame(height: max(0, geometry.size.height * 0.1))

                            // Updated layout with RecordButton to the side
                            HStack(spacing: 20) {
                                if !wantsScreenShare {
                                    cameraSection(geometry: geometry)
                                } else {
                                    ScreenShareView(screenCaptureViewModel: screenCaptureModel)
                                        .environmentObject(cameraViewModel)
                                        .frame(
                                            width: min(geometry.size.width * 0.8, 1200),
                                            height: min(geometry.size.height * 0.5, 600)
                                        )
                                    
                                }
                                
                                ButtonPane(wantsScreenShare: $wantsScreenShare)
                                        .environmentObject(cameraViewModel)
                                        .environmentObject(screenCaptureModel)
                            
                               
                            }
                            .frame(maxWidth: min(geometry.size.width * 0.8, 1200))

                            Spacer().frame(height: max(0, geometry.size.height * 0.2))

                            CommandBar(wantsScreenShare: $wantsScreenShare)
                                .environmentObject(cameraViewModel)
                                .environmentObject(screenCaptureModel)
                                .frame(minHeight: 60)
                                .frame(maxWidth: min(geometry.size.width * 0.8, 1200))
                                .padding(.bottom, geometry.safeAreaInsets.bottom + 20)
                        }
                        .frame(maxWidth: min(geometry.size.width * 0.8, 1200))

                        Spacer()
                    }
                    .zIndex(1)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            setupInitialState()
            configureWindowForMeetingRoom()  // ✅ Window Resize Logic
        }
        .onDisappear {
            restoreWindowResizability()  // ✅ Restore Resize on Exit
        }
    }

    private func backgroundView(geometry: GeometryProxy) -> some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "1E293B"), Color(hex: "0F172A"), Color(hex: "1E293B")]),
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .frame(width: geometry.size.width, height: geometry.size.height)
    }

    private func cameraSection(geometry: GeometryProxy) -> some View {
        CameraView()
            .environmentObject(cameraViewModel)
            .frame(width: min(geometry.size.width * 0.8, 1200), height: min(geometry.size.height * 0.5, 600))
            .cornerRadius(12)
            .shadow(color: Color(hex: "8B5CF6").opacity(0.3), radius: 8, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        LinearGradient(
                            gradient: Gradient(colors: [Color(hex: "8B5CF6"), Color(hex: "EC4899")]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            )
            .onAppear {
                print("CameraView appeared, starting capture...")
                cameraViewModel.startCapture()
            }
            .onDisappear {
                // Only stop if explicitly toggled off, not on view switch
                if !cameraViewModel.isCapturing {
                    print("CameraView disappeared, capture already stopped")
                }
            }
    }

    private func configureWindowForMeetingRoom() {
        guard let window = NSApplication.shared.windows.first else { return }

        if let screen = NSScreen.main {
            let visibleFrame = screen.visibleFrame

            window.setFrame(visibleFrame, display: true, animate: true)
            window.styleMask.remove(.resizable)
            window.styleMask.insert(.resizable)
            window.minSize = NSSize(width: 0, height: visibleFrame.height)
            window.maxSize = NSSize(width: .infinity, height: visibleFrame.height)
        }
    }

    private func restoreWindowResizability() {
        guard let window = NSApplication.shared.windows.first else { return }
        window.styleMask.insert(.resizable)
        window.minSize = NSSize(width: 700, height: 850)
        window.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
    }

    private func setupInitialState() {
        noiseImage = loadNoiseImage(from: "background")
        viewModel.connect()
        viewModel.sendMessage("GET PARTICIPANTS")
        audioViewModel.startMonitoring()
        cameraViewModel.startCapture()
    }
}

// Rest of the code remains unchanged...

struct ParticipantSidebar: View {
    let participants: [Participant]

    private func calculateAvatarSize() -> CGFloat {
        switch participants.count {
        case 1...3: return 160
        case 4...6: return 120
        default: return 100
        }
    }

    var body: some View {
        List {
            ForEach(participants) { participant in
                VStack(spacing: 0) {
                    UserAvatarBadge(
                        initial: String(participant.nickname.prefix(1)),
                        isOnline: participant.isOnline,
                        size: calculateAvatarSize()
                    )
                    .frame(height: calculateAvatarSize())
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.black, lineWidth: 1)
                    )

                    Text(participant.nickname)
                        .font(.caption)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(Color.black)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
        }
        .frame(width: 300)
        .background(
            ZStack {
                Color.black.opacity(0.8)
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.1),
                        Color.white.opacity(0.05)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        )
        .scrollContentBackground(.hidden)
        .listStyle(.sidebar)
    }
}

// New NSScrollbar implementation
struct NSScrollbarOverlay: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let scrollView = view.enclosingScrollView {
                scrollView.hasVerticalScroller = true
                scrollView.scrollerStyle = .overlay
                
                if let scroller = scrollView.verticalScroller {
                    scroller.alphaValue = 0.8
                    scroller.scrollerStyle = .overlay
                    scroller.knobStyle = .dark
                }
            }
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
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
        ZStack {
            Rectangle()
                .fill(Color.clear)
                .border(Color.black, width: 1)
                .overlay(
                    Rectangle()
                        .frame(height: 10)
                        .foregroundColor(.black),
                    alignment: .bottom
                )
            
            VStack(spacing: 0) {
                Button(action: {
                    // Handle click if needed
                }) {
                    UserAvatarBadge(
                        initial: String(participant.nickname.prefix(1)),
                        isOnline: participant.isOnline,
                        size: 100
                    )
                }
                .buttonStyle(.plain)
                .padding(.vertical, 8)
                
                Text(participant.nickname)
                    .padding(.bottom, 4)
            }
        }
       
    }
}
struct CommandBar: View {
    @EnvironmentObject private var audioViewModel: AudioMeterViewModel
    @EnvironmentObject private var cameraViewModel: CameraViewModel
    @EnvironmentObject private var screenCaptureModel: ScreenCaptureViewModel
    @State private var handRaised: Bool = false
    @Binding var wantsScreenShare: Bool
    
    // Drag-related state
    @State private var offset = CGSize.zero
    @State private var isDragging = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Command Buttons Container - Centered horizontally
                HStack(spacing: 20) {
                    CommandButton(icon: !audioViewModel.isMonitoring ? "mic.slash.fill" : "mic.fill",
                                  color: Color(hex: "34495E")) {
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

                    CommandButton(icon: handRaised ? "hand.point.up.fill" : "hand.raised.fill", // Toggle icon
                                  color: Color(hex: "34495E")) {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.5, blendDuration: 0.3)) {
                            handRaised.toggle()
                            if handRaised {
                                SoundManager.shared.playHandRaisedSound()
                            } else {
                                SoundManager.shared.playCancelSound() // Play cancel sound when hand is lowered
                            }
                        }
                    }

                    CommandButton(icon: "rectangle.on.rectangle.angled", color: Color(hex: "34495E")) {
                        wantsScreenShare.toggle()
                        if wantsScreenShare {
                            SoundManager.shared.playScreenSharedSound()
                        } else {
                            SoundManager.shared.playCancelSound() // Play cancel sound when screen share is stopped
                        }
                    }

                    CommandButton(icon: "arrow.up.left.and.arrow.down.right", color: Color(hex: "34495E")) {}
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
                .frame(maxWidth: .infinity) // Allow it to stretch but center content
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2) // Center within GeometryReader
                .gesture(
                    DragGesture(minimumDistance: 10)
                        .onChanged { gesture in
                            offset = CGSize(
                                width: offset.width + gesture.translation.width,
                                height: offset.height + gesture.translation.height
                            )
                        }
                        .onEnded { _ in }
                )
                .offset(x: offset.width, y: offset.height)
                .background(
                    GeometryReader { proxy in
                        Color.clear
                            .onHover { hovering in
                                if hovering {
                                    NSCursor.openHand.push()
                                } else {
                                    NSCursor.pop()
                                }
                            }
                    }
                )

                // Hand Raised Badge - Positioned relative to dragged offset
                HandWaiveBadge()
                    .opacity(handRaised ? 1.0 : 0.0)
                    .scaleEffect(handRaised ? 1.2 : 0.5)
                    .offset(x: offset.width, y: offset.height - 100) // Follows CommandBar, offset upward
                    .animation(.spring(response: 0.6, dampingFraction: 0.4, blendDuration: 0.3), value: handRaised)
                    .onChange(of: handRaised) { newValue in
                        if newValue {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                                withAnimation {
                                    handRaised = false
                                    SoundManager.shared.playCancelSound() // Play cancel sound when auto-lowered
                                }
                            }
                        }
                    }
            }
        }
    }
}
struct UserAvatarBadge: View {
    let initial: String
    let isOnline: Bool
    let size: CGFloat
    @State private var isHovered = false

    var body: some View {
        ZStack(alignment: .center) {
            // Avatar Badge
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(hex: "1E293B"),
                            Color(hex: "0F172A")
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: "4F46E5").opacity(0.6),
                                    Color(hex: "4F46E5").opacity(0.2)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(
                    color: Color(hex: "4F46E5").opacity(0.15),
                    radius: 8,
                    x: 0,
                    y: 4
                )

            Text(initial)
                .font(.system(size: size * 0.4, weight: .semibold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.95),
                            Color.white.opacity(0.8)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: Color(hex: "4F46E5").opacity(0.3), radius: 2, x: 0, y: 1)

            if isOnline {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(hex: "10B981"),
                                Color(hex: "059669")
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: size * 0.2, height: size * 0.2)
                    .overlay(
                        Circle()
                            .stroke(Color(hex: "0F172A"), lineWidth: 2)
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.5), lineWidth: 1)
                    )
                    .shadow(color: Color(hex: "10B981").opacity(0.5), radius: 4, x: 0, y: 0)
                    .offset(x: size * 0.35, y: size * 0.35)
            }

            // Context Menu (only shown when hovered)
            if isHovered {
                contextMenuOverlay()
                    .offset(x: size / 2 + 10, y: 0) // Position to the right
            }
        }
        .frame(width: size + (isHovered ? 150 : 0), height: size) // Expand frame when menu is visible
        .contentShape(Rectangle()) // Ensure the entire area is hoverable
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }

    @ViewBuilder
    private func contextMenuOverlay() -> some View {
        VStack(spacing: 8) {
            Button("Mute") {
                print("Mute clicked for \(initial)")
                isHovered = false // Optionally hide menu after click
            }
            Button("Kick") {
                print("Kick clicked for \(initial)")
                isHovered = false
            }
            Button("View Profile") {
                print("View Profile clicked for \(initial)")
                isHovered = false
            }
        }
        .padding(8)
        .background(Color(hex: "2C3E50").opacity(0.95))
        .cornerRadius(8)
        .shadow(radius: 5)
        .foregroundColor(.white)
        .buttonStyle(PlainButtonStyle()) // Ensure buttons don’t interfere with hover
    }
}
struct HandWaiveBadge: View {
   var body: some View {
       Text("✋ Hand Raised")
           .font(.headline)
           .padding(12)
           .background(Color.red.opacity(0.9))
           .foregroundColor(.white)
           .cornerRadius(12)
           .shadow(radius: 5)
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

struct ButtonPane: View {
    @Binding var wantsScreenShare: Bool // To interact with MeetingRoomView state
    @EnvironmentObject private var cameraViewModel: CameraViewModel
    @EnvironmentObject private var screenCaptureModel: ScreenCaptureViewModel

    var body: some View {
        VStack(spacing: 15) {
            // Record Button
            RecordButton()
                .frame(width: 50, height: 50) // Keep button size consistent
            
            // Toggle Camera Button
            CommandButton(
                icon: cameraViewModel.isCapturing ? "video.fill" : "video.slash.fill",
                color: Color(hex: "34495E")
            ) {
                if cameraViewModel.isCapturing {
                    cameraViewModel.stopCapture()
                } else {
                    cameraViewModel.startCapture()
                }
            }
            .frame(width: 40, height: 40)
            
            // Toggle Screen Share Button
            CommandButton(
                icon: wantsScreenShare ? "rectangle.on.rectangle.angled.fill" : "rectangle.on.rectangle.angled",
                color: Color(hex: "34495E")
            ) {
                wantsScreenShare.toggle()
                if wantsScreenShare {
                    SoundManager.shared.playScreenSharedSound()
                } else {
                    SoundManager.shared.playCancelSound()
                }
            }
            .frame(width: 40, height: 40)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 10)
        .background(
            ZStack {
                // Gradient background with vibrant accent
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(hex: "2C3E50").opacity(0.9), // Darker base
                                Color(hex: "1E293B")              // Matches MeetingRoomView
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                // Subtle vibrant edge glow
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(hex: "8B5CF6").opacity(0.5),
                                Color(hex: "EC4899").opacity(0.3)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
                    .blur(radius: 4)
            }
        )
        .shadow(color: Color(hex: "8B5CF6").opacity(0.25), radius: 8, x: 0, y: 4)
        .animation(.easeInOut(duration: 0.3), value: wantsScreenShare) // Smooth transitions
        .frame(width: 70) // Fixed width for the pane
    }
}

struct RecordButton: View {
    @State private var isPressed = false
    @State private var isHovered = false

    var body: some View {
        ZStack {
            // Outer glow ring (pulsing effect)
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color(hex: "8B5CF6").opacity(0.5),
                            Color(hex: "EC4899").opacity(0.1),
                            Color.clear
                        ]),
                        center: .center,
                        startRadius: 5,
                        endRadius: 40
                    )
                )
                .frame(width: 80, height: 80)
                .scaleEffect(isHovered ? 1.1 : 1.0)
                .opacity(isPressed ? 0.7 : 1.0)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isHovered)

            // Main button
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(hex: "F9FAFB"), // Near-white
                            Color(hex: "D1D5DB")  // Light gray
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 50, height: 50)
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: "8B5CF6"),
                                    Color(hex: "EC4899")
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 4
                        )
                        .shadow(color: Color(hex: "8B5CF6").opacity(0.6), radius: 6, x: 0, y: 0)
                )
                .overlay(
                    // Record icon (red dot)
                    Circle()
                        .fill(Color.red)
                        .frame(width: 20, height: 20)
                        .shadow(color: Color.red.opacity(0.5), radius: 4, x: 0, y: 0)
                )
                .scaleEffect(isPressed ? 0.9 : 1.0)
                .brightness(isPressed ? -0.1 : 0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        }
        .onHover { hovering in
            withAnimation {
                isHovered = hovering
            }
        }
        .gesture(
            TapGesture()
                .onEnded { _ in
                    withAnimation {
                        isPressed = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isPressed = false // Reset after press
                        }
                    }
                }
        )
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

