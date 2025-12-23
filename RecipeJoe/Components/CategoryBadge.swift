//
//  CategoryBadge.swift
//  RecipeJoe
//
//  Reusable category badge component
//

import SwiftUI

struct CategoryBadge: View {
    let text: String
    let icon: String
    var onTap: (() -> Void)?

    var body: some View {
        Label(text, systemImage: icon)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .background(Color.terracotta.opacity(0.15))
            .foregroundStyle(Color.terracotta)
            .clipShape(Capsule())
            .contentShape(Capsule())
            .onLongPressGesture {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onTap?()
            }
    }
}
