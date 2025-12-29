//
//  ImageCompressorTests.swift
//  RecipeJoeTests
//
//  Tests for image compression utility
//

import Testing
import UIKit
@testable import RecipeJoe

@Suite("Image Compressor Tests")
struct ImageCompressorTests {

    // MARK: - Size Limit Tests

    @Test("Max size constant is correct")
    func testMaxSizeConstant() {
        // 3.5 MB in bytes
        let expected = Int(3.5 * 1024 * 1024)
        #expect(ImageCompressor.maxSizeBytes == expected)
    }

    @Test("isWithinLimit returns true for small data")
    func testIsWithinLimitSmall() {
        let smallData = Data(repeating: 0, count: 1000)
        #expect(ImageCompressor.isWithinLimit(smallData) == true)
    }

    @Test("isWithinLimit returns false for large data")
    func testIsWithinLimitLarge() {
        let largeData = Data(repeating: 0, count: ImageCompressor.maxSizeBytes + 1)
        #expect(ImageCompressor.isWithinLimit(largeData) == false)
    }

    @Test("isWithinLimit returns true for exactly max size")
    func testIsWithinLimitExact() {
        let exactData = Data(repeating: 0, count: ImageCompressor.maxSizeBytes)
        #expect(ImageCompressor.isWithinLimit(exactData) == true)
    }

    // MARK: - Compression Tests

    @Test("Compress returns data for valid image")
    func testCompressReturnsData() {
        // Create a simple test image
        let size = CGSize(width: 100, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            UIColor.red.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }

        let result = ImageCompressor.compress(image)
        #expect(result != nil)
    }

    @Test("Compressed image is within size limit")
    func testCompressedImageWithinLimit() {
        // Create a larger test image
        let size = CGSize(width: 1000, height: 1000)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            // Create a noisy image that doesn't compress well
            for x in 0..<Int(size.width) {
                for y in 0..<Int(size.height) {
                    let color = UIColor(
                        red: CGFloat.random(in: 0...1),
                        green: CGFloat.random(in: 0...1),
                        blue: CGFloat.random(in: 0...1),
                        alpha: 1
                    )
                    color.setFill()
                    context.fill(CGRect(x: x, y: y, width: 1, height: 1))
                }
            }
        }

        let result = ImageCompressor.compress(image)
        #expect(result != nil)
        if let data = result {
            #expect(ImageCompressor.isWithinLimit(data))
        }
    }

    @Test("Compress with custom target size")
    func testCompressWithCustomTarget() {
        let size = CGSize(width: 500, height: 500)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            UIColor.blue.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }

        let customLimit = 100_000 // 100KB
        let result = ImageCompressor.compress(image, targetMaxBytes: customLimit)
        #expect(result != nil)
        if let data = result {
            #expect(data.count <= customLimit)
        }
    }

    // MARK: - Base64 Overhead Tests

    @Test("Compressed image base64 is under 5MB")
    func testBase64SizeUnderLimit() {
        // Create a moderately large test image
        let size = CGSize(width: 2000, height: 2000)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            UIColor.green.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }

        let result = ImageCompressor.compress(image)
        #expect(result != nil)

        if let data = result {
            // Base64 encoding adds ~33% overhead
            let base64Size = data.base64EncodedData().count
            let claudeLimit = 5 * 1024 * 1024 // 5MB
            #expect(base64Size < claudeLimit, "Base64 size \(base64Size) should be under 5MB")
        }
    }
}
