import SwiftUI
import Combine

// AppColors struct remains exactly the same
struct AppColors {
    static let backgroundGradient = Gradient(colors: [
        Color(red: 0.98, green: 0.98, blue: 0.98),
        Color(red: 0.95, green: 0.95, blue: 0.95)
    ])
    
    static let primaryGradient = Gradient(colors: [
        Color(red: 0.0, green: 0.47, blue: 0.87),
        Color(red: 0.0, green: 0.42, blue: 0.78)
    ])
    
    static let cameraGradient = Gradient(colors: [
        Color(red: 0.83, green: 0.83, blue: 0.83),  // Lighter silver
        Color(red: 0.75, green: 0.75, blue: 0.75)   // Slightly darker silver
    ])
    
    static let cameraPressedGradient = Gradient(colors: [
        Color(red: 0.75, green: 0.75, blue: 0.75),  // Darker silver
        Color(red: 0.67, green: 0.67, blue: 0.67)   // Even darker silver
    ])
    
    static let toggleMicrophoneGradient = Gradient(colors: [
        Color(red: 0.87, green: 0.0, blue: 0.0),
        Color(red: 0.78, green: 0.0, blue: 0.0)
    ])
    
    static let toggleMicrophonePressedGradient = Gradient(colors: [
        Color(red: 0.78, green: 0.0, blue: 0.0),
        Color(red: 0.69, green: 0.0, blue: 0.0)
    ])
    
    static let primaryPressedGradient = Gradient(colors: [
        Color(red: 0.0, green: 0.42, blue: 0.78),
        Color(red: 0.0, green: 0.37, blue: 0.69)
    ])
    
    static let textPrimary = Color(red: 0.2, green: 0.2, blue: 0.2)
    static let textSecondary = Color(red: 0.4, green: 0.4, blue: 0.4)
    static let border = Color(red: 0.85, green: 0.85, blue: 0.85)
    static let focusedBorder = Color(red: 0.0, green: 0.47, blue: 0.87)
    
    static let badgeGradient = Gradient(colors: [
        Color(red: 0.0, green: 0.0, blue: 0.0),  // Pure black
        Color(red: 0.4, green: 0.4, blue: 0.4)   // Dark grey
    ])
    
    static let messageBackground = Color.white.opacity(0.95)
    static let error = Color(red: 0.95, green: 0.27, blue: 0.27)
}

struct ContentView: View {
    @State private var nickname: String = UserData().nickname
    @State private var passcode: String = ""
    @State private var isPasswordVisible: Bool = false
    @State private var isAtLimit: Bool = false
    @FocusState private var isDisplayNameFocused: Bool
    @FocusState private var isPasscodeFocused: Bool
    let textLimit = 16
    @StateObject private var viewModel = WebSocketViewModel()
    
