//
//  SectionHeader.swift
//  RecipeJoe
//
//  Reusable section header component
//

import SwiftUI

struct SectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        Label(title, systemImage: icon)
            .font(.title2)
            .fontWeight(.bold)
    }
}
