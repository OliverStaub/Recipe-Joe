//
//  TokenPurchaseView.swift
//  RecipeJoe
//
//  View for purchasing token packages
//

import RevenueCat
import SwiftUI

struct TokenPurchaseView: View {
    @ObservedObject private var tokenService = TokenService.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale

    @State private var selectedPackage: Package?
    @State private var isPurchasing = false
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Current balance header
                    balanceHeader

                    // Token packages
                    packagesSection

                    // Token pricing info
                    pricingInfo

                    // Restore purchases button
                    restoreButton
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Get Tokens".localized(for: locale))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close".localized(for: locale)) {
                        dismiss()
                    }
                }
            }
            .task {
                await fetchPackages()
            }
            .alert("Purchase Error".localized(for: locale), isPresented: $showError) {
                Button("OK".localized(for: locale), role: .cancel) {}
            } message: {
                Text(errorMessage ?? "An error occurred")
            }
        }
    }

    // MARK: - Subviews

    private var balanceHeader: some View {
        VStack(spacing: 8) {
            Text("\(tokenService.tokenBalance)")
                .font(.system(size: 56, weight: .bold))
                .foregroundStyle(Color.terracotta)

            Text("tokens available".localized(for: locale))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var packagesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Token Packages".localized(for: locale))
                .font(.headline)
                .padding(.horizontal, 4)

            if tokenService.isLoading && tokenService.availablePackages.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else if tokenService.availablePackages.isEmpty {
                // Show message when packages aren't available
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)

                    Text("Packages not available".localized(for: locale))
                        .font(.headline)

                    Text("Token packages are being configured. Please try again later.".localized(for: locale))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Button("Retry".localized(for: locale)) {
                        Task {
                            await fetchPackages()
                        }
                    }
                    .buttonStyle(.bordered)
                    .tint(Color.terracotta)
                    .padding(.top, 8)
                }
                .padding(.vertical, 40)
                .frame(maxWidth: .infinity)
            } else {
                ForEach(tokenService.availablePackages, id: \.identifier) { package in
                    PackageRow(
                        package: package,
                        isSelected: selectedPackage?.identifier == package.identifier,
                        isPurchasing: isPurchasing
                    ) {
                        selectedPackage = package
                        await purchaseSelected()
                    }
                }
            }
        }
    }

    private var pricingInfo: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Token Usage".localized(for: locale))
                .font(.headline)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                PricingRow(icon: "globe", text: "Website recipe".localized(for: locale), tokens: 1)
                Divider().padding(.leading, 40)
                PricingRow(icon: "video", text: "Video recipe".localized(for: locale), tokens: 2)
                Divider().padding(.leading, 40)
                PricingRow(icon: "doc.viewfinder", text: "Photo/PDF recipe".localized(for: locale), tokens: 3)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var restoreButton: some View {
        Button {
            Task {
                await restorePurchases()
            }
        } label: {
            Text("Restore Purchases".localized(for: locale))
                .font(.subheadline)
                .foregroundStyle(Color.terracotta)
        }
        .disabled(isPurchasing)
        .padding(.top, 8)
    }

    // MARK: - Actions

    private func fetchPackages() async {
        do {
            try await tokenService.fetchPackages()
        } catch {
            // Don't show error for package fetch - fallback UI is shown
            print("Failed to fetch packages: \(error)")
        }
    }

    private func purchaseSelected() async {
        guard let package = selectedPackage else { return }

        isPurchasing = true
        defer { isPurchasing = false }

        do {
            try await tokenService.purchasePackage(package)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func restorePurchases() async {
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            try await tokenService.restorePurchases()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Supporting Views

private struct PackageRow: View {
    let package: Package
    let isSelected: Bool
    let isPurchasing: Bool
    let onPurchase: () async -> Void

    var body: some View {
        Button {
            Task {
                await onPurchase()
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(tokenCountText)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(package.storeProduct.localizedPriceString)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isPurchasing && isSelected {
                    ProgressView()
                } else {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(isPurchasing)
        .buttonStyle(.plain)
    }

    private var tokenCountText: String {
        let id = package.storeProduct.productIdentifier
        if id.contains("120") { return "120 Tokens" }
        if id.contains("50") { return "50 Tokens" }
        if id.contains("25") { return "25 Tokens" }
        if id.contains("10") { return "10 Tokens" }
        return package.storeProduct.localizedTitle
    }
}

private struct PricingRow: View {
    let icon: String
    let text: String
    let tokens: Int

    var body: some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundStyle(Color.terracotta)

            Text(text)
                .foregroundStyle(.primary)

            Spacer()

            Text("\(tokens) token\(tokens > 1 ? "s" : "")")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    TokenPurchaseView()
}
