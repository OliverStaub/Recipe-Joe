//
//  ImportProgressView.swift
//  RecipeJoe
//
//  Progress view for recipe import
//

import SwiftUI

struct ImportProgressView: View {
    let currentStep: RecipeImportViewModel.ImportStep
    @State private var shimmerOffset: CGFloat = -1
    @Environment(\.locale) private var locale

    /// Returns localized step title
    private var stepTitle: String {
        switch currentStep {
        case .fetching: return "Fetching recipe...".localized(for: locale)
        case .fetchingTranscript: return "Fetching transcript...".localized(for: locale)
        case .parsing: return "Analyzing with AI...".localized(for: locale)
        case .extracting: return "Extracting ingredients...".localized(for: locale)
        case .saving: return "Saving recipe...".localized(for: locale)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Progress bar with shimmer
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.systemGray5))

                    // Progress fill
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.terracotta)
                        .frame(width: geometry.size.width * currentStep.progress)
                        .animation(.easeInOut(duration: 0.4), value: currentStep)

                    // Shimmer overlay
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [
                                    .clear,
                                    .white.opacity(0.4),
                                    .clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 60)
                        .offset(x: shimmerOffset * geometry.size.width)
                        .mask(
                            RoundedRectangle(cornerRadius: 6)
                                .frame(width: geometry.size.width * currentStep.progress)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        )
                }
            }
            .frame(height: 12)

            // Step indicator text
            Text(stepTitle)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(Color.terracotta)
        }
        .padding(16)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onAppear {
            withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                shimmerOffset = 1.5
            }
        }
    }
}

// MARK: - Import Status Section

struct ImportStatusSection: View {
    @ObservedObject var viewModel: RecipeImportViewModel
    @Environment(\.locale) private var locale

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            switch viewModel.importState {
            case .idle:
                EmptyView()

            case .importing:
                ImportProgressView(currentStep: viewModel.currentStep)
                    .accessibilityIdentifier("importingIndicator")

            case .success:
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Recipe imported!".localized(for: locale))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }

                    if let recipeName = viewModel.lastImportedRecipeName {
                        Text(recipeName)
                            .font(.headline)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    if let stats = viewModel.lastImportStats {
                        HStack(spacing: 16) {
                            StatBadge(value: stats.stepsCount, label: "steps".localized(for: locale))
                            StatBadge(value: stats.ingredientsCount, label: "ingredients".localized(for: locale))
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
                .accessibilityIdentifier("importSuccess")

            case .error(let message):
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                        Text("Import failed".localized(for: locale))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                .accessibilityIdentifier("importError")
            }
        }
    }
}
