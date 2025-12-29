//
//  StepRow.swift
//  RecipeJoe
//
//  Simple step row component with highlighting for cooking progress
//

import SwiftUI

struct StepRow: View {
    let step: SupabaseRecipeStep
    let isHighlighted: Bool
    var onTap: (() -> Void)?
    var onSave: ((String) -> Void)?

    @State private var showEditSheet = false
    @State private var editInstruction: String = ""

    /// Returns the emoji at the start of the instruction (if any)
    private var leadingEmoji: String? {
        let instruction = step.instruction
        guard let firstChar = instruction.first else { return nil }

        // Check if first character is an emoji using a simple heuristic:
        // Emojis are typically outside the basic ASCII/Latin range and render as single grapheme clusters
        let firstString = String(firstChar)

        // Check if it's likely an emoji by seeing if it contains emoji scalars
        let hasEmoji = firstString.unicodeScalars.contains { scalar in
            scalar.properties.isEmoji && (
                scalar.properties.isEmojiPresentation ||
                scalar.value >= 0x1F300 // Most food/object emojis start here
            )
        }

        return hasEmoji ? firstString : nil
    }

    /// Returns the instruction text without the leading emoji
    private var instructionText: String {
        guard leadingEmoji != nil else { return step.instruction }

        // Drop the first character (the emoji) and trim whitespace
        return String(step.instruction.dropFirst()).trimmingCharacters(in: .whitespaces)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Step number
            Text("\(step.stepNumber)")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(isHighlighted ? Color.primary : .secondary)
                .frame(width: 24, alignment: .leading)

            // Step emoji badge (always reserve space for consistent alignment)
            Text(leadingEmoji ?? "")
                .font(.system(size: 16))
                .frame(width: 28, height: 28)
                .background(isHighlighted && leadingEmoji != nil ? Color.terracotta.opacity(0.15) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 6))

            // Instruction
            VStack(alignment: .leading, spacing: 6) {
                Text(instructionText)
                    .font(.body)
                    .fontWeight(isHighlighted ? .medium : .regular)
                    .foregroundStyle(isHighlighted ? Color.primary : .primary)

                if let duration = step.durationMinutes, duration > 0 {
                    Label("\(duration) min", systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onTap?()
        }
        .onLongPressGesture {
            if onSave != nil {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                editInstruction = step.instruction
                showEditSheet = true
            }
        }
        .sheet(isPresented: $showEditSheet) {
            StepEditSheet(
                stepNumber: step.stepNumber,
                instruction: $editInstruction,
                onSave: {
                    onSave?(editInstruction)
                    showEditSheet = false
                },
                onCancel: {
                    showEditSheet = false
                }
            )
            .presentationDetents([.medium])
        }
    }
}

// MARK: - Step Edit Sheet

struct StepEditSheet: View {
    let stepNumber: Int
    @Binding var instruction: String
    let onSave: () -> Void
    let onCancel: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                TextEditor(text: $instruction)
                    .focused($isFocused)
                    .frame(minHeight: 150)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                Spacer()
            }
            .padding()
            .onAppear { isFocused = true }
            .navigationTitle("Step \(stepNumber)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: onSave)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.terracotta)
                }
            }
        }
    }
}
