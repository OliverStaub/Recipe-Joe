//
//  TokenPurchaseView.swift
//  RecipeJoe
//
//  View for purchasing token packages
//

import StoreKit
import SwiftUI

struct TokenPurchaseView: View {
    @ObservedObject private var tokenService = TokenService.shared
    @ObservedObject private var storeKit = StoreKitManager.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale

    @State private var selectedProduct: Product?
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
                await loadProducts()
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

            if storeKit.products.isEmpty {
                if storeKit.purchaseInProgress {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                } else {
                    // Show message when products aren't available
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
                                await loadProducts()
                            }
                        }
                        .buttonStyle(.bordered)
                        .tint(Color.terracotta)
                        .padding(.top, 8)
                    }
                    .padding(.vertical, 40)
                    .frame(maxWidth: .infinity)
                }
            } else {
                ForEach(storeKit.products, id: \.id) { product in
                    ProductRow(
                        product: product,
                        isSelected: selectedProduct?.id == product.id,
                        isPurchasing: isPurchasing
                    ) {
                        selectedProduct = product
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

    // MARK: - Actions

    private func loadProducts() async {
        await storeKit.loadProducts()
    }

    private func purchaseSelected() async {
        guard let product = selectedProduct else { return }

        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let success = try await storeKit.purchase(product)
            if success {
                // Refresh balance to get updated token count
                try? await tokenService.refreshBalance()
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Supporting Views

private struct ProductRow: View {
    let product: Product
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

                    Text(product.displayPrice)
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
        let id = product.id
        if id.contains("120") { return "120 Tokens" }
        if id.contains("50") { return "50 Tokens" }
        if id.contains("25") { return "25 Tokens" }
        if id.contains("10") { return "10 Tokens" }
        return product.displayName
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
