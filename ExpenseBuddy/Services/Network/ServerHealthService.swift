import Foundation
import Combine

class ServerHealthService: ObservableObject {
    static let shared = ServerHealthService()
    
    @Published var isServerReachable = false
    @Published var lastChecked: Date?
    
    private let networkService = NetworkService.shared
    private var healthCheckTimer: Timer?
    
    private init() {
        startHealthCheck()
    }
    
    func startHealthCheck() {
        // Check immediately
        Task {
            await checkServerHealth()
        }
        
        // Then check every 30 seconds
        healthCheckTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            Task { @MainActor in
                await self.checkServerHealth()
            }
        }
    }
    
    func checkServerHealth() async {
        guard networkService.isConnected else {
            await MainActor.run {
                isServerReachable = false
                lastChecked = Date()
            }
            return
        }
        
        do {
            // Simple ping to server
            let _: HealthResponse = try await networkService.request(
                endpoint: "/health",
                responseType: HealthResponse.self,
                retryCount: 0
            )
            
            await MainActor.run {
                isServerReachable = true
                lastChecked = Date()
            }
        } catch {
            await MainActor.run {
                isServerReachable = false
                lastChecked = Date()
            }
        }
    }
    
    deinit {
        healthCheckTimer?.invalidate()
    }
}

struct HealthResponse: Codable {
    let status: String
    let timestamp: String
}
