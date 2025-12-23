//
//  ShareViewController.swift
//  RecipeJoeShareExtension
//
//  Entry point for the share extension. Extracts files and hosts the SwiftUI view.
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers

class ShareViewController: UIViewController {

    private var hostingController: UIHostingController<ShareExtensionView>?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        // Extract files and show UI
        Task {
            let files = await extractFiles()
            await MainActor.run {
                showShareExtensionView(with: files)
            }
        }
    }

    // MARK: - UI Setup

    private func showShareExtensionView(with files: [SharedFile]) {
        let shareView = ShareExtensionView(
            files: files,
            onComplete: { [weak self] in
                self?.completeExtension()
            }
        )

        let hostingController = UIHostingController(rootView: shareView)
        self.hostingController = hostingController

        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        hostingController.didMove(toParent: self)
    }

    // MARK: - File Extraction

    private func extractFiles() async -> [SharedFile] {
        guard let extensionContext = extensionContext,
              let inputItems = extensionContext.inputItems as? [NSExtensionItem] else {
            return []
        }

        var files: [SharedFile] = []

        for item in inputItems {
            guard let attachments = item.attachments else { continue }

            for provider in attachments {
                // Check for PDF
                if provider.hasItemConformingToTypeIdentifier(UTType.pdf.identifier) {
                    if let data = await loadData(from: provider, typeIdentifier: UTType.pdf.identifier) {
                        files.append(SharedFile(data: data, isPDF: true, thumbnail: nil))
                    }
                }
                // Check for images
                else if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                    var imageData: Data?

                    // Try specific image types first for better quality
                    if provider.hasItemConformingToTypeIdentifier(UTType.jpeg.identifier) {
                        imageData = await loadData(from: provider, typeIdentifier: UTType.jpeg.identifier)
                    } else if provider.hasItemConformingToTypeIdentifier(UTType.png.identifier) {
                        imageData = await loadData(from: provider, typeIdentifier: UTType.png.identifier)
                    } else if provider.hasItemConformingToTypeIdentifier(UTType.heic.identifier) {
                        imageData = await loadData(from: provider, typeIdentifier: UTType.heic.identifier)
                    } else {
                        imageData = await loadData(from: provider, typeIdentifier: UTType.image.identifier)
                    }

                    if let data = imageData {
                        let thumbnail = createThumbnail(from: data)
                        files.append(SharedFile(data: data, isPDF: false, thumbnail: thumbnail))
                    }
                }

                // Limit to max image count
                if files.count >= AppConstants.Limits.maxImageCount && !files.contains(where: { $0.isPDF }) {
                    break
                }
            }
        }

        return files
    }

    private func loadData(from provider: NSItemProvider, typeIdentifier: String) async -> Data? {
        return await withCheckedContinuation { continuation in
            provider.loadItem(forTypeIdentifier: typeIdentifier, options: nil) { item, error in
                guard error == nil else {
                    continuation.resume(returning: nil)
                    return
                }

                if let url = item as? URL {
                    let data = try? Data(contentsOf: url)
                    continuation.resume(returning: data)
                } else if let data = item as? Data {
                    continuation.resume(returning: data)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    private func createThumbnail(from data: Data) -> UIImage? {
        guard let image = UIImage(data: data) else { return nil }

        let size = CGSize(width: 120, height: 120)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }

    // MARK: - Extension Lifecycle

    private func completeExtension() {
        extensionContext?.completeRequest(returningItems: nil)
    }
}
