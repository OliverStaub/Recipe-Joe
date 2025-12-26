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

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Step number
            Text("\(step.stepNumber)")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(isHighlighted ? Color.primary : .secondary)
                .frame(width: 24, alignment: .leading)

            // Instruction
            VStack(alignment: .leading, spacing: 6) {
                Text(step.instruction)
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
