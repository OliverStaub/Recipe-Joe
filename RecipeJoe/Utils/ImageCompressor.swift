//
//  ImageCompressor.swift
//  RecipeJoe
//
//  Utility for compressing images before upload
//

import UIKit

/// Utility class for image compression
enum ImageCompressor {
    /// Maximum image size for Claude Vision API (accounting for base64 overhead)
    /// Base64 adds ~33% overhead, so 3.5MB raw ≈ 4.7MB base64 (under 5MB limit)
    static let maxSizeMB: Double = 3.5
    static let maxSizeBytes: Int = Int(maxSizeMB * 1024 * 1024)

    /// Compress an image to be under the maximum size
    /// - Parameters:
    ///   - image: The image to compress
    ///   - targetMaxBytes: Maximum size in bytes (defaults to maxSizeBytes)
    /// - Returns: Compressed JPEG data, or nil if compression failed
    static func compress(_ image: UIImage, targetMaxBytes: Int = maxSizeBytes) -> Data? {
        var quality: CGFloat = 0.8

        while quality > 0.1 {
            if let data = image.jpegData(compressionQuality: quality) {
                if data.count <= targetMaxBytes {
                    return data
                }
            }
            quality -= 0.1
        }

        // Last resort: return with lowest quality
        return image.jpegData(compressionQuality: 0.1)
    }

    /// Check if image data is within the size limit
    /// - Parameter data: Image data to check
    /// - Returns: true if under the limit
    static func isWithinLimit(_ data: Data) -> Bool {
        return data.count <= maxSizeBytes
    }
}
