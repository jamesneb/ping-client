import SwiftUI

struct MeetingView: View {
    var body: some View {
        ZStack {
            PerlinBackgroundView(width: 1920, height: 1080) // Change dimensions here
            VStack {
                Text("Welcome to PresentNow!")
                    .font(.largeTitle)
                    .foregroundColor(.white)
            }
        }
    }
}
