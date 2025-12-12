//
//  StatBadge.swift
//  RecipeJoe
//
//  Simple stat badge component
//

import SwiftUI

struct StatBadge: View {
    let value: Int
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Text("\(value)")
                .fontWeight(.medium)
            Text(label)
        }
    }
}
