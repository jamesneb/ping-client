import Network
import Foundation

class NetworkScanner {
    
    private var browser: NWBrowser?
    
    public func scan() {
        // Create a dedicated dispatch queue for network scanning
        let scanQueue = DispatchQueue(label: "com.networkscanner.queue")
        
        // Configure the browser for the service you want to discover
        browser = NWBrowser(for: .applicationService(name: "ping.app"), using: .init())
        
        // Set the state update handler (optional, for debugging or tracking)
        browser?.stateUpdateHandler = { newState in
            switch newState {
            case .ready:
                print("Browser is ready")
            case .failed(let error):
                print("Browser failed with error: \(error)")
            case .cancelled:
                print("Browser was cancelled")
            default:
                break
            }
        }
        
        // Set the browse results handler
        browser?.browseResultsChangedHandler = { results, changes in
            // Switch back to main queue if you need to update UI
            DispatchQueue.main.async {
                for result in results {
                    print("Found service: \(result.endpoint)")
                }
            }
        }
        
        // Start the browser on the custom queue
        browser?.start(queue: scanQueue)
    }
    
    // Optional: Method to stop the scanner
    public func stop() {
        browser?.cancel()
        browser = nil
    }
}
