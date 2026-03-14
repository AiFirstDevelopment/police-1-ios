import Foundation
import UIKit
import AVFoundation

// MARK: - Media Type

enum MediaType: String, Codable {
    case photo
    case video
}

// MARK: - Evidence Photo Model

struct EvidencePhoto: Identifiable, Codable, Equatable {
    let id: UUID
    let fileName: String
    let capturedAt: Date
    let metadata: PhotoMetadata?
    let mediaType: MediaType

    init(id: UUID = UUID(), fileName: String, capturedAt: Date, metadata: PhotoMetadata? = nil, mediaType: MediaType = .photo) {
        self.id = id
        self.fileName = fileName
        self.capturedAt = capturedAt
        self.metadata = metadata
        self.mediaType = mediaType
    }

    var isVideo: Bool {
        mediaType == .video
    }

    var isPhoto: Bool {
        mediaType == .photo
    }

    func loadImage() -> UIImage? {
        PhotoStorageService.shared.loadImage(fileName: fileName)
    }

    func loadThumbnail() -> UIImage? {
        PhotoStorageService.shared.loadThumbnail(fileName: fileName)
    }

    func videoURL() -> URL? {
        guard isVideo else { return nil }
        return PhotoStorageService.shared.videoURL(fileName: fileName)
    }

    static func == (lhs: EvidencePhoto, rhs: EvidencePhoto) -> Bool {
        lhs.id == rhs.id && lhs.fileName == rhs.fileName
    }
}

// MARK: - Photo Storage Service

final class PhotoStorageService {
    static let shared = PhotoStorageService()

    private let fileManager = FileManager.default
    private let photosDirectory: URL
    private let thumbnailsDirectory: URL
    private let videosDirectory: URL

    private init() {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        photosDirectory = documentsPath.appendingPathComponent("EvidencePhotos", isDirectory: true)
        thumbnailsDirectory = documentsPath.appendingPathComponent("EvidenceThumbnails", isDirectory: true)
        videosDirectory = documentsPath.appendingPathComponent("EvidenceVideos", isDirectory: true)

        createDirectoriesIfNeeded()
    }

    private func createDirectoriesIfNeeded() {
        try? fileManager.createDirectory(at: photosDirectory, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: thumbnailsDirectory, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: videosDirectory, withIntermediateDirectories: true)
    }

    // MARK: - Save Photo

    func savePhoto(_ image: UIImage, metadata: PhotoMetadata?) -> EvidencePhoto? {
        let id = UUID()
        let fileName = "\(id.uuidString).jpg"

        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("[PhotoStorage] Failed to create JPEG data")
            return nil
        }

        let fileURL = photosDirectory.appendingPathComponent(fileName)
        print("[PhotoStorage] Saving photo to: \(fileURL.path)")

