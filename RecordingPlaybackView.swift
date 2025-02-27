import Foundation
import SwiftUI
import AVFoundation

struct RecordingPlayer: View {
    @StateObject private var playerViewModel = PlayerViewModel()
    @State private var isShowingControls = false
    
    var body: some View {
        ZStack {
            // Player view
            VideoPlayerLayerView(player: playerViewModel.player)
            
            // Controls overlay that appears on hover
            if isShowingControls {
                VStack {
                    Spacer()
                    HStack(spacing: 20) {
                        Button(action: {
                            playerViewModel.seekBackward()
                        }) {
                            Image(systemName: "backward.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(
                                    Circle()
                                        .fill(Color(hex: "34495E").opacity(0.8))
                                        .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: {
                            playerViewModel.togglePlayPause()
                        }) {
                            Image(systemName: playerViewModel.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color(hex: "8B5CF6"),
                                                    Color(hex: "EC4899")
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .shadow(color: Color(hex: "8B5CF6").opacity(0.3), radius: 8, x: 0, y: 4)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: {
                            playerViewModel.seekForward()
                        }) {
                            Image(systemName: "forward.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(
                                    Circle()
                                        .fill(Color(hex: "34495E").opacity(0.8))
                                        .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    )
                    .padding(.bottom, 20)
                }
            }
        }
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isShowingControls = hovering
            }
        }
    }
    
    // Function to play the recording
    func play() {
        playerViewModel.play()
    }
    
    // Function to pause the recording
    func pause() {
        playerViewModel.pause()
    }
    
    // Function to load a new recording
    func load(url: URL) {
        playerViewModel.loadVideo(url: url)
    }
}

// ViewModel to manage AVPlayer state
class PlayerViewModel: ObservableObject {
    @Published var player = AVPlayer()
    @Published var isPlaying = false
    @Published var duration: Double = 0.0
    @Published var currentTime: Double = 0.0
    
    private var timeObserver: Any?
    private var statusObserver: NSKeyValueObservation?
    
    init() {
        setupTimeObserver()
    }
    
    deinit {
        if let timeObserver = timeObserver {
            player.removeTimeObserver(timeObserver)
        }
        statusObserver?.invalidate()
    }
    
    func loadVideo(url: URL) {
        let playerItem = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: playerItem)
        
        // Observe the duration
        statusObserver = playerItem.observe(\.status, options: [.new]) { [weak self] playerItem, _ in
            if playerItem.status == .readyToPlay {
                self?.duration = playerItem.duration.seconds
            }
        }
    }
    
    func play() {
        player.play()
        isPlaying = true
    }
    
    func pause() {
        player.pause()
        isPlaying = false
    }
    
    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }
    
    func seekForward() {
        let currentTime = CMTimeGetSeconds(player.currentTime())
        let newTime = min(currentTime + 10.0, duration)
        player.seek(to: CMTime(seconds: newTime, preferredTimescale: 600))
    }
    
    func seekBackward() {
        let currentTime = CMTimeGetSeconds(player.currentTime())
        let newTime = max(currentTime - 10.0, 0)
        player.seek(to: CMTime(seconds: newTime, preferredTimescale: 600))
    }
    
    private func setupTimeObserver() {
        // Update currentTime every second
        timeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 600), queue: .main) { [weak self] time in
            guard let self = self else { return }
            self.currentTime = time.seconds
            // Check if the video ended
            if self.currentTime >= self.duration && self.duration > 0 {
                self.isPlaying = false
            }
        }
    }
}

// NSViewRepresentable for AVPlayer
struct VideoPlayerLayerView: NSViewRepresentable {
    let player: AVPlayer
    
    func makeNSView(context: Context) -> PlayerContainerView {
        let view = PlayerContainerView()
        view.playerLayer.player = player
        return view
    }
    
    func updateNSView(_ nsView: PlayerContainerView, context: Context) {
        nsView.playerLayer.player = player
    }
}

// Custom NSView that hosts the AVPlayerLayer
class PlayerContainerView: NSView {
    let playerLayer = AVPlayerLayer()
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupLayer()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayer()
    }
    
    private func setupLayer() {
        self.wantsLayer = true
        self.layer = CALayer()
        self.layer?.addSublayer(playerLayer)
        playerLayer.videoGravity = .resizeAspect
    }
    
    override func layout() {
        super.layout()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        playerLayer.frame = self.bounds
        CATransaction.commit()
    }
}

