import Foundation
import SwiftUI
public struct LoginView: View {
    @State private var noiseImage: NSImage?
    @State private var username: String = ""
    @State private var password: String = ""
    
    public var body: some View {
        ZStack {
            // Background layer
            if let image = noiseImage {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
            }
            
            // Form layer - separate from background
            VStack(spacing: 16) {
                // Username field
                TextField("Username", text: $username)
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
                            .stroke(AppColors.focusedBorder)
                    )
                
                // Password field
                SecureField("Password", text: $password)  // Changed to SecureField for password
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
                            .stroke(AppColors.focusedBorder)
                    )
                
                Button(action: {
                    // Login action here
                }) {
                    Text("Log in")
                        .foregroundColor(.white)
                        .frame(width: 160, height: 40)
                        .background(
                            LinearGradient(
                                gradient: AppColors.primaryGradient,
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(12)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            noiseImage = loadNoiseImage(from: "background")
        }
    }
}
