import Foundation
import Combine

class OfflineSyncService: ObservableObject {
    static let shared = OfflineSyncService()
    
    private let networkService = NetworkService.shared
    private let coreDataService = CoreDataService.shared
    @Published var isSyncing = false
    @Published var lastSyncTime: Date?
    @Published var syncStatus: SyncStatus = .idle
    @Published var pendingChanges = 0
    
    enum SyncStatus {
        case idle
        case syncing
        case success
        case failed(String)
        case offline
    }
    
    private init() {
        loadLastSyncTime()
        updatePendingChanges()
        
        // Monitor network changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(networkStatusChanged),
            name: .networkStatusChanged,
            object: nil
        )
    }
    
    private func loadLastSyncTime() {
        if let timestamp = UserDefaults.standard.object(forKey: "last_sync_time") as? Date {
            lastSyncTime = timestamp
        }
    }
    
    private func updatePendingChanges() {
        pendingChanges = coreDataService.getUnsyncedExpenses().count
    }
    
    @objc private func networkStatusChanged() {
        if networkService.isConnected {
            syncStatus = .idle
            Task {
                await performSync()
            }
        } else {
            syncStatus = .offline
        }
    }
    
    func performSync() async {
        guard !isSyncing, networkService.isConnected else {
            syncStatus = .offline
            return
        }
        
        await MainActor.run {
            isSyncing = true
            syncStatus = .syncing
        }
        
        do {
            // First, upload local changes
            try await uploadLocalChanges()
            
            // Then, download server changes
            try await downloadServerChanges()
            
            // Update last sync time
            let syncTime = Date()
            UserDefaults.standard.set(syncTime, forKey: "last_sync_time")
            
            await MainActor.run {
                lastSyncTime = syncTime
                syncStatus = .success
                updatePendingChanges()
            }
            
        } catch {
            print("Sync failed: \(error)")
            await MainActor.run {
                syncStatus = .failed(error.localizedDescription)
            }
        }
        
        await MainActor.run {
            isSyncing = false
        }
    }
    
    private func uploadLocalChanges() async throws {
        let unsyncedExpenses = coreDataService.getUnsyncedExpenses()
        
        guard !unsyncedExpenses.isEmpty else { return }
        
        let syncData = unsyncedExpenses.compactMap { entity -> SyncExpenseData? in
            guard let id = entity.id,
                  let title = entity.title,
                  let category = entity.category,
                  let currency = entity.currency,
                  let date = entity.date else {
                return nil
            }
            
            return SyncExpenseData(
                id: entity.syncedAt != nil ? id : nil,
                title: title,
                amount: entity.amount,
                category: category,
                currency: currency,
                date: ISO8601DateFormatter().string(from: date),
                description: entity.descriptionText,
                operation: entity.isDelete ? .DELETE : (entity.syncedAt != nil ? .UPDATE : .CREATE),
                localId: id
            )
        }
        
        struct SyncRequest: Codable {
            let expenses: [SyncExpenseData]
        }
        
        let response: SyncResponse = try await networkService.request(
            endpoint: "/sync/expenses",
            method: "POST",
            body: SyncRequest(expenses: syncData),
            responseType: SyncResponse.self,
            requiresAuth: true
        )
        
        // Update local data based on sync results
        for result in response.results {
            if result.success, let localId = result.localId {
                coreDataService.markExpenseAsSynced(localId: localId, serverData: result.data)
            }
        }
    }
    
    private func downloadServerChanges() async throws {
        let lastSync = lastSyncTime ?? Date(timeIntervalSince1970: 0)
        
        let response: ServerExpensesResponse = try await networkService.request(
            endpoint: "/sync/expenses?lastSyncTime=\(ISO8601DateFormatter().string(from: lastSync))",
            responseType: ServerExpensesResponse.self,
            requiresAuth: true
        )
        
        // Update local Core Data with server changes
        for expense in response.expenses {
            coreDataService.saveExpenseLocally(expense)
        }
    }
}

struct SyncExpenseData: Codable {
    let id: String?
    let title: String
    let amount: Double
    let category: String
    let currency: String
    let date: String
    let description: String?
    let operation: SyncOperation
    let localId: String?
}

enum SyncOperation: String, Codable {
    case CREATE = "CREATE"
    case UPDATE = "UPDATE"
    case DELETE = "DELETE"
}

struct SyncResponse: Codable {
    let results: [SyncResult]
    let summary: SyncSummary?
}

struct SyncResult: Codable {
    let success: Bool
    let data: Expense?
    let localId: String?
    let error: String?
}

struct SyncSummary: Codable {
    let total: Int
    let successful: Int
    let failed: Int
}

struct ServerExpensesResponse: Codable {
    let expenses: [Expense]
}

extension Notification.Name {
    static let networkStatusChanged = Notification.Name("networkStatusChanged")
}
