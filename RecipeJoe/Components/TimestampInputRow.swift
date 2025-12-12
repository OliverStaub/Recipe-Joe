//
//  TimestampInputRow.swift
//  RecipeJoe
//
//  Timestamp input component for video recipe import
//

import SwiftUI

/// Input section for video timestamp selection
struct TimestampInputSection: View {
    @Binding var startTimestamp: String
    @Binding var endTimestamp: String
    let platformName: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "film")
                    .foregroundStyle(Color("AccentColor"))
                Text(platformName != nil
                    ? String(localized: "\(platformName!) Video")
                    : String(localized: "Video"))
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            Text("Select a time range to extract a specific recipe, or leave empty to use the full video.")
                .font(.caption)
                .foregroundStyle(.secondary)

            // Timestamp inputs
            HStack(spacing: 16) {
                TimestampField(
                    label: String(localized: "Start"),
                    placeholder: "0:00",
                    value: $startTimestamp
                )

                TimestampField(
                    label: String(localized: "End"),
                    placeholder: String(localized: "End of video"),
                    value: $endTimestamp
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

/// Individual timestamp input field
struct TimestampField: View {
    let label: String
    let placeholder: String
    @Binding var value: String

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)

            TextField(placeholder, text: $value)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.numbersAndPunctuation)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .focused($isFocused)
                .onChange(of: value) { _, newValue in
                    // Auto-format: add colon after entering 2+ digits without colon
                    formatTimestamp(newValue)
                }
        }
    }

    private func formatTimestamp(_ newValue: String) {
        // Only auto-format if user is typing (not deleting)
        guard newValue.count > value.count else { return }

        // Remove any non-digit/colon characters
        let cleaned = newValue.filter { $0.isNumber || $0 == ":" }

        // Auto-insert colon after 2 digits if no colon present
        if cleaned.count == 2 && !cleaned.contains(":") {
            value = cleaned + ":"
        } else if cleaned != newValue {
            value = cleaned
        }
    }
}

#Preview {
    VStack {
        TimestampInputSection(
            startTimestamp: .constant(""),
            endTimestamp: .constant(""),
            platformName: "YouTube"
        )
        .padding()

        TimestampInputSection(
            startTimestamp: .constant("1:30"),
            endTimestamp: .constant("5:45"),
            platformName: "TikTok"
        )
        .padding()
    }
}
