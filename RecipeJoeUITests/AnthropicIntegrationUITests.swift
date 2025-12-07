//
//  AnthropicIntegrationUITests.swift
//  RecipeJoeUITests
//
//  Created by Oliver Staub on 05.12.2025.
//

import XCTest

final class AnthropicIntegrationUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testAnthropicTestButtonExists() throws {
        let app = XCUIApplication()
        app.launch()

        // Navigate to Add Recipe tab
        app.tabBars.buttons["Add Recipe"].tap()

        // Verify test button exists
        let testButton = app.buttons["testAnthropicButton"]
        XCTAssertTrue(testButton.waitForExistence(timeout: 5),
                      "Test Anthropic button should exist")
    }

    @MainActor
    func testAnthropicTestButtonIsEnabled() throws {
        let app = XCUIApplication()
        app.launch()

        // Navigate to Add Recipe tab
        app.tabBars.buttons["Add Recipe"].tap()

        // Verify test button is enabled
        let testButton = app.buttons["testAnthropicButton"]
        XCTAssertTrue(testButton.waitForExistence(timeout: 5))
        XCTAssertTrue(testButton.isEnabled, "Test Anthropic button should be enabled")
    }

    @MainActor
    func testAnthropicTestButtonHasCorrectLabel() throws {
        let app = XCUIApplication()
        app.launch()

        // Navigate to Add Recipe tab
        app.tabBars.buttons["Add Recipe"].tap()

        // Verify button has correct label
        let testButton = app.buttons["testAnthropicButton"]
        XCTAssertTrue(testButton.waitForExistence(timeout: 5))

        // Check that the button contains expected text
        let buttonLabel = testButton.label
        XCTAssertTrue(buttonLabel.contains("Anthropic") || buttonLabel.contains("Test"),
                      "Button should have appropriate label")
    }
}
