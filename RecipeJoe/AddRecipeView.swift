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
                        isTextFieldFocused: $isTextFieldFocused
                    )
                    .padding(.horizontal, 24)

                    PlatformIconsView()
                        .padding(.leading, 40)
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
}

// MARK: - URL Input Row

private struct URLInputRow: View {
    @Binding var urlText: String
    @FocusState.Binding var isTextFieldFocused: Bool

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
                .accessibilityIdentifier("urlTextField")

            Button(action: {
                // No functionality yet - UI only
                if hasURL {
                    // Future: trigger URL request
                    print("Send/Go action - URL: \(urlText)")
                } else {
                    // Future: open file picker
                    print("Plus action - open file picker")
                }
            }) {
                Image(systemName: hasURL ? "arrow.forward.circle.fill" : "plus.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(Color.terracotta)
                    .contentTransition(.symbolEffect(.replace))
                    .padding(6)
            }
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

#Preview {
    AddRecipeView()
}
