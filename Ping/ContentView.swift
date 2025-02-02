import SwiftUI
import Combine

struct ContentView: View {
    @State private var nickname: String = UserData().nickname
    @State private var passcode: String = ""
    @State private var isPasswordVisible: Bool = false
    @State private var isAtLimit: Bool = false
    @FocusState private var isDisplayNameFocused: Bool
    @FocusState private var isPasscodeFocused: Bool
    @State private var redisUrl: String = ""
    @StateObject private var redisViewModel = RedisViewModel()
    let textLimit = 16

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
            LinearGradient(gradient: Gradient(colors: [
                Color(red: 0.85, green: 0.80, blue: 0.75), // Light taupe
                Color(red: 0.75, green: 0.70, blue: 0.65)  // Medium taupe
            ]), startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
            
            
            
            VStack {
                          Text(redisViewModel.isConnected ? "Redis Connected" : "Connecting...")
                              .foregroundColor(.white)
                              .font(.headline)
                      }
                
            
            HStack(spacing: 20) {
                CameraView()
                    .frame(width: 480, height: 360)
                    .clipped()
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray, lineWidth: 1)
                    )
                    .shadow(radius: 5, x: 2, y: 2)
                    

                VStack(alignment: .center, spacing: 24) {
                    Spacer().frame(height: 25)

                    textFieldWithLabel(text: $nickname, isFocused: $isDisplayNameFocused, placeholder: "Display Name")

                    passwordFieldWithLabel(text: $passcode, isFocused: $isPasscodeFocused, isPasswordVisible: $isPasswordVisible, placeholder: "Passcode", showLimit: isAtLimit)
                        .onReceive(Just(passcode)) { _ in limitText(textLimit) }

                    ConnectButton()
                        .frame(maxWidth: .infinity, alignment: .center)

                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 16)
            }
            .padding()
        }
        .task {
            redisViewModel.connect()
        }
    }

    private func textFieldWithLabel(text: Binding<String>, isFocused: FocusState<Bool>.Binding, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            TextField("", text: text)
                .textFieldStyle(.plain)
                .frame(width: 160, height: 32)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.15))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isFocused.wrappedValue ? Color.gray.opacity(1) : Color.gray.opacity(0.7), lineWidth: 3)
                )
                .accentColor(isFocused.wrappedValue ?
                    Color(red: 0.45, green: 0.39, blue: 0.34) :
                    Color(red: 0.32, green: 0.27, blue: 0.24))
                .focused(isFocused)

            Text(placeholder)
                .font(.caption)
                .foregroundColor(.gray)
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
                .background(Color.white.opacity(0.15))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isFocused.wrappedValue ? Color.gray.opacity(1) : Color.gray.opacity(0.7), lineWidth: 3)
                )
                .accentColor(isFocused.wrappedValue ?
                    Color(red: 0.45, green: 0.39, blue: 0.34) :
                    Color(red: 0.32, green: 0.27, blue: 0.24))
                .focused(isFocused)

                Button(action: {
                    isPasswordVisible.wrappedValue.toggle()
                }) {
                    Image(systemName: isPasswordVisible.wrappedValue ? "eye.slash" : "eye")
                        .foregroundColor(.gray)
                        .padding(.trailing, 10)
                }
                .buttonStyle(PlainButtonStyle())
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(placeholder)
                    .font(.caption)
                    .foregroundColor(.gray)

                if showLimit {
                    Text("Maximum 16 characters")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
    }
}

struct ConnectButton: View {
    @State private var isHovering = false
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            // Action goes here
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
                    gradient: Gradient(colors: isPressed ?
                        [Color(red: 0/255, green: 90/255, blue: 80/255), // Darker green
                         Color(red: 0/255, green: 75/255, blue: 70/255)] // Even darker green
                        :
                        [Color(red: 0/255, green: 121/255, blue: 107/255), // Teal
                         Color(red: 0/255, green: 105/255, blue: 98/255)] // Slightly darker teal
                    ),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
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
    ContentView()
}

