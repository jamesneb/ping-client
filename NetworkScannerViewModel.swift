import SwiftUI
import Network

class NetworkScannerViewModel: ObservableObject {
    @Published var discoveredServices: [NWBrowser.Result] = []
    private var browser: NWBrowser?
    private let scanQueue = DispatchQueue(label: "com.networkscanner.queue")
    
    init() {
        startScanning()
    }
    
    func startScanning() {
        browser = NWBrowser(for: .applicationService(name: "ping.app"), using: .init())
        
        browser?.stateUpdateHandler = { newState in
            switch newState {
            case .ready:
                print("Network scanner ready")
            case .failed(let error):
                print("Network scanner failed: \(error)")
            case .cancelled:
                print("Network scanner cancelled")
            default:
                break
            }
        }
        
        browser?.browseResultsChangedHandler = { [weak self] results, changes in
            DispatchQueue.main.async {
                self?.discoveredServices = Array(results)
            }
        }
        
        browser?.start(queue: scanQueue)
    }
    
    func stopScanning() {
        browser?.cancel()
        browser = nil
    }
    
    deinit {
        stopScanning()
    }
}
