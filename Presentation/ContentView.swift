import SwiftUI

struct ContentView: View {
   // MARK: - State Management
   @StateObject private var viewModel = WebSocketViewModel()
   @State private var nickname: String = UserData().nickname
   @State private var passcode: String = ""
   @State private var noiseImage: NSImage?
   @EnvironmentObject private var audioViewModel: AudioMeterViewModel
   @EnvironmentObject private var cameraViewModel: CameraViewModel
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
       ZStack {
           HStack {
               Button(action: { urlHandler.currentRoute = .login }) {
                   HStack(spacing: 8) {
                       Image(systemName: "chevron.left")
                           .font(.system(size: 16, weight: .medium))
                       Text("Back")
                           .font(.system(size: 14, weight: .medium))
                   }
               }
               .buttonStyle(PlainButtonStyle())
               .modifier(BaseButton(
                   gradient: AppColors.badgeGradient,
                   pressedGradient: AppColors.badgeGradient
               ))
               
               Spacer()
           }
           .padding(.top, 16)
           
           Text("Join Meeting")
               .font(.system(size: 24, weight: .bold))
               .foregroundColor(AppColors.textPrimary)
               .frame(maxWidth: .infinity)
               .padding(.top, 16)
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
               }
               
               CameraView()
                   .frame(height: 200)
                   .clipShape(RoundedRectangle(cornerRadius: 12))
                   .overlay(
                       RoundedRectangle(cornerRadius: 12)
                           .stroke(AppColors.inputBorder, lineWidth: 1)
                   )
                   .onAppear {
                       cameraViewModel.startCapture()
                   }
                   .onDisappear {
                       cameraViewModel.stopCapture()
                   }
               
               if let error = cameraViewModel.error {
                   Text(error)
                       .font(.system(size: 12))
                       .foregroundColor(.red)
                       .padding(.top, 8)
               }
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
               
               // Center the AudioMeterView
               HStack {
                   Spacer()
                   AudioMeterView()
                   Spacer()
               }
           }
       }
       .modifier(BaseContainer())
   }
   
   private var userCredentialsSection: some View {
       VStack(spacing: 16) {
           VStack(spacing: 20) {
               formField(
                   title: "Display Name",
                   text: $nickname,
                   icon: "person.fill",
                   isFocused: $isDisplayNameFocused
               ).foregroundStyle(Color.black)
               
               formField(
                   title: "Meeting Passcode",
                   text: $passcode,
                   icon: "lock.fill",
                   isSecure: true,
                   isFocused: $isPasscodeFocused
               ).foregroundStyle(Color.black)
           }
           
           // Connect button
           Button(action: handleConnect) {
               Text("Connect")
                   .font(.system(size: 14, weight: .semibold))
                   .frame(height: 36)
                   .frame(width: 120)
                   .foregroundColor(Color(red: 0.45, green: 0.4, blue: 0.8))
                   .background(Color(red: 0.98, green: 0.98, blue: 1.0))
                   .cornerRadius(12)
                   .overlay(
                       RoundedRectangle(cornerRadius: 12)
                           .stroke(
                               LinearGradient(
                                   gradient: Gradient(colors: [
                                       Color(red: 0.45, green: 0.4, blue: 0.8).opacity(0.5),
                                       Color(red: 0.45, green: 0.4, blue: 0.8).opacity(0.3)
                                   ]),
                                   startPoint: .top,
                                   endPoint: .bottom
                               ),
                               lineWidth: 1
                           )
                   )
                   .shadow(
                       color: Color(red: 0.45, green: 0.4, blue: 0.8).opacity(0.1),
                       radius: 4,
                       x: 0,
                       y: 2
                   )
           }
           .buttonStyle(PlainButtonStyle())
           .disabled(nickname.isEmpty || passcode.isEmpty)
           .onHover { hovering in
               withAnimation(.easeInOut(duration: 0.2)) {
                   if hovering {
                       NSCursor.pointingHand.push()
                   } else {
                       NSCursor.pop()
                   }
               }
           }
       }
       .modifier(BaseContainer())
   }
   
   private var participantsIndicator: some View {
       HStack {
           Image(systemName: "person.2.fill")
               .foregroundColor(AppColors.textSecondary)
           Text("Participants")
               .font(.system(size: 14, weight: .semibold))
               .foregroundColor(AppColors.textPrimary)
           
           Circle()
               .fill(LinearGradient(
                   gradient: AppColors.badgeGradient,
                   startPoint: .top,
                   endPoint: .bottom
               ))
               .frame(width: 20, height: 20)
               .overlay(
                   Text("3")
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
       .modifier(BaseContainer())
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
           .modifier(BaseInput())
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

#Preview {
   ContentView()
       .environmentObject(URLHandler())
}
