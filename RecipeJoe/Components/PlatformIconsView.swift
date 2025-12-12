//
//  PlatformIconsView.swift
//  RecipeJoe
//
//  Supported platform icons display
//

import SwiftUI

struct PlatformIconsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Supports:")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                PlatformIcon(
                    iconName: "play.rectangle.fill",
                    iconColor: .red,
                    platformName: "YouTube"
                )

                PlatformIcon(
                    iconName: "camera.fill",
                    iconColor: .purple,
                    platformName: "Reels"
                )

                PlatformIcon(
                    iconName: "music.note",
                    iconColor: .primary,
                    platformName: "TikTok"
                )

                PlatformIcon(
                    iconName: "safari",
                    iconColor: Color.terracotta,
                    platformName: "Recipes"
                )
            }
            .accessibilityIdentifier("platformIcons")
        }
    }
}

// MARK: - Platform Icon

struct PlatformIcon: View {
    let iconName: String
    let iconColor: Color
    let platformName: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .font(.caption)
                .foregroundStyle(iconColor)
            Text(platformName)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(platformName) supported")
    }
}
