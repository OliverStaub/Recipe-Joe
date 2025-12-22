//
//  StepRow.swift
//  RecipeJoe
//
//  Reusable step row component with category parsing
//

import SwiftUI

struct StepRow: View {
    let step: SupabaseRecipeStep
    var onSave: ((String) -> Void)?
    @Environment(\.locale) private var locale

    @State private var showEditSheet = false
    @State private var editInstruction: String = ""

    private var parsedStep: (category: StepCategory, instruction: String) {
        StepCategory.parse(step.instruction)
    }

    var body: some View {
        let parsed = parsedStep

        HStack(alignment: .top, spacing: 12) {
            // Category icon
            Image(systemName: parsed.category.icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(parsed.category.color)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            // Instruction
            VStack(alignment: .leading, spacing: 6) {
                // Category badge
                Text(parsed.category.displayName(locale: locale))
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(parsed.category.color)
                    .textCase(.uppercase)

                // Instruction text
                Text(parsed.instruction)
                    .font(.body)

                if let duration = step.durationMinutes, duration > 0 {
                    Label("\(duration) min", systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)
        }
        .padding()
        .background(parsed.category.color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(parsed.category.color.opacity(0.2), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onLongPressGesture {
            if onSave != nil {
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

                Text("Tip: Start with a category prefix like \"prep:\", \"cook:\", \"mix:\" for automatic categorization")
                    .font(.caption)
                    .foregroundStyle(.secondary)

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

// MARK: - Step Category

enum StepCategory: String, CaseIterable {
    case prep
    case heat
    case cook
    case mix
    case assemble
    case bake
    case rest
    case finish
    case unknown

    func displayName(locale: Locale) -> String {
        let key: String
        switch self {
        case .prep: key = "Prep"
        case .heat: key = "Heat"
        case .cook: key = "Cook"
        case .mix: key = "Mix"
        case .assemble: key = "Assemble"
        case .bake: key = "Bake"
        case .rest: key = "Rest"
        case .finish: key = "Finish"
        case .unknown: key = "Step"
        }
        return key.localized(for: locale)
    }

    // Keep a default for backward compatibility
    var displayName: String {
        displayName(locale: .current)
    }

    var icon: String {
        switch self {
        case .prep: return "knife"
        case .heat: return "flame"
        case .cook: return "frying.pan"
        case .mix: return "arrow.triangle.2.circlepath"
        case .assemble: return "square.stack.3d.up"
        case .bake: return "oven"
        case .rest: return "clock"
        case .finish: return "sparkles"
        case .unknown: return "list.number"
        }
    }

    var color: Color {
        switch self {
        case .prep: return .blue
        case .heat: return .orange
        case .cook: return Color.terracotta
        case .mix: return .purple
        case .assemble: return .indigo
        case .bake: return .red
        case .rest: return .teal
        case .finish: return .green
        case .unknown: return .gray
        }
    }

    static func parse(_ instruction: String) -> (category: StepCategory, instruction: String) {
        // Try to match "category: instruction" format
        let lowercased = instruction.lowercased()

        for category in StepCategory.allCases where category != .unknown {
            let prefix = "\(category.rawValue):"
            if lowercased.hasPrefix(prefix) {
                let startIndex = instruction.index(instruction.startIndex, offsetBy: prefix.count)
                let cleanInstruction = String(instruction[startIndex...]).trimmingCharacters(in: .whitespaces)
                return (category, cleanInstruction)
            }
        }

        // No category found, return as-is
        return (.unknown, instruction)
    }
}
