import SwiftUI

struct ContentView: View {
    @State private var nickname: String = UserData().nickname
    @State private var passcode: String = ""
    @FocusState private var isDisplayNameFocused: Bool
    @FocusState private var isPasscodeFocused: Bool

    var body: some View {
        ZStack {
            // Background gradient that covers the entire screen
            LinearGradient(gradient: Gradient(colors: [
                Color(red: 0.85, green: 0.80, blue: 0.75), // Light taupe
                Color(red: 0.75, green: 0.70, blue: 0.65)  // Medium taupe
            ]), startPoint: .topLeading, endPoint: .bottomTrailing)
            .edgesIgnoringSafeArea(.all) // Ensures the gradient covers the full screen

            HStack(spacing: 20) {
                // Camera view
              
                CameraView()
                    .frame(width: 480, height: 360)
                    .clipped()
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray, lineWidth: 1)
                    )
                    .shadow(radius: 5, x: 2, y: 2)
                
                // VStack for text fields and labels, arranged horizontally
                VStack(alignment: .leading, spacing: 24) {
                    Spacer().frame(width: 25, height: 25) // Pushes content down to make space for the camera
                    
                    // Display Name component
                    VStack {
                        VStack(alignment: .center, spacing: 6) {
                            TextField("Display Name", text: $nickname)
                                .textFieldStyle(.plain)
                                .frame(width: 160, height: 32)  // Reduced height from 40 to 32
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.15))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(isDisplayNameFocused ? Color.gray.opacity(1) : Color.gray.opacity(0.7), lineWidth: 3)
                                )
                                .accentColor(isDisplayNameFocused ?
                                    Color(red: 0.45, green: 0.39, blue: 0.34) :
                                    Color(red: 0.32, green: 0.27, blue: 0.24))
                                .focused($isDisplayNameFocused)
                        
                                
                                

                            Text("Display Name")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    
                    
                    // Passcode component
                    
                        VStack(alignment: .center, spacing: 6) {
                            TextField("Passcode", text: $passcode)
                                .textFieldStyle(.plain)
                                .frame(width: 160, height: 32)  // Reduced height from 40 to 32
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.15))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(isPasscodeFocused ? Color.gray.opacity(1) : Color.gray.opacity(0.7), lineWidth: 3)
                                )
                                .accentColor(isPasscodeFocused ?
                                    Color(red: 0.45, green: 0.39, blue: 0.34) :
                                    Color(red: 0.32, green: 0.27, blue: 0.24))
                                .focused($isPasscodeFocused)

                            Text("Passcode")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Button(action: {
                            // Action goes here
                        }) {
                            Text("Connect")
                                .padding()
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color(red: 0/255, green: 121/255, blue: 107/255), Color(red: 0/255, green: 105/255, blue: 98/255)]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .cornerRadius(12)
                                .foregroundColor(.white)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    Spacer() // Keeps the layout flexible and pushes content upwards
                }
                .frame(maxHeight: .infinity) // Makes the VStack flexible to adjust with available space
                .padding(.top, 16) // Moves the entire VStack down slightly to avoid overlap with the camera
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}

