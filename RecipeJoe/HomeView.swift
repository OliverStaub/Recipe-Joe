//
//  HomeView.swift
//  RecipeJoe
//
//  Created by Oliver Staub on 23.11.2025.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "house.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.terracotta)

                Text("Home")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Recipe home screen coming soon")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("RecipeJoe")
        }
    }
}

#Preview {
    HomeView()
}
