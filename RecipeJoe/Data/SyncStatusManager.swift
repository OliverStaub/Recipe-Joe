//
//  SyncStatusManager.swift
//  RecipeJoe
//
//  Created by Oliver Staub on 25.11.2025.
//

import Foundation
import CloudKit
import Observation

/// Manages and monitors CloudKit sync status
@Observable
@MainActor
final class SyncStatusManager {
    // MARK: - Properties

    /// Whether CloudKit is enabled in the app
    /// Must match DataController.cloudKitEnabled
    private static let cloudKitEnabled = false

    /// Current sync status
    private(set) var syncStatus: SyncStatus = .unknown

    /// Last sync date
    private(set) var lastSyncDate: Date?

    /// iCloud account status
    private(set) var accountStatus: CKAccountStatus = .couldNotDetermine

    /// Error message if any
    private(set) var errorMessage: String?

    // MARK: - Sync Status Enum

    enum SyncStatus: Equatable {
        case unknown
        case syncing
        case synced
        case notSyncing
        case error(String)

        var description: String {
            switch self {
            case .unknown:
                return "Checking..."
            case .syncing:
                return "Syncing..."
            case .synced:
                return "Up to date"
            case .notSyncing:
                return "Not syncing"
            case .error(let message):
                return "Error: \(message)"
            }
        }

        var systemImage: String {
            switch self {
            case .unknown:
                return "questionmark.circle"
            case .syncing:
                return "arrow.triangle.2.circlepath"
            case .synced:
                return "checkmark.icloud"
            case .notSyncing:
                return "xmark.icloud"
            case .error:
                return "exclamationmark.icloud"
            }
        }
    }

    // MARK: - Initialization

    init() {
        if Self.cloudKitEnabled {
            Task {
                await checkAccountStatus()
            }
            setupNotifications()
        } else {
            // CloudKit not configured yet
            self.syncStatus = .notSyncing
            self.errorMessage = "iCloud sync not configured"
        }
    }

    // MARK: - Public Methods

    /// Refresh the sync status
    func refresh() async {
        guard Self.cloudKitEnabled else {
            self.syncStatus = .notSyncing
            self.errorMessage = "iCloud sync not configured"
            return
        }
        await checkAccountStatus()
    }

    // MARK: - Private Methods

    private func checkAccountStatus() async {
        guard Self.cloudKitEnabled else {
            self.syncStatus = .notSyncing
            self.errorMessage = "iCloud sync not configured"
            return
        }

        do {
            let container = CKContainer(identifier: "iCloud.Oliver.RecipeJoe")
            let status = try await container.accountStatus()

            self.accountStatus = status

            switch status {
            case .available:
                self.syncStatus = .synced
                self.lastSyncDate = Date()
                self.errorMessage = nil
            case .noAccount:
                self.syncStatus = .notSyncing
                self.errorMessage = "No iCloud account signed in"
            case .restricted:
                self.syncStatus = .notSyncing
                self.errorMessage = "iCloud access is restricted"
            case .couldNotDetermine:
                self.syncStatus = .unknown
                self.errorMessage = "Could not determine iCloud status"
            case .temporarilyUnavailable:
                self.syncStatus = .notSyncing
                self.errorMessage = "iCloud temporarily unavailable"
            @unknown default:
                self.syncStatus = .unknown
                self.errorMessage = "Unknown iCloud status"
            }
        } catch {
            self.syncStatus = .error(error.localizedDescription)
            self.errorMessage = error.localizedDescription
        }
    }

    private func setupNotifications() {
        guard Self.cloudKitEnabled else { return }

        NotificationCenter.default.addObserver(
            forName: .CKAccountChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.checkAccountStatus()
            }
        }
    }
}