    func limitText(_ upper: Int) {
        if passcode.count >= upper {
            passcode = String(passcode.prefix(upper))
            isAtLimit = true
        } else {
            isAtLimit = false
        }
    }
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: AppColors.backgroundGradient,
                          startPoint: .topLeading,
                          endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Camera with overlapping Connect button
                    ZStack(alignment: .bottomLeading) {
                        CameraView()
                            .frame(width: 360, height: 240)
                            .clipped()
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppColors.border, lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.2),
                                   radius: 5, x: 2, y: 2)
                        DisableCameraButton().frame(width: 160)
                            .offset(x: 50, y: 0)
                        ConnectButton()
                            .frame(width: 160)
                            .offset(x: 100, y: 0)
                    }
                    
                    // Input Fields
                    VStack(spacing: 16) {
                        textFieldWithLabel(text: $nickname,
                                         isFocused: $isDisplayNameFocused,
                                         placeholder: "Display Name")
                        
                        passwordFieldWithLabel(text: $passcode,
                                            isFocused: $isPasscodeFocused,
                                            isPasswordVisible: $isPasswordVisible,
                                            placeholder: "Passcode",
                                            showLimit: isAtLimit)
                            .onReceive(Just(passcode)) { _ in limitText(textLimit) }
                    }
                    
                    // Audio Meter
                    AudioMeterView()
                        .frame(width: 360)
                        .shadow(color: Color.black.opacity(0.2),
                               radius: 5, x: 2, y: 2)
                    
                    // Message Area
                    ZStack {
                        Text(viewModel.receivedMessage)
                            .font(.body)
                            .padding()
                            .frame(width: 300, alignment: .center)
                            .background(AppColors.messageBackground)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(AppColors.border, lineWidth: 1)
                            )
                            .foregroundColor(AppColors.textPrimary)
                            .zIndex(0)
                        
                        HStack(spacing: 0) {
                            Text("1")
                                .padding(.leading, 0)
                                .foregroundColor(.white)
                                .font(.system(size: 16, weight: .heavy, design: .rounded))
                                .frame(width: 20, height: 30)
                                .background(
                                    LinearGradient(
                                        gradient: AppColors.badgeGradient,
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                    .clipShape(Circle())
                                )
                                .offset(x: 50)
                                .zIndex(1)
                            
                            Spacer()
                        }
                    }
                    .frame(width: 300)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            }
        }
        .navigationTitle("Ping - Meeting Lobby")
        .frame(minWidth: 700, minHeight: 400)
        .onAppear {
            viewModel.connect()
            viewModel.sendMessage("GET PARTICIPANTS")
        }
    }
    
    // Helper Views
    private func textFieldWithLabel(text: Binding<String>, isFocused: FocusState<Bool>.Binding, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            TextField("", text: text)
                .textFieldStyle(.plain)
                .frame(width: 160, height: 32)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(AppColors.messageBackground)
                .foregroundColor(AppColors.focusedBorder)
                .fontWeight(.heavy)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isFocused.wrappedValue ? AppColors.focusedBorder : AppColors.border, lineWidth: 1)
                )
                .focused(isFocused)

            Text(placeholder)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppColors.textSecondary)
                .padding(.leading, 4)
        }
    }

    private func passwordFieldWithLabel(text: Binding<String>, isFocused: FocusState<Bool>.Binding, isPasswordVisible: Binding<Bool>, placeholder: String, showLimit: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .trailing) {
                Group {
                    if isPasswordVisible.wrappedValue {
                        TextField("", text: text)
                    } else {
                        SecureField("", text: text)
                    }
                }
                .textFieldStyle(.plain)
                .frame(width: 160, height: 32)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(AppColors.messageBackground)
                .cornerRadius(12)
                .foregroundColor(AppColors.focusedBorder)
                .fontWeight(.heavy)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isFocused.wrappedValue ? AppColors.focusedBorder : AppColors.border, lineWidth: 1)
                )
                .focused(isFocused)

                Button(action: {
                    isPasswordVisible.wrappedValue.toggle()
                }) {
                    Image(systemName: isPasswordVisible.wrappedValue ? "eye.slash" : "eye")
                        .foregroundColor(AppColors.textSecondary)
                        .padding(.trailing, 10)
                }
                .buttonStyle(PlainButtonStyle())
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(placeholder)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)
                    .padding(.leading, 4)

                if showLimit {
                    Text("Maximum 16 characters")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(AppColors.error)
                        .padding(.leading, 4)
                }
            }
        }
    }
}

struct ConnectButton: View {
    @State private var isHovering = false
    @State private var isPressed = false
    @State private var showNoiseView = false

    var body: some View {
        Button(action: {
            showNoiseView = true
        }) {
            HStack(spacing: 8) {
                Image(systemName: "wifi")
                    .imageScale(.large)

                if isHovering {
                    Text("Connect")
                        .transition(.opacity)
                }
            }
            .padding()
            .background(
                LinearGradient(
                    gradient: isPressed ? AppColors.primaryPressedGradient : AppColors.primaryGradient,
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .opacity(0.8)
            .border(Color.gray, width: 1)
            .cornerRadius(12)
            .foregroundColor(.white)
            .animation(.easeInOut(duration: 0.2), value: isHovering)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHovering = hovering
        }
        .pressAction(onPress: {
            isPressed = true
        }, onRelease: {
            isPressed = false
        })
        .sheet(isPresented: $showNoiseView) {
            PerlinBackgroundView().frame(width: 1024, height:768)
        }
    }
}

struct DisableCameraButton: View {
    @State private var isHovering = false
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            // Action goes here
        }) {
            HStack(spacing: 8) {
                Image(systemName: "camera.circle.fill")
                    .imageScale(.large)
                
                if isHovering {
                    Text("Disable camera")
                        .transition(.opacity)
                }
            }
            .padding()
            .background(
                LinearGradient(
                    gradient: isPressed ? AppColors.cameraPressedGradient : AppColors.cameraGradient,
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .opacity(0.8)
            .border(Color.gray, width: 1)
            .cornerRadius(12)
            .foregroundColor(.white)
            .animation(.easeInOut(duration: 0.2), value: isHovering)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHovering = hovering
        }
        .pressAction(onPress: {
            isPressed = true
        }, onRelease: {
            isPressed = false
        })
    }
}

struct PressAction: ViewModifier {
    let onPress: () -> Void
    let onRelease: () -> Void

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in onPress() }
                    .onEnded { _ in onRelease() }
            )
    }
}

extension View {
    func pressAction(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        self.modifier(PressAction(onPress: onPress, onRelease: onRelease))
    }
}

#Preview {
    LoginView()
}
