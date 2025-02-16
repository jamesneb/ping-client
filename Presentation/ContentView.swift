import SwiftUI

struct ContentView: View {
    // MARK: - State Management
    @StateObject private var viewModel = WebSocketViewModel()
    @State private var nickname: String = UserData().nickname
    @State private var passcode: String = ""
    @State private var noiseImage: NSImage?
    
    // URLHandler for navigation
    @EnvironmentObject private var urlHandler: URLHandler
    
    // Focus states for form fields
    @FocusState private var isDisplayNameFocused: Bool
    @FocusState private var isPasscodeFocused: Bool
    
    // MARK: - Main View Body
    var body: some View {
        ZStack {
            // Background texture layer
            if let image = noiseImage {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
            }
            
            // Main Content Layer
            VStack(spacing: 32) {
                headerSection
                
                // Main content stack
                VStack(spacing: 24) {
                    mediaControlsSection
                    userCredentialsSection
                    participantsIndicator
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
    
    // MARK: - View Sections
    private var headerSection: some View {
        HStack {
            Button(action: { urlHandler.currentRoute = .login }) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                    Text("Back")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(AppColors.textPrimary)
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            Text("Join Meeting")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
        }
    }
    
    private var mediaControlsSection: some View {
        VStack(spacing: 20) {
            // Camera preview section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "video.fill")
                        .foregroundColor(AppColors.textSecondary)
                    Text("Camera")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                    Spacer()
                    AudioMeterView()
                }
                
                CameraView()
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppColors.inputBorder, lineWidth: 1)
                    )
            }
            
            Divider()
                .background(AppColors.inputBorder)
            
            // Audio controls section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "waveform")
                        .foregroundColor(AppColors.textSecondary)
                    Text("Audio")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                    Spacer()
                    
                }
                
                AudioMeterView()
            }
        }
        .padding(24)
        .background(AppColors.messageBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
    }
    
    private var userCredentialsSection: some View {
        VStack(spacing: 16) {
            VStack(spacing: 20) {
                formField(
                    title: "Display Name",
                    text: $nickname,
                    icon: "person.fill",
                    isFocused: $isDisplayNameFocused
                )
                
                formField(
                    title: "Meeting Passcode",
                    text: $passcode,
                    icon: "lock.fill",
                    isSecure: true,
                    isFocused: $isPasscodeFocused
                )
            }
            
            // Connect button
            Button(action: handleConnect) {
                Text("Connect")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(height: 36)
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            gradient: AppColors.badgeGradient,
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
            .frame(width: 120)
            .disabled(nickname.isEmpty || passcode.isEmpty)
        }
        .padding(24)
        .background(AppColors.messageBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
    }
    
    private var participantsIndicator: some View {
        HStack {
            Image(systemName: "person.2.fill")
                .foregroundColor(AppColors.textSecondary)
            Text("Participants")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
            
            // Add participant count badge
            Circle()
                .fill(LinearGradient(
                    gradient: AppColors.badgeGradient,
                    startPoint: .top,
                    endPoint: .bottom
                ))
                .frame(width: 20, height: 20)
                .overlay(
                    Text("3")  // Replace with actual count
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                )
            
            if !viewModel.receivedMessage.isEmpty {
                Text(viewModel.receivedMessage)
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textPrimary)
            }
            
            Spacer()
        }
        .padding(24)
        .background(AppColors.messageBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
    }
    
    // MARK: - Helper Views
    private func formField(
        title: String,
        text: Binding<String>,
        icon: String,
        isSecure: Bool = false,
        isFocused: FocusState<Bool>.Binding
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppColors.textSecondary)
            
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(AppColors.textSecondary)
                    .frame(width: 20)
                
                if isSecure {
                    SecureField("", text: text)
                        .textFieldStyle(.plain)
                        .focused(isFocused)
                } else {
                    TextField("", text: text)
                        .textFieldStyle(.plain)
                        .focused(isFocused)
                }
            }
            .frame(height: 36)
            .padding(.horizontal, 12)
            .background(AppColors.inputBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppColors.inputBorder, lineWidth: 1)
            )
        }
    }
    
    // MARK: - Helper Methods
    private func setupInitialState() {
        noiseImage = loadNoiseImage(from: "background")
        viewModel.connect()
        viewModel.sendMessage("GET PARTICIPANTS")
    }
    
    private func handleConnect() {
        // Save nickname for future use
        UserData.shared.nickname = nickname
        
        // Validate inputs
        guard !nickname.isEmpty && !passcode.isEmpty else {
            return
        }
        
        // Navigate to meeting view using URLHandler
        urlHandler.currentRoute = .meeting
    }
}

// MARK: - Preview Provider
#Preview {
    ContentView()
        .environmentObject(URLHandler())
}
