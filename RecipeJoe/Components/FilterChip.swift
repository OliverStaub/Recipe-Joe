//
//  FilterChip.swift
//  RecipeJoe
//
//  Reusable filter chip component for recipe filtering
//

import SwiftUI

struct FilterChip: View {
    let title: String
    let icon: String?
    let isSelected: Bool
    let action: () -> Void

    init(title: String, icon: String? = nil, isSelected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(title)
            }
            .font(.subheadline)
            .fontWeight(isSelected ? .semibold : .regular)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? Color.terracotta : Color(.systemGray5))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Filter Bar

struct FilterBar: View {
    @Environment(\.locale) private var locale
    @Binding var filters: RecipeFilters
    let availableCategories: [String]
    let availableCuisines: [String]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Time filters
                timeFilterSection

                // Divider if there are more filters
                if !availableCategories.isEmpty || !availableCuisines.isEmpty {
                    Divider()
                        .frame(height: 20)
                }

                // Category filters
                categoryFilterSection

                // Cuisine filters
                cuisineFilterSection

                // Favorites filter
                favoritesFilterSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .accessibilityIdentifier("filterBar")
    }

    // MARK: - Time Filter Section

    private var timeFilterSection: some View {
        ForEach(TimeFilter.allCases) { timeFilter in
            FilterChip(
                title: timeFilter.displayName(for: locale),
                icon: timeFilter.icon,
                isSelected: filters.timeFilter == timeFilter
            ) {
                filters.timeFilter = timeFilter
            }
        }
    }

    // MARK: - Category Filter Section

    @ViewBuilder
    private var categoryFilterSection: some View {
        if !availableCategories.isEmpty {
            Menu {
                Button("All".localized(for: locale)) {
                    filters.selectedCategory = nil
                }
                ForEach(availableCategories, id: \.self) { category in
                    Button(category) {
                        filters.selectedCategory = category
                    }
                }
            } label: {
                FilterChip(
                    title: filters.selectedCategory ?? "Category".localized(for: locale),
                    isSelected: filters.selectedCategory != nil
                ) {}
            }
        }
    }

    // MARK: - Cuisine Filter Section

    @ViewBuilder
    private var cuisineFilterSection: some View {
        if !availableCuisines.isEmpty {
            Menu {
                Button("All".localized(for: locale)) {
                    filters.selectedCuisine = nil
                }
                ForEach(availableCuisines, id: \.self) { cuisine in
                    Button(cuisine) {
                        filters.selectedCuisine = cuisine
                    }
                }
            } label: {
                FilterChip(
                    title: filters.selectedCuisine ?? "Cuisine".localized(for: locale),
                    isSelected: filters.selectedCuisine != nil
                ) {}
            }
        }
    }

    // MARK: - Favorites Filter Section

    private var favoritesFilterSection: some View {
        FilterChip(
            title: "Favorites".localized(for: locale),
            icon: "heart.fill",
            isSelected: filters.showFavoritesOnly
        ) {
            filters.showFavoritesOnly.toggle()
        }
    }
}
