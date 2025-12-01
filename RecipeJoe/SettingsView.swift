//
//  SettingsView.swift
//  RecipeJoe
//
//  Created by Oliver Staub on 25.11.2025.
//

import SwiftUI

struct SettingsView: View {
    @State private var syncManager = SyncStatusManager()

    var body: some View {
        NavigationStack {
            List {
                // MARK: - Sync Status Section
                Section {
                    SyncStatusRow(syncManager: syncManager)
                } header: {
                    Text("iCloud Sync")
                } footer: {
                    Text("Your recipes sync automatically across all your devices signed into the same iCloud account.")
                }

                // MARK: - About Section
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.appVersion)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .refreshable {
                await syncManager.refresh()
            }
        }
    }
}

// MARK: - Sync Status Row

private struct SyncStatusRow: View {
    let syncManager: SyncStatusManager

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: syncManager.syncStatus.systemImage)
                .font(.title2)
                .foregroundStyle(statusColor)
                .symbolEffect(.pulse, isActive: syncManager.syncStatus == .syncing)

            VStack(alignment: .leading, spacing: 4) {
                Text("Sync Status")
                    .font(.body)

                Text(syncManager.syncStatus.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let lastSync = syncManager.lastSyncDate {
                    Text("Last synced: \(lastSync.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
        .accessibilityIdentifier("syncStatusRow")
    }

    private var statusColor: Color {
        switch syncManager.syncStatus {
        case .synced:
            return .green
        case .syncing:
            return .blue
        case .notSyncing, .error:
            return .orange
        case .unknown:
            return .gray
        }
    }
}

// MARK: - Bundle Extension

extension Bundle {
    var appVersion: String {
        let version = infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

#Preview {
    SettingsView()
}
