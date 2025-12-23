//
//  ShareExtensionView.swift
//  RecipeJoeShareExtension
//
//  SwiftUI view for the share extension UI.
//

import SwiftUI
import UIKit

/// Represents a file to be imported
struct SharedFile: Identifiable {
    let id = UUID()
    let data: Data
    let isPDF: Bool
    let thumbnail: UIImage?
}

/// View state for the share extension
enum ShareExtensionState {
    case ready
    case notAuthenticated
    case importing(step: String)
    case success(recipeName: String?)
    case error(message: String)
}

struct ShareExtensionView: View {
    let files: [SharedFile]
    let onComplete: () -> Void

    @State private var state: ShareExtensionState = .ready

    /// Terracotta accent color
    private let terracotta = Color(red: 198/255, green: 93/255, blue: 0/255)

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                switch state {
                case .ready:
                    readyView

                case .notAuthenticated:
                    notAuthenticatedView

                case .importing(let step):
                    importingView(step: step)

                case .success(let recipeName):
                    successView(recipeName: recipeName)

                case .error(let message):
                    errorView(message: message)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
            .navigationTitle("RecipeJoe")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            checkAuthentication()
        }
    }

    // MARK: - State Views

    private var readyView: some View {
        VStack(spacing: 20) {
            // File preview
            filePreview

            // Import button
            Button(action: startImport) {
                HStack {
                    Image(systemName: "arrow.down.doc")
                    Text("Import to RecipeJoe")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(terracotta)
                .cornerRadius(12)
            }

            Spacer()
        }
    }

    private var notAuthenticatedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("Sign in Required")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Please open RecipeJoe and sign in first to import recipes.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(.top, 40)
    }

    private func importingView(step: String) -> some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .padding()

            Text(step)
                .font(.headline)
                .foregroundColor(.primary)

            Text("You can close this - the recipe will appear in RecipeJoe shortly.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(.top, 40)
    }

    private func successView(recipeName: String?) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)

            Text("Import Started!")
                .font(.title2)
                .fontWeight(.semibold)

            if let name = recipeName {
                Text(name)
                    .font(.headline)
                    .foregroundColor(.secondary)
            }

            Text("Your recipe will appear in RecipeJoe in about a minute.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(.top, 40)
        .onAppear {
            // Auto-close after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                onComplete()
            }
        }
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)

            Text("Import Failed")
                .font(.title2)
                .fontWeight(.semibold)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button(action: startImport) {
                Text("Try Again")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(terracotta)
                    .cornerRadius(12)
            }
            .padding(.top, 8)

            Spacer()
        }
        .padding(.top, 40)
    }

    // MARK: - File Preview

    private var filePreview: some View {
        VStack(spacing: 12) {
            if files.count == 1, let file = files.first {
                // Single file preview
                singleFilePreview(file: file)
            } else {
                // Multiple files
                multipleFilesPreview
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private func singleFilePreview(file: SharedFile) -> some View {
        HStack(spacing: 16) {
            // Thumbnail or icon
            Group {
                if let thumbnail = file.thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .cornerRadius(8)
                        .clipped()
                } else {
                    Image(systemName: file.isPDF ? "doc.fill" : "photo.fill")
                        .font(.system(size: 30))
                        .foregroundColor(terracotta)
                        .frame(width: 60, height: 60)
                        .background(Color(.tertiarySystemBackground))
                        .cornerRadius(8)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(file.isPDF ? "PDF Document" : "Image")
                    .font(.headline)

                Text(formatFileSize(file.data.count))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }

    private var multipleFilesPreview: some View {
        HStack(spacing: 16) {
            // Stack of thumbnails
            ZStack {
                ForEach(Array(files.prefix(3).enumerated()), id: \.offset) { index, file in
                    Group {
                        if let thumbnail = file.thumbnail {
                            Image(uiImage: thumbnail)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
                            Image(systemName: "photo.fill")
                                .font(.system(size: 20))
                                .foregroundColor(terracotta)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color(.tertiarySystemBackground))
                        }
                    }
                    .frame(width: 50, height: 50)
                    .cornerRadius(6)
                    .clipped()
                    .offset(x: CGFloat(index * 8), y: CGFloat(index * -4))
                }
            }
            .frame(width: 70, height: 60)

            VStack(alignment: .leading, spacing: 4) {
                Text("\(files.count) Images")
                    .font(.headline)

                let totalSize = files.reduce(0) { $0 + $1.data.count }
                Text(formatFileSize(totalSize))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }

    // MARK: - Actions

    private func checkAuthentication() {
        if !ExtensionSupabaseClient.shared.isAuthenticated {
            state = .notAuthenticated
        }
    }

    private func startImport() {
        let mediaType = files.first?.isPDF == true ? "pdf" : "image"
        state = .importing(step: "Uploading...")

        Task {
            do {
                // Update UI for analysis step after brief delay
                try await Task.sleep(nanoseconds: 500_000_000)
                await MainActor.run {
                    state = .importing(step: "AI is analyzing your recipe...")
                }

                let fileData = files.map { $0.data }
                let result = try await ExtensionSupabaseClient.shared.importRecipe(
                    files: fileData,
                    mediaType: mediaType
                )

                await MainActor.run {
                    if result.success {
                        state = .success(recipeName: result.recipeName)
                    } else {
                        state = .error(message: result.error ?? "Unknown error")
                    }
                }
            } catch {
                await MainActor.run {
                    state = .error(message: error.localizedDescription)
                }
            }
        }
    }

    // MARK: - Helpers

    private func formatFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}
