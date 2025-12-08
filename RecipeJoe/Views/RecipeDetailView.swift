//
//  RecipeDetailView.swift
//  RecipeJoe
//
//  Full recipe detail view with ingredients and steps
//

import Combine
import PhotosUI
import SwiftUI
import UIKit

struct RecipeDetailView: View {
    let recipeId: UUID

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = RecipeDetailViewModel()
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isUploadingImage = false
    @State private var uploadError: String?
    @State private var showingDeleteConfirmation = false
    @State private var isDeleting = false

    var body: some View {
        ScrollView {
            if viewModel.isLoading {
                ProgressView("Loading recipe...")
                    .padding(.top, 100)
            } else if let detail = viewModel.recipeDetail {
                recipeContent(detail: detail)
            } else if let error = viewModel.error {
                errorView(error: error)
            }
        }
        .navigationTitle(viewModel.recipeDetail?.recipe.name ?? "Recipe")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete Recipe", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .disabled(isDeleting)
            }
        }
        .confirmationDialog(
            "Delete Recipe",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                Task {
                    await deleteRecipe()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this recipe? This action cannot be undone.")
        }
        .task {
            await viewModel.fetchRecipeDetail(id: recipeId)
        }
    }

    private func deleteRecipe() async {
        isDeleting = true
        do {
            try await SupabaseService.shared.deleteRecipe(id: recipeId)
            dismiss()
        } catch {
            viewModel.error = "Failed to delete: \(error.localizedDescription)"
        }
        isDeleting = false
    }

    // MARK: - Recipe Content

    @ViewBuilder
    private func recipeContent(detail: SupabaseRecipeDetail) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header Image
            headerImageSection(recipe: detail.recipe)

            // Recipe Info
            recipeInfoSection(recipe: detail.recipe)

            // Source Link
            if let sourceUrl = detail.recipe.sourceUrl, !sourceUrl.isEmpty {
                sourceLinkSection(urlString: sourceUrl)
            }

            // Ingredients
            if !detail.sortedIngredients.isEmpty {
                ingredientsSection(ingredients: detail.sortedIngredients)
            }

            // Steps
            if !detail.sortedSteps.isEmpty {
                stepsSection(steps: detail.sortedSteps)
            }
        }
        .padding()
    }

    // MARK: - Header Image

    @ViewBuilder
    private func headerImageSection(recipe: SupabaseRecipe) -> some View {
        ZStack {
            // Image placeholder or actual image
            if let imageUrl = recipe.imageUrl,
               let url = URL(string: imageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        placeholderContent
                    case .empty:
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    @unknown default:
                        placeholderContent
                    }
                }
            } else {
                placeholderContent
            }

            // Upload progress overlay
            if isUploadingImage {
                Color.black.opacity(0.5)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay {
                        VStack(spacing: 8) {
                            ProgressView()
                                .tint(.white)
                            Text("Uploading...")
                                .font(.caption)
                                .foregroundStyle(.white)
                        }
                    }
            }

            // Add Image Button
            VStack {
                if let error = uploadError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(Color.red)
                        .clipShape(Capsule())
                        .padding(.top, 8)
                }
                Spacer()
                HStack {
                    Spacer()
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        Label(
                            recipe.imageUrl != nil ? "Change Photo" : "Add Photo",
                            systemImage: "camera.fill"
                        )
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.terracotta)
                        .clipShape(Capsule())
                    }
                    .disabled(isUploadingImage)
                    .padding(12)
                }
            }
        }
        .frame(height: 220)
        .frame(maxWidth: .infinity)
        .background(Color.terracotta.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                await handleImageSelection(newItem)
            }
        }
    }

    private var placeholderContent: some View {
        VStack(spacing: 8) {
            Image(systemName: "fork.knife")
                .font(.system(size: 48))
                .foregroundStyle(Color.terracotta)
            Text("No image")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func handleImageSelection(_ item: PhotosPickerItem?) async {
        guard let item = item else { return }

        isUploadingImage = true
        uploadError = nil

        do {
            // Load image data
            guard let data = try await item.loadTransferable(type: Data.self) else {
                throw SupabaseError.unknownError
            }

            // Compress image if needed (max 1MB)
            let compressedData = compressImage(data: data, maxSizeKB: 1024)

            // Upload to Supabase
            _ = try await SupabaseService.shared.uploadRecipeImage(
                imageData: compressedData,
                recipeId: recipeId
            )

            // Refresh recipe detail to show new image
            await viewModel.fetchRecipeDetail(id: recipeId)

        } catch {
            uploadError = "Upload failed: \(error.localizedDescription)"
        }

        isUploadingImage = false
        selectedPhotoItem = nil
    }

    private func compressImage(data: Data, maxSizeKB: Int) -> Data {
        guard let image = UIImage(data: data) else { return data }

        let maxBytes = maxSizeKB * 1024
        var compression: CGFloat = 0.8

        // Try to compress to target size
        while compression > 0.1 {
            if let compressed = image.jpegData(compressionQuality: compression),
               compressed.count <= maxBytes {
                return compressed
            }
            compression -= 0.1
        }

        // Return lowest compression if still too big
        return image.jpegData(compressionQuality: 0.1) ?? data
    }

    // MARK: - Recipe Info

    @ViewBuilder
    private func recipeInfoSection(recipe: SupabaseRecipe) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title
            Text(recipe.name)
                .font(.title)
                .fontWeight(.bold)

            // Author
            if let author = recipe.author, !author.isEmpty {
                Text("by \(author)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Description
            if let description = recipe.description, !description.isEmpty {
                Text(description)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            // Time badges
            HStack(spacing: 16) {
                if let prepTime = recipe.prepTimeMinutes, prepTime > 0 {
                    TimeBadge(label: "Prep", minutes: prepTime)
                }
                if let cookTime = recipe.cookTimeMinutes, cookTime > 0 {
                    TimeBadge(label: "Cook", minutes: cookTime)
                }
                if let totalTime = recipe.totalTimeMinutes, totalTime > 0 {
                    TimeBadge(label: "Total", minutes: totalTime)
                }
            }

            // Category & Cuisine
            HStack(spacing: 12) {
                if let category = recipe.category, !category.isEmpty {
                    CategoryBadge(text: category, icon: "tag.fill")
                }
                if let cuisine = recipe.cuisine, !cuisine.isEmpty {
                    CategoryBadge(text: cuisine, icon: "globe")
                }
            }

            // Yield
            if let recipeYield = recipe.recipeYield, !recipeYield.isEmpty {
                Label(recipeYield, systemImage: "person.2.fill")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Source Link

    @ViewBuilder
    private func sourceLinkSection(urlString: String) -> some View {
        if let url = URL(string: urlString) {
            Link(destination: url) {
                HStack {
                    Image(systemName: "link")
                    Text("View Original Recipe")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                }
                .font(.subheadline)
                .foregroundStyle(Color.terracotta)
                .padding()
                .background(Color.terracotta.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Ingredients

    @ViewBuilder
    private func ingredientsSection(ingredients: [SupabaseRecipeIngredient]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Ingredients", icon: "basket.fill")

            VStack(alignment: .leading, spacing: 8) {
                ForEach(ingredients) { ingredient in
                    IngredientRow(ingredient: ingredient)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Steps

    @ViewBuilder
    private func stepsSection(steps: [SupabaseRecipeStep]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Instructions", icon: "list.number")

            VStack(alignment: .leading, spacing: 16) {
                ForEach(steps) { step in
                    StepRow(step: step)
                }
            }
        }
    }

    // MARK: - Error View

    @ViewBuilder
    private func errorView(error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.red)
            Text("Error loading recipe")
                .font(.headline)
            Text(error)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Retry") {
                Task {
                    await viewModel.fetchRecipeDetail(id: recipeId)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.terracotta)
        }
        .padding()
    }
}

// MARK: - Supporting Views

private struct TimeBadge: View {
    let label: String
    let minutes: Int

    var body: some View {
        VStack(spacing: 2) {
            Text(formattedTime)
                .font(.subheadline)
                .fontWeight(.semibold)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var formattedTime: String {
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            if mins == 0 {
                return "\(hours)h"
            }
            return "\(hours)h \(mins)m"
        }
        return "\(minutes)m"
    }
}

private struct CategoryBadge: View {
    let text: String
    let icon: String

    var body: some View {
        Label(text, systemImage: icon)
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.terracotta.opacity(0.15))
            .foregroundStyle(Color.terracotta)
            .clipShape(Capsule())
    }
}

private struct SectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        Label(title, systemImage: icon)
            .font(.title2)
            .fontWeight(.bold)
    }
}

private struct IngredientRow: View {
    let ingredient: SupabaseRecipeIngredient

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Quantity
            Text(ingredient.formattedQuantity)
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(width: 60, alignment: .leading)

            // Ingredient name
            VStack(alignment: .leading, spacing: 2) {
                Text(ingredient.ingredient?.localizedName ?? "Unknown")
                    .font(.subheadline)

                if let notes = ingredient.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
    }
}

private struct StepRow: View {
    let step: SupabaseRecipeStep

    private var parsedStep: (category: StepCategory, instruction: String) {
        StepCategory.parse(step.instruction)
    }

    var body: some View {
        let parsed = parsedStep

        HStack(alignment: .top, spacing: 12) {
            // Category icon
            Image(systemName: parsed.category.icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(parsed.category.color)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            // Instruction
            VStack(alignment: .leading, spacing: 6) {
                // Category badge
                Text(parsed.category.displayName)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(parsed.category.color)
                    .textCase(.uppercase)

                // Instruction text
                Text(parsed.instruction)
                    .font(.body)

                if let duration = step.durationMinutes, duration > 0 {
                    Label("\(duration) min", systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)
        }
        .padding()
        .background(parsed.category.color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(parsed.category.color.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Step Category

private enum StepCategory: String, CaseIterable {
    case prep
    case heat
    case cook
    case mix
    case assemble
    case bake
    case rest
    case finish
    case unknown

    var displayName: String {
        switch self {
        case .prep: return String(localized: "Prep")
        case .heat: return String(localized: "Heat")
        case .cook: return String(localized: "Cook")
        case .mix: return String(localized: "Mix")
        case .assemble: return String(localized: "Assemble")
        case .bake: return String(localized: "Bake")
        case .rest: return String(localized: "Rest")
        case .finish: return String(localized: "Finish")
        case .unknown: return String(localized: "Step")
        }
    }

    var icon: String {
        switch self {
        case .prep: return "knife"
        case .heat: return "flame"
        case .cook: return "frying.pan"
        case .mix: return "arrow.triangle.2.circlepath"
        case .assemble: return "square.stack.3d.up"
        case .bake: return "oven"
        case .rest: return "clock"
        case .finish: return "sparkles"
        case .unknown: return "list.number"
        }
    }

    var color: Color {
        switch self {
        case .prep: return .blue
        case .heat: return .orange
        case .cook: return Color.terracotta
        case .mix: return .purple
        case .assemble: return .indigo
        case .bake: return .red
        case .rest: return .teal
        case .finish: return .green
        case .unknown: return .gray
        }
    }

    static func parse(_ instruction: String) -> (category: StepCategory, instruction: String) {
        // Try to match "category: instruction" format
        let lowercased = instruction.lowercased()

        for category in StepCategory.allCases where category != .unknown {
            let prefix = "\(category.rawValue):"
            if lowercased.hasPrefix(prefix) {
                let startIndex = instruction.index(instruction.startIndex, offsetBy: prefix.count)
                let cleanInstruction = String(instruction[startIndex...]).trimmingCharacters(in: .whitespaces)
                return (category, cleanInstruction)
            }
        }

        // No category found, return as-is
        return (.unknown, instruction)
    }
}

// MARK: - ViewModel

@MainActor
final class RecipeDetailViewModel: ObservableObject {
    @Published var recipeDetail: SupabaseRecipeDetail?
    @Published var isLoading: Bool = false
    @Published var error: String?

    func fetchRecipeDetail(id: UUID) async {
        isLoading = true
        error = nil

        do {
            recipeDetail = try await SupabaseService.shared.fetchRecipeDetail(id: id)
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}
