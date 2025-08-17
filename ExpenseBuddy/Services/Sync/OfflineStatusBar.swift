import Foundation
import SwiftUI

struct OfflineStatusBar: View {
    @ObservedObject private var networkService = NetworkService.shared
      @ObservedObject private var syncService = OfflineSyncService.shared
      @ObservedObject private var currencyService = CurrencyService.shared
      @State private var showDetails = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Main status bar
            HStack(spacing: 12) {
                // Status indicator
                HStack(spacing: 8) {
                    statusIcon
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(statusTitle)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(statusColor)
                        
                        Text(statusMessage)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Currency indicator
                HStack(spacing: 8) {
                    Text(currencyService.selectedCurrency.symbol)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                    
                    Text(currencyService.selectedCurrency.rawValue.uppercased())
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                // Action button
                if syncService.isSyncing {
                    ProgressView()
                        .scaleEffect(0.7)
                } else {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showDetails.toggle()
                        }
                    }) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                            .rotationEffect(.degrees(showDetails ? 180 : 0))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(statusBackgroundColor)
            
            // Details section
            if showDetails {
                OfflineDetailsView()
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private var statusIcon: some View {
        Group {
            switch syncService.syncStatus {
            case .offline:
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                    Image(systemName: "wifi.slash")
                        .foregroundColor(.orange)
                }
            case .syncing:
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                        .scaleEffect(1.2)
                        .animation(.easeInOut(duration: 1).repeatForever(), value: syncService.isSyncing)
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundColor(.blue)
                }
            case .success:
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            case .failed:
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                }
            case .idle:
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Image(systemName: "cloud")
                        .foregroundColor(.blue)
                }
            }
        }
    }
    
    private var statusTitle: String {
        switch syncService.syncStatus {
        case .offline:
            return "Offline"
        case .syncing:
            return "Syncing..."
        case .success:
            return "Online"
        case .failed:
            return "Sync failed"
        case .idle:
            return networkService.isConnected ? "Online" : "Offline"
        }
    }
    
    private var statusMessage: String {
        switch syncService.syncStatus {
        case .offline:
            return syncService.pendingChanges > 0 ?
                "\(syncService.pendingChanges) changes pending" :
                "Data saved locally"
        case .syncing:
            return "Updating expenses..."
        case .success:
            return "All data synchronized"
        case .failed:
            return "Will retry automatically"
        case .idle:
            return syncService.pendingChanges > 0 ?
                "\(syncService.pendingChanges) changes to sync" :
                "Everything up to date"
        }
    }
    
    private var statusColor: Color {
        switch syncService.syncStatus {
        case .offline:
            return .orange
        case .syncing:
            return .blue
        case .success:
            return .green
        case .failed:
            return .red
        case .idle:
            return networkService.isConnected ? .green : .orange
        }
    }
    
    private var statusBackgroundColor: Color {
        statusColor.opacity(0.1)
    }
}

struct OfflineDetailsView: View {
    @ObservedObject private var syncService = OfflineSyncService.shared
    @ObservedObject private var networkService = NetworkService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Sync Details")
                    .font(.caption)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                DetailRow(
                    icon: "wifi",
                    title: "Network Status",
                    value: networkService.isConnected ? "Connected" : "Offline",
                    color: networkService.isConnected ? .green : .red
                )
                
                DetailRow(
                    icon: "arrow.triangle.2.circlepath",
                    title: "Pending Changes",
                    value: "\(syncService.pendingChanges)",
                    color: syncService.pendingChanges > 0 ? .orange : .green
                )
                
                if let lastSync = syncService.lastSyncTime {
                    DetailRow(
                        icon: "clock",
                        title: "Last Sync",
                        value: RelativeDateTimeFormatter().localizedString(for: lastSync, relativeTo: Date()),
                        color: .blue
                    )
                }
            }
            
            if networkService.isConnected && syncService.pendingChanges > 0 {
                Button(action: {
                    Task {
                        await syncService.performSync()
                    }
                }) {
                    HStack {
                        if syncService.isSyncing {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                        }
                        Text("Sync Now")
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(syncService.isSyncing)
            }
        }
        .padding(16)
        .background(Color(.systemGray6).opacity(0.5))
    }
}


#Preview{
    OfflineStatusBar()
        
}
