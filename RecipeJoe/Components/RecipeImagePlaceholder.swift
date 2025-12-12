//
//  RecipeImagePlaceholder.swift
//  RecipeJoe
//
//  Placeholder view for recipe images
//

import SwiftUI

struct RecipeImagePlaceholder: View {
    var body: some View {
        Rectangle()
            .fill(Color.terracotta.opacity(0.15))
            .overlay {
                Image(systemName: "fork.knife")
                    .font(.title2)
                    .foregroundStyle(Color.terracotta)
            }
    }
}
