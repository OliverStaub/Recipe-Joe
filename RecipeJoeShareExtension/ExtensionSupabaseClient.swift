//
//  ExtensionSupabaseClient.swift
//  RecipeJoeShareExtension
//
//  Lightweight Supabase client for share extension.
//  Uses URLSession directly to minimize memory footprint.
//

import Foundation

/// Result of a recipe import operation
struct ImportResult {
    let success: Bool
    let recipeName: String?
    let error: String?
}

/// Lightweight Supabase client for the share extension
final class ExtensionSupabaseClient {
    static let shared = ExtensionSupabaseClient()

    private init() {}

    /// Check if user is authenticated
    var isAuthenticated: Bool {
        SharedUserDefaults.shared.accessToken != nil
    }

    /// Import a recipe from files (images or PDF)
    /// - Parameters:
    ///   - files: Array of file data to import
    ///   - mediaType: "image" or "pdf"
    /// - Returns: ImportResult with success status and recipe name
    func importRecipe(files: [Data], mediaType: String) async throws -> ImportResult {
        guard let accessToken = SharedUserDefaults.shared.accessToken else {
            return ImportResult(success: false, recipeName: nil, error: "Not authenticated")
        }

        // Determine content type and extension
        let contentType = mediaType == "pdf" ? "application/pdf" : "image/jpeg"
        let fileExtension = mediaType == "pdf" ? "pdf" : "jpg"

        // Upload all files to temp storage
        var storagePaths: [String] = []
        for data in files {
            let path = try await uploadToStorage(
                data: data,
                contentType: contentType,
                fileExtension: fileExtension,
                accessToken: accessToken
            )
            storagePaths.append(path)
        }

        // Call the Edge Function
        let response = try await callOCRImportFunction(
            storagePaths: storagePaths,
            mediaType: mediaType,
            accessToken: accessToken
        )

        return response
    }

    // MARK: - Private Methods

    /// Upload a file to Supabase storage
    private func uploadToStorage(
        data: Data,
        contentType: String,
        fileExtension: String,
        accessToken: String
    ) async throws -> String {
        let fileName = "\(UUID().uuidString).\(fileExtension)"
        let filePath = "temp/\(fileName)"

        let uploadURL = URL(string: "\(AppConstants.supabaseURL)/storage/v1/object/recipe-imports/\(filePath)")!

        var request = URLRequest(url: uploadURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(AppConstants.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.httpBody = data

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw ImportError.uploadFailed
        }

        return filePath
    }

    /// Call the recipe-ocr-import Edge Function
    private func callOCRImportFunction(
        storagePaths: [String],
        mediaType: String,
        accessToken: String
    ) async throws -> ImportResult {
        let functionURL = URL(string: "\(AppConstants.supabaseURL)/functions/v1/recipe-ocr-import")!

        // Get settings from shared defaults
        let language = SharedUserDefaults.shared.recipeLanguage
        let reword = !SharedUserDefaults.shared.keepOriginalWording

        let requestBody: [String: Any] = [
            "storage_paths": storagePaths,
            "media_type": mediaType,
            "language": language,
            "reword": reword
        ]

        var request = URLRequest(url: functionURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(AppConstants.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ImportError.networkError
        }

        // Parse response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ImportError.invalidResponse
        }

        let success = json["success"] as? Bool ?? false
        let recipeName = json["recipe_name"] as? String
        let error = json["error"] as? String

        if !success && error == nil {
            // Check for HTTP error
            if !(200...299).contains(httpResponse.statusCode) {
                return ImportResult(
                    success: false,
                    recipeName: nil,
                    error: "Server error (\(httpResponse.statusCode))"
                )
            }
        }

        return ImportResult(success: success, recipeName: recipeName, error: error)
    }
}

/// Errors that can occur during import
enum ImportError: LocalizedError {
    case uploadFailed
    case networkError
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .uploadFailed:
            return "Failed to upload file"
        case .networkError:
            return "Network error"
        case .invalidResponse:
            return "Invalid server response"
        }
    }
}
