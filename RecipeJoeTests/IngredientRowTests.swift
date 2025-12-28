//
//  IngredientRowTests.swift
//  RecipeJoeTests
//
//  Tests for ingredient row formatting (Mela style)
//

import Testing
import Foundation
@testable import RecipeJoe

@Suite("Ingredient Row Formatting Tests")
struct IngredientRowTests {

    // MARK: - Quantity Formatting Tests

    /// Format quantity like Mela (no space for short units)
    private func formatQuantity(quantity: Double?, abbreviation: String?) -> String? {
        var result = ""

        if let qty = quantity {
            if qty == qty.rounded() {
                result = String(format: "%.0f", qty)
            } else {
                result = String(format: "%.1f", qty)
            }
        }

        if let abbr = abbreviation {
            // Add space only for longer units like "Stück" but not for "g", "ml", "EL"
            if abbr.count > 2 {
                result += " " + abbr
            } else {
                result += abbr
            }
        }

        return result.isEmpty ? nil : result
    }

    @Test("Formats grams without space")
    func testGramsNoSpace() {
        let result = formatQuantity(quantity: 375, abbreviation: "g")
        #expect(result == "375g")
    }

    @Test("Formats milliliters without space")
    func testMillilitersNoSpace() {
        let result = formatQuantity(quantity: 400, abbreviation: "ml")
        #expect(result == "400ml")
    }

    @Test("Formats tablespoons without space")
    func testTablespoonsNoSpace() {
        let result = formatQuantity(quantity: 4, abbreviation: "EL")
        #expect(result == "4EL")
    }

    @Test("Formats teaspoons without space")
    func testTeaspoonsNoSpace() {
        let result = formatQuantity(quantity: 2, abbreviation: "TL")
        #expect(result == "2TL")
    }

    @Test("Formats liters without space")
    func testLitersNoSpace() {
        let result = formatQuantity(quantity: 1, abbreviation: "l")
        #expect(result == "1l")
    }

    @Test("Formats pieces with space")
    func testPiecesWithSpace() {
        let result = formatQuantity(quantity: 2, abbreviation: "Stück")
        #expect(result == "2 Stück")
    }

    @Test("Formats Zehe with space")
    func testZeheWithSpace() {
        let result = formatQuantity(quantity: 3, abbreviation: "Zehe")
        #expect(result == "3 Zehe")
    }

    @Test("Formats decimal quantities")
    func testDecimalQuantity() {
        let result = formatQuantity(quantity: 1.5, abbreviation: "kg")
        #expect(result == "1.5kg")
    }

    @Test("Formats whole numbers without decimal")
    func testWholeNumber() {
        let result = formatQuantity(quantity: 2.0, abbreviation: "St")
        #expect(result == "2St")
    }

    @Test("Returns nil for no quantity")
    func testNoQuantity() {
        let result = formatQuantity(quantity: nil, abbreviation: nil)
        #expect(result == nil)
    }

    @Test("Returns just quantity when no unit")
    func testQuantityOnly() {
        let result = formatQuantity(quantity: 5, abbreviation: nil)
        #expect(result == "5")
    }

    @Test("Returns just unit when no quantity")
    func testUnitOnly() {
        let result = formatQuantity(quantity: nil, abbreviation: "EL")
        #expect(result == "EL")
    }

    // MARK: - Ingredient Text Formatting Tests

    private func formatIngredientText(name: String, notes: String?) -> String {
        var text = name
        if let notes = notes, !notes.isEmpty {
            text += ", " + notes
        }
        return text
    }

    @Test("Formats name without notes")
    func testNameOnly() {
        let result = formatIngredientText(name: "Butter", notes: nil)
        #expect(result == "Butter")
    }

    @Test("Formats name with notes")
    func testNameWithNotes() {
        let result = formatIngredientText(name: "Teigwaren", notes: "z.B. Makkaroni")
        #expect(result == "Teigwaren, z.B. Makkaroni")
    }

    @Test("Ignores empty notes")
    func testEmptyNotes() {
        let result = formatIngredientText(name: "Salz", notes: "")
        #expect(result == "Salz")
    }

    @Test("Formats with preparation notes")
    func testPreparationNotes() {
        let result = formatIngredientText(name: "Peterli", notes: "fein gehackt")
        #expect(result == "Peterli, fein gehackt")
    }

    // MARK: - Combined Examples (Mela style)

    @Test("Complete Mela-style formatting")
    func testMelaStyleExamples() {
        // Test cases matching Mela screenshot
        let testCases: [(Double?, String?, String, String?, String)] = [
            (1, "l", "Milch", nil, "1l Milch"),
            (4, "EL", "Butter", nil, "4EL Butter"),
            (nil, nil, "Salz", nil, "Salz"),
            (nil, nil, "Pfeffer", nil, "Pfeffer"),
            (375, "g", "Teigwaren", "z.B. Makkaroni", "375g Teigwaren, z.B. Makkaroni"),
            (200, "g", "Gruyère AOP", "gerieben", "200g Gruyère AOP, gerieben"),
            (5, nil, "Paniermehl", "- 6EL", "5 Paniermehl, - 6EL"),
        ]

        for (qty, unit, name, notes, expected) in testCases {
            let qtyStr = formatQuantity(quantity: qty, abbreviation: unit)
            let ingredientText = formatIngredientText(name: name, notes: notes)
            let combined = [qtyStr, ingredientText].compactMap { $0 }.joined(separator: " ")
            #expect(combined == expected, "Expected '\(expected)' but got '\(combined)'")
        }
    }
}
