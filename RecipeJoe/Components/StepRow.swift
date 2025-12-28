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

    /// Step type prefix mappings to emoji and color
    private static let prefixMappings: [(prefix: String, emoji: String, color: Color)] = [
        ("prep: ", "🔪", Color.blue.opacity(0.15)),
        ("heat: ", "🔥", Color.orange.opacity(0.15)),
        ("cook: ", "🍳", Color.yellow.opacity(0.15)),
        ("mix: ", "🥄", Color.purple.opacity(0.15)),
        ("assemble: ", "🍽️", Color.green.opacity(0.15)),
        ("bake: ", "♨️", Color.red.opacity(0.15)),
        ("rest: ", "⏸️", Color.gray.opacity(0.15)),
        ("finish: ", "✨", Color.pink.opacity(0.15))
    ]

    /// Returns the emoji and background color if instruction has a known prefix
    private var stepTypeInfo: (emoji: String, color: Color)? {
        let instruction = step.instruction.lowercased()
        for mapping in Self.prefixMappings {
            if instruction.hasPrefix(mapping.prefix) {
                return (mapping.emoji, mapping.color)
            }
        }
        return nil
    }

    /// Returns the instruction text without the prefix
    private var instructionText: String {
        let instruction = step.instruction
        for mapping in Self.prefixMappings {
            if instruction.lowercased().hasPrefix(mapping.prefix) {
                return String(instruction.dropFirst(mapping.prefix.count))
            }
        }
        return instruction
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Step number
            Text("\(step.stepNumber)")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(isHighlighted ? Color.primary : .secondary)
                .frame(width: 24, alignment: .leading)

            // Step type emoji badge (if applicable)
            if let typeInfo = stepTypeInfo {
                Text(typeInfo.emoji)
                    .font(.system(size: 16))
                    .frame(width: 28, height: 28)
                    .background(isHighlighted ? Color.terracotta.opacity(0.15) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }

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
