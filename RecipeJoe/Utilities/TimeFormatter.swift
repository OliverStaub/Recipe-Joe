//
//  TimeFormatter.swift
//  RecipeJoe
//
//  Utility for formatting time durations
//

import Foundation

/// Format minutes into a readable time string
/// - Parameter minutes: The number of minutes
/// - Returns: A formatted string like "1h 30m" or "45 min"
func formatTime(_ minutes: Int) -> String {
    if minutes >= 60 {
        let hours = minutes / 60
        let mins = minutes % 60
        if mins == 0 {
            return "\(hours)h"
        }
        return "\(hours)h \(mins)m"
    }
    return "\(minutes) min"
}
