import Foundation
import SwiftUI
import AVFoundation

struct LoginResponse: Codable {
    let status: Int?
    let userId: String?
    let message: String?
}

enum LoginError: Error {
    case invalidResponse
    case invalidData
    case networkError
}

func callLoginEP(username: String, password: String) async throws -> LoginResponse {
    guard let url = URL(string: "http://localhost:8080/login") else {
        throw LoginError.invalidResponse
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    // Create a Codable struct for the request body
    struct LoginRequest: Codable {
        let username: String
        let password: String
    }
    
    let loginRequest = LoginRequest(username: username, password: password)
    let jsonData = try JSONEncoder().encode(loginRequest)
    request.httpBody = jsonData
    
    do {
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LoginError.networkError
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw LoginError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(LoginResponse.self, from: data)
        print(decoded)
        return decoded
    } catch let error as DecodingError {
        print("Decoding error: \(error)")
        throw LoginError.invalidData
    } catch {
        print("Network error: \(error)")
        throw LoginError.networkError
    }
}

class SoundManager {
    static let shared = SoundManager()
    private var audioPlayer: AVAudioPlayer?
    
    func playNotificationSound() {
        guard let soundURL = Bundle.main.url(forResource: "InputError 3", withExtension: "wav") else {
            print("Sound file not found")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.play()
        } catch {
            print("Could not play sound: \(error)")
        }
    }
    
    func playSuccessSound() {
        guard let soundUrl = Bundle.main.url(forResource: "success", withExtension: "wav") else {
            print("Sound file not found")
            return
        }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundUrl)
            audioPlayer?.play()
        } catch {
            print("Could not play sound: \(error)")
        }
    }
    func playCancelSound() {
        guard let soundUrl = Bundle.main.url(forResource: "cancel", withExtension: "wav") else {
            print("Sound file not found")
            return
        }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundUrl)
            audioPlayer?.play()
        } catch {
            print("Could not play sound: \(error)")
        }
    }
    
    func playHandRaisedSound() {
        guard let soundUrl = Bundle.main.url(forResource: "chime", withExtension: "wav") else {
            print("Sound file not found")
            return
        }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundUrl)
            audioPlayer?.play()
            
        } catch {
            print ("Could not play sound: \(error)")
        }
    }
    
    func playScreenSharedSound() {
        guard let soundUrl = Bundle.main.url(forResource: "screensharechime", withExtension: "wav") else {
            print("Sound file not found")
            return
        }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundUrl)
            audioPlayer?.play()
            
        } catch {
            print ("Could not play sound: \(error)")
        }
    }
}



public struct LoginView: View {
    @State private var noiseImage: NSImage?
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var showToast: Bool = false
    @State private var toastMessage: String = ""
    @State private var isLoggedIn: Bool = false
    @EnvironmentObject private var urlHandler: URLHandler
    
    public var body: some View {
        if isLoggedIn {
            NavigationSplitView {
                // Sidebar content
                List {
                    NavigationLink("Item 1", value: "item1")
                    NavigationLink("Item 2", value: "item2")
                }
            } detail: {  // <-- This 'a' here is a typo
                // Detail view
                Text("Select an item")
            }
        } else {
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
                    Button(action: {
                        Task {
                            do {
                                let response = try await callLoginEP(username: username, password: password)
                                if (response.status ?? 400 > 299 || response.status ?? 400 < 200) {
                                    showToast(message: "Error: Status \(response.status ?? 0) - \(response.message ?? "Unknown error")")
                                } else {
                                    SoundManager.shared.playSuccessSound()
                                    urlHandler.currentRoute = .controlPanel
                                }
                            } catch LoginError.invalidResponse {
                                showToast(message: "Error: Invalid response from server")
                            } catch LoginError.invalidData {
                                showToast(message: "Error: Invalid data received")
                            } catch LoginError.networkError {
                                showToast(message: "Error: Invalid username or password")
                            } catch {
                                showToast(message: "Error: Unexpected error occurred")
                            }
                        }
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
                
                // Toast overlay
                if showToast {
                    VStack {
                        Spacer()
                        ToastView(message: toastMessage)
                            .padding(.bottom, 32)
                    }
                    .transition(AnyTransition.move(edge: .bottom).combined(with: .opacity))
                    .animation(.easeInOut(duration: 1), value: showToast)
                }
            }
            .onAppear {
                noiseImage = loadNoiseImage(from: "background")
            }
        }
    }
    private func showToast(message: String) {
        toastMessage = message
        withAnimation(.easeInOut(duration: 0.8)) {
            showToast = true
        }
        SoundManager.shared.playNotificationSound()
        
        // Automatically hide the toast after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation(.easeInOut(duration: 0.8)) {
                showToast = false
            }
        }
    }
}

// Color definitions remain the same
extension AppColors {
    static let primaryText = Color(.sRGB, red: 0.1, green: 0.1, blue: 0.1, opacity: 1)
    static let secondaryText = Color(.sRGB, red: 0.6, green: 0.6, blue: 0.6, opacity: 1)
    static let buttonShadow = Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.1)
    static let accentColor = Color(.sRGB, red: 0.2, green: 0.5, blue: 1, opacity: 1)
  
}
