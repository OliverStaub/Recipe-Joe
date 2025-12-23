//
//  RecipeDetailView.swift
//  RecipeJoe
//
//  Full recipe detail view with ingredients and steps
//

import Combine
import Kingfisher
import PhotosUI
import SwiftUI
import UIKit

struct RecipeDetailView: View {
    let recipeId: UUID

    @StateObject private var viewModel = RecipeDetailViewModel()
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isUploadingImage = false
    @State private var uploadError: String?
    @State private var showPhotoPicker = false
    @Environment(\.locale) private var locale

    // Time picker state
    @State private var showPrepTimePicker = false
    @State private var showCookTimePicker = false
    @State private var showTotalTimePicker = false
    @State private var editTimeMinutes = 0

    // Category/Cuisine edit state
    @State private var showCategoryEdit = false
    @State private var showCuisineEdit = false
    @State private var editCategory = ""
    @State private var editCuisine = ""

    var body: some View {
        ZStack {
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

            // Saving overlay
            if viewModel.isSaving {
                savingOverlay
            }
        }
        .navigationTitle(viewModel.recipeDetail?.recipe.name ?? "Recipe")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.fetchRecipeDetail(id: recipeId)
        }
    }

    // MARK: - Saving Overlay

    private var savingOverlay: some View {
        Color.black.opacity(0.3)
            .ignoresSafeArea()
            .overlay {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(.white)
                    Text("Saving...")
                        .font(.subheadline)
                        .foregroundStyle(.white)
                }
                .padding(24)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
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
            // Image with Kingfisher caching
            if let imageUrl = recipe.imageUrl,
               let url = URL(string: imageUrl) {
                KFImage(url)
                    .placeholder { ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity) }
                    .onFailure { _ in }
                    .loadDiskFileSynchronously()
                    .cacheMemoryOnly(false)
                    .fade(duration: 0.25)
                    .resizable()
                    .scaledToFill()
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

            // Upload error overlay
            if let error = uploadError {
                VStack {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(Color.red)
                        .clipShape(Capsule())
                        .padding(.top, 8)
                    Spacer()
                }
            }
        }
        .frame(height: 220)
        .frame(maxWidth: .infinity)
        .background(Color.terracotta.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .contentShape(Rectangle())
        .onLongPressGesture {
            guard !isUploadingImage else { return }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            showPhotoPicker = true
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhotoItem, matching: .images)
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
            // Editable Title
            EditableTextField(
                value: recipe.name,
                placeholder: "Recipe Title",
                title: "Recipe Title",
                onSave: { newValue in
                    Task { await viewModel.saveName(newValue) }
                },
                textStyle: .title,
                textWeight: .bold
            )

            // Author (read-only)
            if let author = recipe.author, !author.isEmpty {
                Text("by \(author)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Editable Description
            EditableTextField(
                value: recipe.description ?? "",
                placeholder: "Add description...",
                title: "Description",
                onSave: { newValue in
                    Task { await viewModel.saveDescription(newValue) }
                },
                textColor: .secondary,
                multiline: true
            )

            // Time badges
            HStack(spacing: 16) {
                if let prepTime = recipe.prepTimeMinutes, prepTime > 0 {
                    TimeBadge(label: "Prep", minutes: prepTime) {
                        editTimeMinutes = prepTime
                        showPrepTimePicker = true
                    }
                }
                if let cookTime = recipe.cookTimeMinutes, cookTime > 0 {
                    TimeBadge(label: "Cook", minutes: cookTime) {
                        editTimeMinutes = cookTime
                        showCookTimePicker = true
                    }
                }
                if let totalTime = recipe.totalTimeMinutes, totalTime > 0 {
                    TimeBadge(label: "Total", minutes: totalTime) {
                        editTimeMinutes = totalTime
                        showTotalTimePicker = true
                    }
                }
            }

            // Category & Cuisine
            HStack(spacing: 12) {
                if let category = recipe.category, !category.isEmpty {
                    CategoryBadge(text: category, icon: "tag.fill") {
                        editCategory = category
                        showCategoryEdit = true
                    }
                }
                if let cuisine = recipe.cuisine, !cuisine.isEmpty {
                    CategoryBadge(text: cuisine, icon: "globe") {
                        editCuisine = cuisine
                        showCuisineEdit = true
                    }
                }
            }

            // Editable Yield
            if let recipeYield = recipe.recipeYield, !recipeYield.isEmpty {
                HStack {
                    Image(systemName: "person.2.fill")
                    EditableTextField(
                        value: recipeYield,
                        placeholder: "Servings",
                        title: "Servings",
                        onSave: { newValue in
                            Task { await viewModel.saveYield(newValue) }
                        },
                        textStyle: .subheadline,
                        textColor: .secondary
                    )
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
        }
        // Time picker sheets
        .sheet(isPresented: $showPrepTimePicker) {
            TimePickerSheet(
                title: "Prep",
                minutes: $editTimeMinutes,
                onSave: {
                    showPrepTimePicker = false
                    Task { await viewModel.savePrepTime(editTimeMinutes) }
                },
                onCancel: { showPrepTimePicker = false }
            )
            .presentationDetents([.height(300)])
        }
        .sheet(isPresented: $showCookTimePicker) {
            TimePickerSheet(
                title: "Cook",
                minutes: $editTimeMinutes,
                onSave: {
                    showCookTimePicker = false
                    Task { await viewModel.saveCookTime(editTimeMinutes) }
                },
                onCancel: { showCookTimePicker = false }
            )
            .presentationDetents([.height(300)])
        }
        .sheet(isPresented: $showTotalTimePicker) {
            TimePickerSheet(
                title: "Total",
                minutes: $editTimeMinutes,
                onSave: {
                    showTotalTimePicker = false
                    Task { await viewModel.saveTotalTime(editTimeMinutes) }
                },
                onCancel: { showTotalTimePicker = false }
            )
            .presentationDetents([.height(300)])
        }
        // Category/Cuisine edit sheets
        .sheet(isPresented: $showCategoryEdit) {
            TextEditSheet(
                title: "Category",
                value: $editCategory,
                onSave: {
                    showCategoryEdit = false
                    Task { await viewModel.saveCategory(editCategory) }
                },
                onCancel: { showCategoryEdit = false }
            )
            .presentationDetents([.height(200)])
        }
        .sheet(isPresented: $showCuisineEdit) {
            TextEditSheet(
                title: "Cuisine",
                value: $editCuisine,
                onSave: {
                    showCuisineEdit = false
                    Task { await viewModel.saveCuisine(editCuisine) }
                },
                onCancel: { showCuisineEdit = false }
            )
            .presentationDetents([.height(200)])
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
                    IngredientRow(ingredient: ingredient) { quantity, notes in
                        Task {
                            await viewModel.saveIngredient(
                                ingredientId: ingredient.id,
                                quantity: quantity,
                                notes: notes
                            )
                        }
                    }
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
                    StepRow(step: step) { instruction in
                        Task {
                            await viewModel.saveStepInstruction(
                                stepId: step.id,
                                instruction: instruction
                            )
                        }
                    }
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
