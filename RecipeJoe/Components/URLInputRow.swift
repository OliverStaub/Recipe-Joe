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
