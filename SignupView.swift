import Foundation
import SwiftUI

enum SignupError: Error {
   case networkError(Error)
   case invalidResponse
   case decodingError(Error)
}

struct SignupResponse: Codable {
   let userId: String?
   let message: String?
}

func callSignupEP(username: String, password: String, email: String, firstname: String, lastname: String) async throws -> SignupResponse {
   guard let url = URL(string: "http://localhost:8080/signup") else {
       throw SignupError.invalidResponse
   }
   
   var request = URLRequest(url: url)
   request.httpMethod = "POST"
   request.setValue("application/json", forHTTPHeaderField: "Content-Type")
   
   let jsonBody: [String: Any] = [
       "username": username,
       "password": password,
       "email": email,
       "firstName": firstname,
       "lastName": lastname
   ]
   
   do {
       let jsonData = try JSONSerialization.data(withJSONObject: jsonBody, options: [])
       request.httpBody = jsonData
       
       let (data, _) = try await URLSession.shared.data(for: request)
       
       let decoder = JSONDecoder()
       let responseData = try decoder.decode(SignupResponse.self, from: data)
       return responseData
   } catch let error as URLError {
       throw SignupError.networkError(error)
   } catch let error as DecodingError {
       throw SignupError.decodingError(error)
   } catch {
       throw SignupError.networkError(error)
   }
}

public struct SignupView: View {
   @State private var noiseImage: NSImage?
   @State private var username: String = ""
   @State private var password: String = ""
   @State private var firstName: String = ""
   @State private var lastName: String = ""
   @State private var email: String = ""
   @State private var showToast: Bool = false
   @State private var toastMessage: String = ""
   @EnvironmentObject private var urlHandler: URLHandler
   
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
               // Back Button
               HStack {
                   Button(action: {
                       urlHandler.currentRoute = .login
                   }) {
                       HStack(spacing: 4) {
                           Image(systemName: "chevron.left")
                               .font(.system(size: 14, weight: .semibold))
                           Text("Back")
                               .font(.system(size: 14, weight: .medium))
                       }
                       .foregroundColor(AppColors.accentColor)
                   }
                   .buttonStyle(PlainButtonStyle())
                   .padding(.bottom, 8)
                   
                   Spacer()
               }
               
               // Account Section
               VStack(alignment: .leading, spacing: 16) {
                   Text("Account Details")
                       .font(.system(size: 14, weight: .semibold))
                       .foregroundColor(AppColors.textPrimary)
                   
                   VStack(spacing: 12) {
                       formField(title: "Username", text: $username)
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
                   Task {
                       do {
                           let response = try await callSignupEP(
                               username: username,
                               password: password,
                               email: email,
                               firstname: firstName,
                               lastname: lastName
                           )
                           if response.userId != nil || response.message ?? "no" == "User created successfully" {
                               SoundManager.shared.playSuccessSound()
                               urlHandler.currentRoute = .controlPanel
                           } else {
                               showToast(message: response.message ?? "Signup failed")
                           }
                       } catch SignupError.networkError(let error) {
                           showToast(message: "Network error: \(error.localizedDescription)")
                       } catch SignupError.invalidResponse {
                           showToast(message: "Invalid response from server")
                       } catch SignupError.decodingError {
                           showToast(message: "Error processing server response")
                       } catch {
                           showToast(message: "An unexpected error occurred")
                       }
                   }
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
           .frame(width: 320)
           
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
