//
//  TimeBadge.swift
//  RecipeJoe
//
//  Reusable time badge component
//

import SwiftUI

struct TimeBadge: View {
    let label: String
    let minutes: Int
    var onTap: (() -> Void)?

    var body: some View {
        VStack(spacing: 2) {
            Text(formatTime(minutes))
                .font(.subheadline)
                .fontWeight(.semibold)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .contentShape(Rectangle())
        .onLongPressGesture {
            onTap?()
        }
    }
}
