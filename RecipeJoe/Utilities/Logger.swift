//
//  Logger.swift
//  RecipeJoe
//
//  App-wide logging utility using Apple's unified logging system.
//

import Foundation
import os.log

/// App-wide logger using Apple's unified logging system.
/// Debug/Info logs only appear in DEBUG builds.
/// Error logs appear in all builds (useful for crash diagnostics).
enum Log {
    private static let subsystem = "com.oliverstaub.recipejoe"

    static let auth = Logger(subsystem: subsystem, category: "auth")
    static let storeKit = Logger(subsystem: subsystem, category: "storekit")
    static let tokens = Logger(subsystem: subsystem, category: "tokens")
    static let general = Logger(subsystem: subsystem, category: "general")

    /// Debug-only logging (stripped from release builds)
    static func debug(_ message: String, category: Logger = Log.general) {
        #if DEBUG
        category.debug("\(message)")
        #endif
    }

    /// Error logging (available in DEBUG builds only)
    static func error(_ message: String, category: Logger = Log.general) {
        #if DEBUG
        category.error("\(message)")
        #endif
    }
}
