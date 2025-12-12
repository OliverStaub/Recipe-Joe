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

    @StateObject private var viewModel = RecipeDetailViewModel()
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isUploadingImage = false
    @State private var uploadError: String?
    @Environment(\.locale) private var locale

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
        .task {
            await viewModel.fetchRecipeDetail(id: recipeId)
        }
    }

    // MARK: - Recipe Content

    @ViewBuilder
    private func recipeContent(detail: SupabaseRecipeDetail) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header Image
            headerImageSection(recipe: detail.recipe)

            // Recipe Info
            recipeInfoSection(recipe: detail.recipe)
                .padding(.horizontal, 16)

            // Source Link
            if let sourceUrl = detail.recipe.sourceUrl, !sourceUrl.isEmpty {
                sourceLinkSection(urlString: sourceUrl)
                    .padding(.horizontal, 16)
            }

            // Ingredients
            if !detail.sortedIngredients.isEmpty {
                ingredientsSection(ingredients: detail.sortedIngredients)
                    .padding(.horizontal, 16)
            }

            // Steps
            if !detail.sortedSteps.isEmpty {
                stepsSection(steps: detail.sortedSteps)
                    .padding(.horizontal, 16)
            }
        }
        .padding(.vertical)
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
            SectionHeader(title: "Ingredients".localized(for: locale), icon: "basket.fill")

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
            SectionHeader(title: "Instructions".localized(for: locale), icon: "list.number")

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
