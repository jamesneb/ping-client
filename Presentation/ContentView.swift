// internal/presentation/ContentView.swift
import SwiftUI

struct ContentView: View {
    @State private var noiseImage: NSImage?
    @State private var nickname: String = UserData().nickname
    @State private var passcode: String = ""
    @FocusState private var isDisplayNameFocused: Bool
    @FocusState private var isPasscodeFocused: Bool
    @StateObject private var viewModel = WebSocketViewModel()
    @EnvironmentObject private var urlHandler: URLHandler
    
    var body: some View {
        ZStack {
            // Background
            if let image = noiseImage {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
            }
            
            VStack(spacing: 32) {
                // Header
                HeaderView(urlHandler: urlHandler)
                
                // Main Content
                VStack(spacing: 24) {
                    // Media Controls Card
                    MediaControlsCard(viewModel: viewModel)
                    
                    // User Info Card
                    UserInfoCard(nickname: $nickname, passcode: $passcode)
                    
                    // Participants Section
                    if !viewModel.receivedMessage.isEmpty {
                        ParticipantsView(message: viewModel.receivedMessage)
                    }
                }
            }
            .padding(32)
            .frame(maxWidth: 600)
            .frame(minWidth: 700, minHeight: 850)
        }
        .onAppear {
            noiseImage = loadNoiseImage(from: "background")
            viewModel.connect()
            viewModel.sendMessage("GET PARTICIPANTS")
        }
    }
}

// MARK: - Subviews
struct HeaderView: View {
    let urlHandler: URLHandler
    
    var body: some View {
        HStack {
            Text("Meeting Room")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
            
            Spacer()
            
            Button(action: {
                urlHandler.currentRoute = .login
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(AppColors.textSecondary)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

struct MediaControlsCard: View {
    @ObservedObject var viewModel: WebSocketViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            // Camera Section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "video.fill")
                        .foregroundColor(AppColors.textSecondary)
                    Text("Camera")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                    Spacer()
                    DisableCameraButton()
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
            
            // Audio Section
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
}

struct UserInfoCard: View {
    @Binding var nickname: String
    @Binding var passcode: String
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 20) {
                // Display Name Field
                formField(title: "Display Name",
                         text: $nickname,
                         icon: "person.fill")
                
                // Meeting Passcode Field
                formField(title: "Meeting Passcode",
                         text: $passcode,
                         icon: "lock.fill",
                         isSecure: true)
            }
            
            ConnectButton()
                .frame(width: 120)
        }
        .padding(24)
        .background(AppColors.messageBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
    }
    
    private func formField(title: String, text: Binding<String>, icon: String, isSecure: Bool = false) -> some View {
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
                } else {
                    TextField("", text: text)
                        .textFieldStyle(.plain)
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
}

struct ParticipantsView: View {
    let message: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundColor(AppColors.textSecondary)
                Text("Participants")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                
                Circle()
                    .fill(LinearGradient(gradient: AppColors.badgeGradient,
                                       startPoint: .top,
                                       endPoint: .bottom))
                    .frame(width: 20, height: 20)
                    .overlay(
                        Text("1")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    )
                Spacer()
            }
            
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(AppColors.textPrimary)
        }
        .padding(24)
        .background(AppColors.messageBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
    }
}

// Preview provider for development
#Preview {
    ContentView()
        .environmentObject(URLHandler())
}
