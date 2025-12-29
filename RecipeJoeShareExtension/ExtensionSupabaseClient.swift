//
//  ExtensionSupabaseClient.swift
//  RecipeJoeShareExtension
//
//  Lightweight Supabase client for share extension.
//  Uses URLSession directly to minimize memory footprint.
//

import Foundation
import UIKit

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

    /// Maximum image size for Claude Vision API (3.5MB raw = ~4.7MB base64, under 5MB limit)
    private let maxImageSizeBytes = Int(3.5 * 1024 * 1024)

    /// Import a recipe from files (images or PDF)
    /// - Parameters:
    ///   - files: Array of file data to import
    ///   - mediaType: "image" or "pdf"
    /// - Returns: ImportResult with success status and recipe name
    func importRecipe(files: [Data], mediaType: String) async throws -> ImportResult {
        // Check if we have an access token
        guard let accessToken = SharedUserDefaults.shared.accessToken else {
            return ImportResult(success: false, recipeName: nil, error: "No access token. Please open RecipeJoe and sign in again.")
        }

        // Token exists, continue with import

        // Determine content type and extension
        let contentType = mediaType == "pdf" ? "application/pdf" : "image/jpeg"
        let fileExtension = mediaType == "pdf" ? "pdf" : "jpg"

        // Compress images if needed (PDFs are not compressed)
        var processedFiles = files
        if mediaType == "image" {
            processedFiles = files.compactMap { compressImage($0) }
            if processedFiles.isEmpty {
                return ImportResult(success: false, recipeName: nil, error: "Failed to process images")
            }
        }

        // Upload all files to temp storage
        var storagePaths: [String] = []
        for data in processedFiles {
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

    /// Compress image to fit within Claude Vision API limits
    private func compressImage(_ data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return data }

        // If already small enough, return as-is
        if data.count <= maxImageSizeBytes {
            // Still convert to JPEG for consistency
            return image.jpegData(compressionQuality: 0.8) ?? data
        }

        // Progressively reduce quality until under limit
        var quality: CGFloat = 0.8
        while quality > 0.1 {
            if let compressed = image.jpegData(compressionQuality: quality),
               compressed.count <= maxImageSizeBytes {
                return compressed
            }
            quality -= 0.1
        }

        // Last resort: lowest quality
        return image.jpegData(compressionQuality: 0.1)
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

        let responseData: Data
        let response: URLResponse

        do {
            (responseData, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw ImportError.networkError("\(error)")
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ImportError.uploadFailed(statusCode: 0, message: "No HTTP response")
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let errorBody = String(data: responseData, encoding: .utf8) ?? "Unknown"
            throw ImportError.uploadFailed(statusCode: httpResponse.statusCode, message: errorBody)
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
        let translate = SharedUserDefaults.shared.enableTranslation

        let requestBody: [String: Any] = [
            "storage_paths": storagePaths,
            "media_type": mediaType,
            "language": language,
            "translate": translate
        ]

        var request = URLRequest(url: functionURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(AppConstants.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        // OCR can take a while - set 5 minute timeout
        request.timeoutInterval = 300

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ImportError.networkError("No HTTP response from function")
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
    case uploadFailed(statusCode: Int, message: String)
    case networkError(String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .uploadFailed(let statusCode, let message):
            return "Upload error \(statusCode): \(message)"
        case .networkError(let details):
            return "Network: \(details)"
        case .invalidResponse:
            return "Invalid server response"
        }
    }
}
