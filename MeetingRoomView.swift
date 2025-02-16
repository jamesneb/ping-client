import SwiftUI

// MARK: - Meeting Room View
struct MeetingRoomView: View {
    // MARK: - Properties
    
    // User information passed from login
    let nickname: String
    let passcode: String
    
    // Window management
    let windowDelegate: MeetingWindowDelegate
    
    // View model for WebSocket communication
    @StateObject private var viewModel = WebSocketViewModel()
    
    // State properties for UI management
    @State private var participants: [Participant] = []
    @State private var noiseImage: NSImage?
    @State private var isCameraEnabled: Bool = true
    @State private var isAudioEnabled: Bool = true
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Background Layer with noise texture
            if let image = noiseImage {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
            }
            
            // Main Content
            VStack(spacing: 32) {
                // Header Section
                headerSection
                
                // Content Stack
                VStack(spacing: 24) {
                    // Media Controls
                    mediaControlsSection
                    
                    // Participants Section
                    if !participants.isEmpty {
                        participantsSection
                    }
                    
                    // Chat or Additional Features
                    Spacer()
                }
            }
            .padding(32)
            .frame(maxWidth: 600)
            .frame(minWidth: 700, minHeight: 850)
        }
        .onAppear {
            setupInitialState()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            // Room title
            Text("Meeting Room")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
            
            Spacer()
            
            // Connection status indicator
            ConnectionStatusView(isConnected: viewModel.isConnected)
            
            // Leave meeting button
            Button(action: {
                handleLeaveMeeting()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(AppColors.textSecondary)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - Media Controls Section
    private var mediaControlsSection: some View {
        VStack(spacing: 20) {
            // Camera section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "video.fill")
                        .foregroundColor(AppColors.textSecondary)
                    Text("Camera")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                    Spacer()
                    
                    // Camera toggle button
                    MediaToggleButton(
                        isEnabled: $isCameraEnabled,
                        enabledIcon: "video.fill",
                        disabledIcon: "video.slash.fill"
                    )
                }
                
                // Camera preview
                if isCameraEnabled {
                    CameraPreviewView()
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppColors.inputBorder, lineWidth: 1)
                        )
                } else {
                    CameraDisabledView()
                        .frame(height: 200)
                }
            }
            
            Divider()
                .background(AppColors.inputBorder)
            
            // Audio section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "waveform")
                        .foregroundColor(AppColors.textSecondary)
                    Text("Audio")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                    Spacer()
                    
                    // Audio toggle button
                    MediaToggleButton(
                        isEnabled: $isAudioEnabled,
                        enabledIcon: "mic.fill",
                        disabledIcon: "mic.slash.fill"
                    )
                }
                
                if isAudioEnabled {
                    AudioMeterView()
                } else {
                    AudioDisabledView()
                }
            }
        }
        .padding(24)
        .background(AppColors.messageBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
    }
    
    // MARK: - Participants Section
    private var participantsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundColor(AppColors.textSecondary)
                Text("Participants (\(participants.count))")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                
                UserAvatarGroup(participants: participants)
                
                Spacer()
            }
            
            // Participants list
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(participants) { participant in
                        ParticipantRow(participant: participant)
                    }
                }
            }
            .frame(maxHeight: 200)
        }
        .padding(24)
        .background(AppColors.messageBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
    }
    
    // MARK: - Helper Methods
    private func setupInitialState() {
        // Load background texture
        noiseImage = loadNoiseImage(from: "background")
        
        // Initialize WebSocket connection
        viewModel.connect()
        
        // Request initial participants list
        viewModel.sendMessage("GET PARTICIPANTS")
        
        // Setup WebSocket message handling
        setupMessageHandling()
    }
    
    private func setupMessageHandling() {
        // Handle incoming WebSocket messages
        viewModel.onMessage = { message in
            // Parse participant updates and update the UI
            if let updatedParticipants = parseParticipants(from: message) {
                DispatchQueue.main.async {
                    self.participants = updatedParticipants
                }
            }
        }
    }
    
    private func handleLeaveMeeting() {
        // Clean up WebSocket connection
        viewModel.disconnect()
        
        // Close the window
        windowDelegate.window?.close()
    }
    
    private func parseParticipants(from message: String) -> [Participant]? {
        // Implement message parsing logic here
        // This would depend on your specific message format
        return nil
    }
}

// MARK: - Supporting Views
struct ConnectionStatusView: View {
    let isConnected: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(isConnected ? Color.green : Color.red)
                .frame(width: 8, height: 8)
            
            Text(isConnected ? "Connected" : "Disconnected")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppColors.textSecondary)
        }
    }
}

struct MediaToggleButton: View {
    @Binding var isEnabled: Bool
    let enabledIcon: String
    let disabledIcon: String
    
    var body: some View {
        Button(action: {
            isEnabled.toggle()
        }) {
            Image(systemName: isEnabled ? enabledIcon : disabledIcon)
                .font(.system(size: 16))
                .foregroundColor(isEnabled ? AppColors.textPrimary : Color.red)
                .padding(8)
                .background(AppColors.inputBackground)
                .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ParticipantRow: View {
    let participant: Participant
    
    var body: some View {
        HStack(spacing: 12) {
            UserAvatarBadge(
                initial: String(participant.nickname.prefix(1)),
                isOnline: participant.isOnline
            )
            
            Text(participant.nickname)
                .font(.system(size: 14))
                .foregroundColor(AppColors.textPrimary)
            
            Spacer()
            
            // Media status indicators
            Image(systemName: "mic.fill")
                .foregroundColor(AppColors.textSecondary)
            Image(systemName: "video.fill")
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

// MARK: - Preview Provider
#Preview {
    MeetingRoomView(
        nickname: "Test User",
        passcode: "123456",
        windowDelegate: MeetingWindowDelegate(
            window: NSWindow()
        )
    )
}
