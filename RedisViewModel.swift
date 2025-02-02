import SwiftUI

class RedisViewModel: ObservableObject {
    @Published var isConnected: Bool = false

    func connect() {
        Task { @MainActor in  // Ensure UI updates happen on the main thread
            let result = await connectToRedis()
            self.isConnected = result
        }
    }
}

