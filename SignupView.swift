import Foundation
import SwiftUI

public struct SignupView: View {
    @State private var noiseImage: NSImage?
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    
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
            
            // Form content layer
            VStack(spacing: 24) {
                // Account Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Account Details")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                    
                    VStack(spacing: 12) {
                        // Username field
                        formField(title: "Username", text: $username)
                        // Password field
                        formField(title: "Password", text: $password, isSecure: true)
                    }
                }
                
                // Personal Info Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Personal Information")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                    
                    VStack(spacing: 12) {
                        formField(title: "First Name", text: $firstName)
                        formField(title: "Last Name", text: $lastName)
                        formField(title: "Email", text: $email)
                    }
                }
                
                // Sign Up Button
                Button(action: {
                    // Sign up action
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "person.badge.plus")
                            .imageScale(.medium)
                        Text("Sign Up")
                            .fontWeight(.semibold)
                    }
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
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
                }
                .buttonStyle(PlainButtonStyle())
                // Add hover and press effects
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if hovering {
                            // Hover effect
                        }
                    }
                }
                .pressAction(onPress: {
                    // Press effect
                }, onRelease: {
                    // Release effect
                })

             



            }
            .padding(24)
            .background(AppColors.messageBackground.opacity(0.95))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 5)
            .frame(width: 320)  // Increased width to accommodate fields and labels
        }
        .onAppear {
            noiseImage = loadNoiseImage(from: "background")
        }
    }
    
    // Helper function to create consistent form fields
    private func formField(title: String, text: Binding<String>, isSecure: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppColors.textSecondary)
            
            Group {
                if isSecure {
                    SecureField("", text: text)
                } else {
                    TextField("", text: text)
                }
            }
            .textFieldStyle(.plain)
            .frame(height: 32)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(AppColors.messageBackground)
            .foregroundColor(AppColors.focusedBorder)
            .fontWeight(.medium)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppColors.focusedBorder)
            )
        }
    }
}
