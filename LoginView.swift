import Foundation
import SwiftUI

struct LoginResponse: Codable {
    // Define the structure of your signup response
    // For example:
    let userId: String?
    let message: String?
}

enum LoginError: Error {
    case invalidResponse
  
}

func callLoginEP(username: String, password: String) async throws -> LoginResponse {
    guard let URL = URL(string:"http://localhost:8080/login") else {
        throw LoginError.invalidResponse
    }
    
    var request = URLRequest(url: URL)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let jsonBody: [String: Any] = ["username": username, "password": password]
    let jsonData = try JSONSerialization.data(withJSONObject: jsonBody, options: [])
    request.httpBody = jsonData
    
    let (data, _) = try await URLSession.shared.data(for: request)
}

public struct LoginView: View {
    @State private var noiseImage: NSImage?
    @State private var username: String = ""
    @State private var password: String = ""
    @EnvironmentObject private var urlHandler: URLHandler  // Add URLHandler
    
    public var body: some View {
        ZStack {
            // Background with noise texture
            if let image = noiseImage {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
            }
            
            // Main content container
            VStack(spacing: 24) {
                // Title section
                Text("Welcome Back")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppColors.primaryText)
                
                // Form fields container
                VStack(spacing: 16) {
                    // Username field with icon
                    HStack {
                        Image(systemName: "person.fill")
                            .foregroundColor(AppColors.secondaryText)
                            .frame(width: 20)
                        
                        TextField("Username", text: $username)
                            .textFieldStyle(.plain)
                            .frame(height: 40)
                            .foregroundColor(AppColors.primaryText)
                            .font(.system(size: 14, weight: .medium))
                    }
                    .padding(.horizontal, 12)
                    .background(AppColors.inputBackground)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppColors.inputBorder, lineWidth: 1)
                    )
                    
                    // Password field with icon
                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundColor(AppColors.secondaryText)
                            .frame(width: 20)
                        
                        SecureField("Password", text: $password)
                            .textFieldStyle(.plain)
                            .frame(height: 40)
                            .foregroundColor(AppColors.primaryText)
                            .font(.system(size: 14, weight: .medium))
                    }
                    .padding(.horizontal, 12)
                    .background(AppColors.inputBackground)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppColors.inputBorder, lineWidth: 1)
                    )
                }
                .frame(width: 300)
                
                // Login button
                Button(action: { Task { try await callLoginEP(username: username, password: password) }
                    // Login action
                }) {
                    Text("Log In")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 300, height: 44)
                        .background(
                            LinearGradient(
                                gradient: AppColors.primaryGradient,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
                .shadow(color: AppColors.buttonShadow, radius: 8, x: 0, y: 4)
                
                // Additional options
                HStack(spacing: 4) {
                    Text("Don't have an account?")
                        .foregroundColor(AppColors.secondaryText)
                    Button(action: {
                        // Direct route update instead of URL handling
                        urlHandler.currentRoute = .signup
                    }) {
                        Text("Sign Up")
                            .foregroundColor(AppColors.accentColor)
                            .fontWeight(.medium)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .font(.system(size: 14))
                .padding(.top, 8)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
        }
        .onAppear {
            noiseImage = loadNoiseImage(from: "background")
        }
    }
}

// Color definitions remain the same
extension AppColors {
    static let inputBackground = Color(.sRGB, red: 0.98, green: 0.98, blue: 0.98, opacity: 1)
    static let inputBorder = Color(.sRGB, red: 0.9, green: 0.9, blue: 0.9, opacity: 1)
    static let primaryText = Color(.sRGB, red: 0.1, green: 0.1, blue: 0.1, opacity: 1)
    static let secondaryText = Color(.sRGB, red: 0.6, green: 0.6, blue: 0.6, opacity: 1)
    static let buttonShadow = Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.1)
    static let accentColor = Color(.sRGB, red: 0.2, green: 0.5, blue: 1, opacity: 1)
}
