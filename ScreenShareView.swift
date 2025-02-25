import SwiftUI
import ScreenCaptureKit
import AVFoundation
import Network
struct ScreenShareView: View {
    @ObservedObject var screenCaptureViewModel: ScreenCaptureViewModel
    @EnvironmentObject var cameraViewModel: CameraViewModel

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Main content
                if let image = screenCaptureViewModel.latestFrame {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: geometry.size.width, maxHeight: geometry.size.height)
                        .background(
                            Color.black.opacity(0.2)
                                .blur(radius: 20)
                                .overlay(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(hex: "1E293B").opacity(0.8),
                                            Color(hex: "0F172A").opacity(0.6)
                                        ]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.white.opacity(0.2),
                                            Color(hex: "4338CA").opacity(0.3),
                                            Color.clear
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                        .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 5)
                } else {
                    Text("Waiting for screen capture...")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.7))
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.black.opacity(0.3))
                                .blur(radius: 5)
                        )
                }
                
                PresenterOverlay(cameraViewModel: cameraViewModel)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Custom overlay for selection
                if screenCaptureViewModel.isShowingSelection {
                    Color.black.opacity(0.5)
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture {
                            screenCaptureViewModel.isShowingSelection = false
                        }
                        .zIndex(1)

                    SelectionView(viewModel: screenCaptureViewModel)
                        .frame(width: 500, height: 400)
                        .zIndex(2)
                        .transition(.opacity)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .onAppear {
            screenCaptureViewModel.startScreenCapture()
        }
        .animation(.easeInOut(duration: 0.3), value: screenCaptureViewModel.isShowingSelection)
    }
}

struct SelectionView: View {
    @ObservedObject var viewModel: ScreenCaptureViewModel
    @StateObject private var networkScannerViewModel = NetworkScannerViewModel()
    @State private var selectedDisplay: SCDisplay?
    @State private var selectedWindow: SCWindow?
    @State private var selectedService: NWBrowser.Result?
    @State private var previewViewModels: [UInt32: DisplayPreviewViewModel] = [:]

    var body: some View {
        let vm = viewModel // Local capture for closure safety
        
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "1E293B"),
                    Color(hex: "0F172A")
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.3), radius: 15, x: 0, y: 5)

            VStack(spacing: 20) {
                Text("Select Screen, Window, or Network Service")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.top, 20)

                Divider()
                    .background(Color.white.opacity(0.2))

                if let content = vm.availableContent {
                    ScrollView {
                        VStack(spacing: 20) {
                            Text("Displays")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 10)], spacing: 10) {
                                ForEach(content.displays, id: \.displayID) { display in
                                    DisplayPreviewCard(
                                        previewViewModel: previewViewModel(for: display),
                                        display: display,
                                        isSelected: selectedDisplay?.displayID == display.displayID,
                                        action: {
                                            selectedDisplay = display
                                            selectedWindow = nil
                                            selectedService = nil
                                        }
                                    )
                                }
                            }

                            Text("Windows")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 10)

                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 10)], spacing: 10) {
                                ForEach(content.windows, id: \.windowID) { window in
                                    WindowPreviewCard(
                                        window: window,
                                        isSelected: selectedWindow?.windowID == window.windowID,
                                        action: {
                                            selectedWindow = window
                                            selectedDisplay = nil
                                            selectedService = nil
                                        }
                                    )
                                }
                            }

                            Text("Network Services")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 10)

                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 10)], spacing: 10) {
                                ForEach(networkScannerViewModel.discoveredServices, id: \.endpoint) { service in
                                    NetworkServiceCard(
                                        service: service,
                                        isSelected: selectedService?.endpoint == service.endpoint,
                                        action: {
                                            selectedService = service
                                            selectedDisplay = nil
                                            selectedWindow = nil
                                        }
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                } else {
                    Text("Loading available content...")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }

                Button(action: {
                    previewViewModels.values.forEach { $0.stopStream() }
                    if let service = selectedService {
                        print("Selected network service: \(service.endpoint)")
                        // Handle network service selection if needed
                    } else {
                        vm.startCaptureWithSelection(display: selectedDisplay, window: selectedWindow) // Use local vm
                    }
                    vm.isShowingSelection = false
                }) {
                    Text("Start Capture")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: "4338CA"),
                                    Color(hex: "7C3AED")
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: Color(hex: "4338CA").opacity(0.4), radius: 8, x: 0, y: 4)
                }
                .disabled(selectedDisplay == nil && selectedWindow == nil && selectedService == nil)
                .opacity((selectedDisplay == nil && selectedWindow == nil && selectedService == nil) ? 0.6 : 1.0)
                .padding(.bottom, 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 500, height: 400)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(hex: "4338CA").opacity(0.5),
                            Color(hex: "7C3AED").opacity(0.3),
                            Color.clear
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .onAppear {
            if let content = vm.availableContent {
                for display in content.displays {
                    let previewVM = DisplayPreviewViewModel(display: display)
                    previewViewModels[display.displayID] = previewVM
                    previewVM.startStream()
                }
            }
        }
        .onDisappear {
            previewViewModels.values.forEach { $0.stopStream() }
        }
    }

    private func previewViewModel(for display: SCDisplay) -> DisplayPreviewViewModel {
        if let existing = previewViewModels[display.displayID] {
            return existing
        }
        let newVM = DisplayPreviewViewModel(display: display)
        previewViewModels[display.displayID] = newVM
        newVM.startStream()
        return newVM
    }
}

