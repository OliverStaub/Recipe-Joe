//
//  TokenBalanceView.swift
//  RecipeJoe
//
//  Compact token balance display component
//

import SwiftUI

/// Compact pill showing token balance, tappable to open purchase sheet
struct TokenBalanceView: View {
    @ObservedObject private var tokenService = TokenService.shared
    @State private var showPurchaseSheet = false

    var body: some View {
        Button {
            showPurchaseSheet = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "circle.fill")
                    .font(.system(size: 8))
                    .foregroundStyle(Color.terracotta)

                Text("\(tokenService.tokenBalance)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.terracotta)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(.secondarySystemBackground))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("tokenBalanceButton")
        .sheet(isPresented: $showPurchaseSheet) {
            TokenPurchaseView()
        }
    }
}

/// Inline token cost badge for import buttons
struct TokenCostBadge: View {
    let cost: Int

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "circle.fill")
                .font(.system(size: 6))
            Text("\(cost)")
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundStyle(Color.terracotta)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.terracotta.opacity(0.15))
        .clipShape(Capsule())
    }
}

/// Alert-style view shown when user doesn't have enough tokens
struct InsufficientTokensView: View {
    @Environment(\.locale) private var locale
    let requiredTokens: Int
    let availableTokens: Int
    let onGetTokens: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 48))
                .foregroundStyle(Color.terracotta)

            Text("Not Enough Tokens".localized(for: locale))
                .font(.headline)

            Text("You need %lld tokens but only have %lld.".localizedWithFormat(for: locale, requiredTokens, availableTokens))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 12) {
                Button {
                    onCancel()
                } label: {
                    Text("Cancel".localized(for: locale))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    onGetTokens()
                } label: {
                    Text("Get Tokens".localized(for: locale))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.terracotta)
            }
        }
        .padding(24)
    }
}

#Preview("Token Balance") {
    TokenBalanceView()
}

#Preview("Token Cost Badge") {
    HStack {
        TokenCostBadge(cost: 1)
        TokenCostBadge(cost: 2)
        TokenCostBadge(cost: 3)
    }
}

#Preview("Insufficient Tokens") {
    InsufficientTokensView(
        requiredTokens: 3,
        availableTokens: 1,
        onGetTokens: {},
        onCancel: {}
    )
}
