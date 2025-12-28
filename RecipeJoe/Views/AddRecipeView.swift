//
//  AddRecipeView.swift
//  RecipeJoe
//
//  Created by Oliver Staub on 23.11.2025.
//

import PhotosUI
import SwiftUI

struct AddRecipeView: View {
    @State private var urlText: String = ""
    @FocusState private var isTextFieldFocused: Bool
    @StateObject private var importViewModel = RecipeImportViewModel()
    @Environment(\.locale) private var locale

    // Photo picker state
    @State private var showPhotoPicker = false
    @State private var selectedPhotoItems: [PhotosPickerItem] = []

    // Camera state
    @State private var showCamera = false
    @State private var capturedImage: UIImage?

    // Document picker state
    @State private var showDocumentPicker = false

    // Token purchase state
    @State private var showPurchaseSheet = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                // Title with Token Balance
                HStack {
                    Text("New Recipe")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .accessibilityIdentifier("newRecipeTitle")

                    Spacer()

                    TokenBalanceView()
                }
                .padding(.horizontal, 40)
                .padding(.top, 8)

                // URL Input Section
                VStack(alignment: .leading, spacing: 12) {
                    URLInputRow(
                        urlText: $urlText,
                        isTextFieldFocused: $isTextFieldFocused,
                        isLoading: importViewModel.importState.isLoading,
                        onImport: importRecipe,
                        onSelectPhoto: { showPhotoPicker = true },
                        onTakePhoto: { showCamera = true },
                        onSelectPDF: { showDocumentPicker = true }
                    )
                    .padding(.horizontal, 24)

                    PlatformIconsView()
                        .padding(.leading, 40)

                    // Video Timestamp Section (only shown for video URLs)
                    if importViewModel.isVideoURL(urlText) {
                        TimestampInputSection(
                            startTimestamp: $importViewModel.startTimestamp,
                            endTimestamp: $importViewModel.endTimestamp,
                            platformName: importViewModel.videoPlatformName(urlText)
                        )
                        .padding(.horizontal, 24)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    // Import Status Section (when not importing)
                    if !importViewModel.importState.isActiveImport {
                        ImportStatusSection(viewModel: importViewModel)
                            .padding(.horizontal, 24)
                            .padding(.top, 8)
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: importViewModel.isVideoURL(urlText))

                // Import Status Section - centered when importing/success
                if importViewModel.importState.isActiveImport {
                    ImportStatusSection(viewModel: importViewModel)
                        .padding(.horizontal, 24)
                }

                Spacer()
            }
            .navigationBarHidden(true)
            .contentShape(Rectangle())
            .onTapGesture {
                isTextFieldFocused = false
            }
            // Photo picker (up to 3 images)
            .photosPicker(
                isPresented: $showPhotoPicker,
                selection: $selectedPhotoItems,
                maxSelectionCount: 3,
                matching: .images
            )
            .onChange(of: selectedPhotoItems) { _, newItems in
                handlePhotoSelection(newItems)
            }
            // Camera
            .fullScreenCover(isPresented: $showCamera) {
                CameraView(capturedImage: $capturedImage)
            }
            .onChange(of: capturedImage) { _, newImage in
                handleCameraCapture(newImage)
            }
            // Document picker
            .sheet(isPresented: $showDocumentPicker) {
                DocumentPickerView { pdfData in
                    handlePDFSelection(pdfData)
                }
            }
            // Token purchase sheet (triggered by insufficient tokens)
            .sheet(isPresented: $showPurchaseSheet) {
                TokenPurchaseView()
            }
            // Insufficient tokens alert
            .alert(
                "Not Enough Tokens".localized(for: locale),
                isPresented: $importViewModel.showInsufficientTokensAlert
            ) {
                Button("Cancel".localized(for: locale), role: .cancel) {}
                Button("Get Tokens".localized(for: locale)) {
                    showPurchaseSheet = true
                }
            } message: {
                Text("You need %lld tokens to import this recipe. Tap 'Get Tokens' to purchase more.".localizedWithFormat(for: locale, importViewModel.requiredTokens))
            }
        }
    }

    // MARK: - URL Import

    private func importRecipe() {
        guard !urlText.isEmpty else { return }
        isTextFieldFocused = false
        Task {
            await importViewModel.importRecipe(from: urlText)
        }
    }

    // MARK: - Photo Import

    private func handlePhotoSelection(_ items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }

        Task {
            var compressedImages: [Data] = []

            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data),
                   let compressedData = compressImage(image) {
                    compressedImages.append(compressedData)
                }
            }

            if !compressedImages.isEmpty {
                await importViewModel.importRecipeFromImages(compressedImages)
            }

            // Reset selection
            selectedPhotoItems = []
        }
    }

    private func handleCameraCapture(_ image: UIImage?) {
        guard let image = image else { return }

        Task {
            if let compressedData = compressImage(image) {
                await importViewModel.importRecipeFromImage(compressedData)
            }
            // Reset captured image
            capturedImage = nil
        }
    }

    private func compressImage(_ image: UIImage, maxSizeMB: Int = 4) -> Data? {
        let maxBytes = maxSizeMB * 1024 * 1024
        var quality: CGFloat = 0.8

        while quality > 0.1 {
            if let data = image.jpegData(compressionQuality: quality) {
                if data.count <= maxBytes {
                    return data
                }
            }
            quality -= 0.1
        }

        // Last resort: return with lowest quality
        return image.jpegData(compressionQuality: 0.1)
    }

    // MARK: - PDF Import

    private func handlePDFSelection(_ pdfData: Data) {
        Task {
            await importViewModel.importRecipeFromPDF(pdfData)
        }
    }
}

#Preview {
    AddRecipeView()
}
