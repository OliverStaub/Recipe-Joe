//
//  URLInputRow.swift
//  RecipeJoe
//
//  URL input field with action button
//

import SwiftUI

struct URLInputRow: View {
    @Binding var urlText: String
    @FocusState.Binding var isTextFieldFocused: Bool
    let isLoading: Bool
    let onImport: () -> Void
    var onSelectPhoto: (() -> Void)?
    var onTakePhoto: (() -> Void)?
    var onSelectPDF: (() -> Void)?

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

            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(0.8)
                    .frame(width: 36, height: 36)
                    .foregroundStyle(Color.terracotta)
                    .padding(6)
            } else if hasURL {
                Button(action: onImport) {
                    Image(systemName: "arrow.forward.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(Color.terracotta)
                        .padding(6)
                }
                .accessibilityIdentifier("actionButton")
            } else {
                Menu {
                    Button(action: { onSelectPhoto?() }) {
                        Label(String(localized: "Photo Library"), systemImage: "photo.on.rectangle")
                    }
                    .accessibilityIdentifier("photoLibraryButton")

                    Button(action: { onTakePhoto?() }) {
                        Label(String(localized: "Take Photo"), systemImage: "camera")
                    }
                    .accessibilityIdentifier("takePhotoButton")

                    Button(action: { onSelectPDF?() }) {
                        Label(String(localized: "Import PDF"), systemImage: "doc.fill")
                    }
                    .accessibilityIdentifier("importPDFButton")
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(Color.terracotta)
                        .padding(6)
                }
                .accessibilityIdentifier("actionButton")
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: hasURL)
    }
}
