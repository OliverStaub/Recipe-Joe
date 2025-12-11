//
//  RecipeFilter.swift
//  RecipeJoe
//
//  Filter models for recipe filtering on HomeView
//

import Foundation
import SwiftUI

// MARK: - Time Filter

enum TimeFilter: String, CaseIterable, Identifiable {
    case all
    case quick      // < 30 min
    case medium     // 30-60 min
    case long       // > 60 min

    var id: String { rawValue }

    var icon: String? {
        switch self {
        case .all: return nil
        case .quick: return "clock"
        case .medium: return "clock"
        case .long: return "clock"
        }
    }

    func displayName(for locale: Locale) -> String {
        switch self {
        case .all: return "All".localized(for: locale)
        case .quick: return "Quick".localized(for: locale)
        case .medium: return "Medium".localized(for: locale)
        case .long: return "Long".localized(for: locale)
        }
    }

    func matches(totalMinutes: Int?) -> Bool {
        guard let minutes = totalMinutes else {
            return self == .all
        }
        switch self {
        case .all: return true
        case .quick: return minutes < 30
        case .medium: return minutes >= 30 && minutes <= 60
        case .long: return minutes > 60
        }
    }
}

// MARK: - Recipe Filters State

struct RecipeFilters {
    var timeFilter: TimeFilter = .all
    var selectedCategory: String? = nil
    var selectedCuisine: String? = nil
    var showFavoritesOnly: Bool = false

    var hasActiveFilters: Bool {
        timeFilter != .all || selectedCategory != nil || selectedCuisine != nil || showFavoritesOnly
    }

    mutating func reset() {
        timeFilter = .all
        selectedCategory = nil
        selectedCuisine = nil
        showFavoritesOnly = false
    }
}
