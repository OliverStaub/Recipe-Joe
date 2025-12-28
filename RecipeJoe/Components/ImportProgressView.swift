//
//  ImportProgressView.swift
//  RecipeJoe
//
//  Progress view for recipe import
//

import SwiftUI

struct ImportProgressView: View {
    let currentStep: RecipeImportViewModel.ImportStep
    @State private var rotation: Double = 0
    @Environment(\.locale) private var locale

    /// Returns localized step title
    private var stepTitle: String {
        switch currentStep {
        case .fetching: return "Fetching recipe...".localized(for: locale)
        case .fetchingTranscript: return "Fetching transcript...".localized(for: locale)
        case .uploading: return "Uploading file...".localized(for: locale)
        case .recognizing: return "Reading text...".localized(for: locale)
        case .parsing: return "Analyzing with AI...".localized(for: locale)
        case .extracting: return "Extracting ingredients...".localized(for: locale)
        case .saving: return "Saving recipe...".localized(for: locale)
        }
    }

    /// Show hint after upload is complete (during AI processing phases)
    private var showNoWaitHint: Bool {
        switch currentStep {
        case .recognizing, .parsing, .extracting:
            return true
        default:
            return false
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            // Spinning logo
            Image(systemName: "fork.knife.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color.terracotta)
                .rotationEffect(.degrees(rotation))

            // Step indicator text
            Text(stepTitle)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(Color.terracotta)

            // Hint that user doesn't need to wait
            if showNoWaitHint {
                Text("You can leave this screen - your recipe will appear when ready.".localized(for: locale))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .animation(.easeInOut(duration: 0.3), value: showNoWaitHint)
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

// MARK: - Import Status Section

struct ImportStatusSection: View {
    @ObservedObject var viewModel: RecipeImportViewModel
    @Environment(\.locale) private var locale

    /// Whether the current state should expand to fill available space
    private var shouldExpand: Bool {
        switch viewModel.importState {
        case .importing, .success:
            return true
        default:
            return false
        }
    }

    var body: some View {
        Group {
            switch viewModel.importState {
            case .idle:
                EmptyView()

            case .importing:
                ImportProgressView(currentStep: viewModel.currentStep)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .accessibilityIdentifier("importingIndicator")

            case .success:
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.green)

                    Text("Recipe imported!".localized(for: locale))
                        .font(.title2)
                        .fontWeight(.semibold)

                    if let recipeName = viewModel.lastImportedRecipeName {
                        Text(recipeName)
                            .font(.headline)
                            .foregroundStyle(.secondary)
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
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(24)
                .transition(.opacity)
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
