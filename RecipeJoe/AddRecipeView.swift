//
//  AddRecipeView.swift
//  RecipeJoe
//
//  Created by Oliver Staub on 23.11.2025.
//

import SwiftUI

struct AddRecipeView: View {
    @State private var urlText: String = ""
    @FocusState private var isTextFieldFocused: Bool
    @StateObject private var importViewModel = RecipeImportViewModel()

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                // Title
                Text("New Recipe")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.leading, 40)
                    .padding(.top, 8)
                    .accessibilityIdentifier("newRecipeTitle")

                // URL Input Section
                VStack(alignment: .leading, spacing: 12) {
                    URLInputRow(
                        urlText: $urlText,
                        isTextFieldFocused: $isTextFieldFocused,
                        isLoading: importViewModel.importState.isLoading,
                        onImport: importRecipe
                    )
                    .padding(.horizontal, 24)

                    PlatformIconsView()
                        .padding(.leading, 40)

                    // Import Status Section
                    ImportStatusSection(viewModel: importViewModel)
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                }

                Spacer()
            }
            .navigationBarHidden(true)
            .contentShape(Rectangle())
            .onTapGesture {
                isTextFieldFocused = false
            }
        }
    }

    private func importRecipe() {
        guard !urlText.isEmpty else { return }
        isTextFieldFocused = false
        Task {
            await importViewModel.importRecipe(from: urlText)
        }
    }
}

// MARK: - URL Input Row

private struct URLInputRow: View {
    @Binding var urlText: String
    @FocusState.Binding var isTextFieldFocused: Bool
    let isLoading: Bool
    let onImport: () -> Void

    private var hasURL: Bool {
        !urlText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        HStack(spacing: 8) {
            TextField("Paste recipe URL...", text: $urlText)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .clipShape(Capsule())
                .focused($isTextFieldFocused)
                .autocapitalization(.none)
                .autocorrectionDisabled()
                .keyboardType(.URL)
                .submitLabel(.go)
                .onSubmit {
                    if hasURL {
                        onImport()
                    }
                }
                .accessibilityIdentifier("urlTextField")

            Button(action: {
                if hasURL {
                    onImport()
                }
                // TODO: Plus button for file picker when no URL
            }) {
                Group {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(0.8)
                            .frame(width: 36, height: 36)
                    } else {
                        Image(systemName: hasURL ? "arrow.forward.circle.fill" : "plus.circle.fill")
                            .font(.system(size: 36))
                    }
                }
                .foregroundStyle(Color.terracotta)
                .contentTransition(.symbolEffect(.replace))
                .padding(6)
            }
            .disabled(isLoading || !hasURL)
            .accessibilityIdentifier("actionButton")
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: hasURL)
        }
    }
}

// MARK: - Platform Icons View

private struct PlatformIconsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Supports:")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                PlatformIcon(
                    iconName: "play.rectangle.fill",
                    iconColor: .red,
                    platformName: "YouTube"
                )

                PlatformIcon(
                    iconName: "music.note",
                    iconColor: .primary,
                    platformName: "TikTok"
                )

                PlatformIcon(
                    iconName: "safari",
                    iconColor: Color.terracotta,
                    platformName: "Recipe sites"
                )
            }
            .accessibilityIdentifier("platformIcons")
        }
    }
}

// MARK: - Platform Icon

private struct PlatformIcon: View {
    let iconName: String
    let iconColor: Color
    let platformName: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .font(.caption)
                .foregroundStyle(iconColor)
            Text(platformName)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(platformName) supported")
    }
}

// MARK: - Import Status Section

private struct ImportStatusSection: View {
    @ObservedObject var viewModel: RecipeImportViewModel

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
                        Text("Recipe imported!")
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
                            StatBadge(value: stats.stepsCount, label: "steps")
                            StatBadge(value: stats.ingredientsCount, label: "ingredients")
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
                        Text("Import failed")
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

// MARK: - Import Progress View

private struct ImportProgressView: View {
    let currentStep: RecipeImportViewModel.ImportStep
    @State private var shimmerOffset: CGFloat = -1

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Step indicator text
            Text(currentStep.title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(Color.terracotta)

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

            // Step dots
            HStack(spacing: 0) {
                ForEach(RecipeImportViewModel.ImportStep.allCases, id: \.rawValue) { step in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(step.rawValue <= currentStep.rawValue ? Color.terracotta : Color(.systemGray4))
                            .frame(width: 8, height: 8)

                        if step != RecipeImportViewModel.ImportStep.allCases.last {
                            Rectangle()
                                .fill(step.rawValue < currentStep.rawValue ? Color.terracotta : Color(.systemGray4))
                                .frame(height: 2)
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
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

// MARK: - Stat Badge

private struct StatBadge: View {
    let value: Int
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Text("\(value)")
                .fontWeight(.medium)
            Text(label)
        }
    }
}

#Preview {
    AddRecipeView()
}
