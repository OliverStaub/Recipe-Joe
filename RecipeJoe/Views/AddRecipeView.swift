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

#Preview {
    AddRecipeView()
}