        do {
            try imageData.write(to: fileURL)
            print("[PhotoStorage] Photo saved successfully: \(fileName)")
            print("[PhotoStorage] File exists after save: \(fileManager.fileExists(atPath: fileURL.path))")
            saveThumbnail(image, fileName: fileName)
            return EvidencePhoto(
                id: id,
                fileName: fileName,
                capturedAt: metadata?.capturedAt ?? Date(),
                metadata: metadata
            )
        } catch {
            print("[PhotoStorage] Failed to save photo: \(error)")
            return nil
        }
    }

    private func saveThumbnail(_ image: UIImage, fileName: String) {
        let thumbnailSize = CGSize(width: 200, height: 200)
        let renderer = UIGraphicsImageRenderer(size: thumbnailSize)
        let thumbnail = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: thumbnailSize))
        }

        if let data = thumbnail.jpegData(compressionQuality: 0.6) {
            let thumbnailURL = thumbnailsDirectory.appendingPathComponent(fileName)
            try? data.write(to: thumbnailURL)
        }
    }

    // MARK: - Save Video

    func saveVideo(_ videoURL: URL, metadata: PhotoMetadata?) -> EvidencePhoto? {
        let id = UUID()
        let fileName = "\(id.uuidString).mp4"
        let destinationURL = videosDirectory.appendingPathComponent(fileName)

        do {
            try fileManager.copyItem(at: videoURL, to: destinationURL)

            // Generate thumbnail from video
            if let thumbnail = generateVideoThumbnail(from: destinationURL) {
                let thumbnailFileName = "\(id.uuidString).jpg"
                saveThumbnail(thumbnail, fileName: thumbnailFileName)
            }

            return EvidencePhoto(
                id: id,
                fileName: fileName,
                capturedAt: metadata?.capturedAt ?? Date(),
                metadata: metadata,
                mediaType: .video
            )
        } catch {
            print("Failed to save video: \(error)")
            return nil
        }
    }

    private func generateVideoThumbnail(from url: URL) -> UIImage? {
        let asset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true

        let time = CMTime(seconds: 0.5, preferredTimescale: 600)

        do {
            let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
            return UIImage(cgImage: cgImage)
        } catch {
            print("Failed to generate video thumbnail: \(error)")
            return nil
        }
    }

    // MARK: - Load Photo

    func loadImage(fileName: String) -> UIImage? {
        let fileURL = photosDirectory.appendingPathComponent(fileName)
        print("[PhotoStorage] Loading image from: \(fileURL.path)")
        print("[PhotoStorage] File exists: \(fileManager.fileExists(atPath: fileURL.path))")
        guard let data = try? Data(contentsOf: fileURL) else {
            print("[PhotoStorage] Failed to load data from file")
            return nil
        }
        let image = UIImage(data: data)
        print("[PhotoStorage] Loaded image: \(image != nil ? "success" : "nil")")
        return image
    }

    func loadThumbnail(fileName: String) -> UIImage? {
        // For videos, thumbnail has .jpg extension
        let thumbnailFileName = fileName.replacingOccurrences(of: ".mp4", with: ".jpg")
        let thumbnailURL = thumbnailsDirectory.appendingPathComponent(thumbnailFileName)
        if let data = try? Data(contentsOf: thumbnailURL) {
            return UIImage(data: data)
        }
        // Fallback to full image if thumbnail doesn't exist (for photos)
        return loadImage(fileName: fileName)
    }

    func videoURL(fileName: String) -> URL? {
        let fileURL = videosDirectory.appendingPathComponent(fileName)
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }
        return fileURL
    }

    // MARK: - Delete Photo

    func deletePhoto(fileName: String) {
        let fileURL = photosDirectory.appendingPathComponent(fileName)
        let thumbnailURL = thumbnailsDirectory.appendingPathComponent(fileName)

        try? fileManager.removeItem(at: fileURL)
        try? fileManager.removeItem(at: thumbnailURL)
    }

    func deleteVideo(fileName: String) {
        let fileURL = videosDirectory.appendingPathComponent(fileName)
        let thumbnailFileName = fileName.replacingOccurrences(of: ".mp4", with: ".jpg")
        let thumbnailURL = thumbnailsDirectory.appendingPathComponent(thumbnailFileName)

        try? fileManager.removeItem(at: fileURL)
        try? fileManager.removeItem(at: thumbnailURL)
    }

    func deleteMedia(_ media: EvidencePhoto) {
        if media.isVideo {
            deleteVideo(fileName: media.fileName)
        } else {
            deletePhoto(fileName: media.fileName)
        }
    }

    func deletePhotos(_ photos: [EvidencePhoto]) {
        for photo in photos {
            deleteMedia(photo)
        }
    }

    // MARK: - Storage Info

    var totalStorageUsed: Int64 {
        calculateDirectorySize(photosDirectory) + calculateDirectorySize(thumbnailsDirectory) + calculateDirectorySize(videosDirectory)
    }

    var formattedStorageUsed: String {
        ByteCountFormatter.string(fromByteCount: totalStorageUsed, countStyle: .file)
    }

    private func calculateDirectorySize(_ url: URL) -> Int64 {
        guard let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }

        var totalSize: Int64 = 0
        for case let fileURL as URL in enumerator {
            if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                totalSize += Int64(fileSize)
            }
        }
        return totalSize
    }

    // MARK: - Cleanup

    func clearAllPhotos() {
        try? fileManager.removeItem(at: photosDirectory)
        try? fileManager.removeItem(at: thumbnailsDirectory)
        try? fileManager.removeItem(at: videosDirectory)
        createDirectoriesIfNeeded()
    }
}