// Network Service Card
struct NetworkServiceCard: View {
    let service: NWBrowser.Result
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: "network")
                    .font(.system(size: 40))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 140, height: 80)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(hex: "1E293B").opacity(0.5),
                                Color(hex: "0F172A").opacity(0.3)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                
                Text(service.endpoint.debugDescription)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            .padding(10)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color(hex: "4338CA").opacity(0.8) : Color.black.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(isSelected ? 0.5 : 0.2),
                                        Color(hex: "4338CA").opacity(0.5)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
            )
            .shadow(color: isSelected ? Color(hex: "4338CA").opacity(0.3) : .clear, radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}
// View Model for Live Display Previews
class DisplayPreviewViewModel: NSObject, ObservableObject, SCStreamOutput {
    @Published var previewFrame: NSImage?
    private let display: SCDisplay
    private var stream: SCStream?

    init(display: SCDisplay) {
        self.display = display
        super.init()
    }

    func startStream() {
        Task {
            do {
                let filter = SCContentFilter(display: display, excludingWindows: [])
                let config = SCStreamConfiguration()
                config.width = 140 // Small preview size
                config.height = 80
                config.minimumFrameInterval = CMTime(value: 1, timescale: 10) // 10 FPS

                stream = SCStream(filter: filter, configuration: config, delegate: nil)
                try stream?.addStreamOutput(self, type: .screen, sampleHandlerQueue: .main)
                try await stream?.startCapture()
            } catch {
                print("Failed to start preview stream for display \(display.displayID): \(error)")
            }
        }
    }

    func stopStream() {
        Task {
            do {
                try await stream?.stopCapture()
                stream = nil
            } catch {
                print("Failed to stop preview stream for display \(display.displayID): \(error)")
            }
        }
    }

    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .screen, let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let ciImage = CIImage(cvImageBuffer: imageBuffer)
        let context = CIContext()
        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
            let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: 140, height: 80))
            DispatchQueue.main.async {
                self.previewFrame = nsImage
            }
        }
    }
}

// Display Preview Card with Live Stream
struct DisplayPreviewCard: View {
    @ObservedObject var previewViewModel: DisplayPreviewViewModel
    let display: SCDisplay
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                if let image = previewViewModel.previewFrame {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 140, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                } else {
                    Image(systemName: "display")
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 140, height: 80)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: "1E293B").opacity(0.5),
                                    Color(hex: "0F172A").opacity(0.3)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                VStack(spacing: 4) {
                    Text("Display \(display.displayID)")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Text("\(Int(display.width)) x \(Int(display.height))")
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color(hex: "4338CA").opacity(0.8) : Color.black.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(isSelected ? 0.5 : 0.2),
                                        Color(hex: "4338CA").opacity(0.5)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
            )
            .shadow(color: isSelected ? Color(hex: "4338CA").opacity(0.3) : .clear, radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// Window Preview Card (Icon-Based)
struct WindowPreviewCard: View {
    let window: SCWindow
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: "window.rectangle")
                    .font(.system(size: 40))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 140, height: 80)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(hex: "1E293B").opacity(0.5),
                                Color(hex: "0F172A").opacity(0.3)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                
                Text(window.title ?? "Untitled Window")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            .padding(10)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color(hex: "4338CA").opacity(0.8) : Color.black.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(isSelected ? 0.5 : 0.2),
                                        Color(hex: "4338CA").opacity(0.5)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
            )
            .shadow(color: isSelected ? Color(hex: "4338CA").opacity(0.3) : .clear, radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// Rest of your file (PresenterOverlay, Color extension) remains unchanged...
struct PresenterOverlay: View {
    @ObservedObject var cameraViewModel: CameraViewModel
    @State private var position: CGPoint
    @State private var isDragging = false
    let size: CGSize = CGSize(width: 200, height: 150)

    init(cameraViewModel: CameraViewModel) {
        self.cameraViewModel = cameraViewModel
        self._position = State(initialValue: CGPoint(x: 0, y: 0))
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                CameraView()
                    .environmentObject(cameraViewModel)
                    .frame(width: size.width, height: size.height)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.black.opacity(0.1))
                            .blur(radius: 10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.05))
                                    .blur(radius: 5)
                            )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(hex: "4338CA").opacity(0.8),
                                        Color(hex: "7C3AED").opacity(0.5),
                                        Color(hex: "DB2777").opacity(0.3)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(color: Color(hex: "4338CA").opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .position(
                x: max(min(position.x, geometry.size.width - size.width / 2), size.width / 2),
                y: max(min(position.y, geometry.size.height - size.height / 2), size.height / 2)
            )
            .gesture(
                DragGesture()
                    .onChanged { value in
                        position = value.location
                        isDragging = true
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
            .scaleEffect(isDragging ? 1.05 : 1.0)
            .opacity(isDragging ? 0.9 : 1.0)
            .animation(.interactiveSpring(response: 0.4, dampingFraction: 0.8), value: position)
            .animation(.spring(response: 0.3), value: isDragging)
            .onAppear {
                position = CGPoint(
                    x: geometry.size.width - size.width / 2 - 20,
                    y: geometry.size.height - size.height / 2 - 20
                )
                print("PresenterOverlay appeared, ensuring camera capture...")
                cameraViewModel.startCapture()
            }
        }
    }
}
