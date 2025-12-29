//
//  IngredientRow.swift
//  RecipeJoe
//
//  Reusable ingredient row component
//

import SwiftUI

struct IngredientRow: View {
    let ingredient: SupabaseRecipeIngredient
    var onSave: ((Double?, String?) -> Void)?
    @Environment(\.locale) private var locale

    @State private var showEditSheet = false
    @State private var editQuantity: String = ""
    @State private var editNotes: String = ""

    /// Check if current locale is German-based
    private var isGerman: Bool {
        let langCode = locale.language.languageCode?.identifier ?? "en"
        return langCode == "de" || langCode == "gsw"
    }

    /// Returns localized ingredient name based on app's locale setting
    private var ingredientName: String {
        guard let ing = ingredient.ingredient else {
            return "Unknown".localized(for: locale)
        }
        return isGerman ? ing.nameDe : ing.nameEn
    }

    /// Returns formatted quantity with localized measurement unit (no space like Mela: "1l", "4EL", "375g")
    private var formattedQuantity: String? {
        var result = ""

        if let qty = ingredient.quantity {
            if qty == qty.rounded() {
                result = String(format: "%.0f", qty)
            } else {
                result = String(format: "%.1f", qty)
            }
        }

        if let measurement = ingredient.measurementType {
            let abbr = isGerman ? measurement.abbreviationDe : measurement.abbreviationEn
            // Add space only for longer units like "Stück" but not for "g", "ml", "EL"
            if abbr.count > 2 {
                result += " " + abbr
            } else {
                result += abbr
            }
        }

        return result.isEmpty ? nil : result
    }

    private var measurementAbbreviation: String? {
        guard let measurement = ingredient.measurementType else { return nil }
        return isGerman ? measurement.abbreviationDe : measurement.abbreviationEn
    }

    /// Combined ingredient text with notes inline (Mela style)
    private var ingredientText: String {
        var text = ingredientName
        if let notes = ingredient.notes, !notes.isEmpty {
            text += ", " + notes
        }
        return text
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            // Quantity (bold, fixed width)
            if let qty = formattedQuantity {
                Text(qty)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(width: 70, alignment: .leading)
            } else {
                // Empty space for alignment when no quantity
                Color.clear
                    .frame(width: 70)
            }

            // Ingredient name with notes inline
            Text(ingredientText)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onLongPressGesture {
            if onSave != nil {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                editQuantity = ingredient.quantity.map { String($0) } ?? ""
                editNotes = ingredient.notes ?? ""
                showEditSheet = true
            }
        }
        .sheet(isPresented: $showEditSheet) {
            IngredientEditSheet(
                ingredientName: ingredientName,
                quantity: $editQuantity,
                notes: $editNotes,
                measurementAbbreviation: measurementAbbreviation,
                onSave: {
                    let qty = Double(editQuantity)
                    let notes = editNotes.isEmpty ? nil : editNotes
                    onSave?(qty, notes)
                    showEditSheet = false
                },
                onCancel: {
                    showEditSheet = false
                }
            )
            .presentationDetents([.height(280)])
        }
    }
}

// MARK: - Ingredient Edit Sheet

struct IngredientEditSheet: View {
    let ingredientName: String
    @Binding var quantity: String
    @Binding var notes: String
    let measurementAbbreviation: String?
    let onSave: () -> Void
    let onCancel: () -> Void

    @FocusState private var focusedField: Field?
    enum Field { case quantity, notes }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(ingredientName)) {
                    HStack {
                        TextField("Quantity", text: $quantity)
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .quantity)

                        if let abbr = measurementAbbreviation {
                            Text(abbr)
                                .foregroundStyle(.secondary)
                        }
                    }

                    TextField("Notes (optional)", text: $notes)
                        .focused($focusedField, equals: .notes)
                }
            }
            .onAppear { focusedField = .quantity }
            .navigationTitle("Edit Ingredient")
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
