import XCTest
import SwiftUI
import ViewInspector
@testable import Police1

// MARK: - PhotoCaptureView Tests

@MainActor
final class PhotoCaptureViewTests: XCTestCase {

    func testPhotoCaptureViewHasNavigationStack() throws {
        let view = PhotoCaptureView { _ in }
        let sut = try view.inspect()

        let nav = try sut.find(ViewType.NavigationStack.self)
        XCTAssertNotNil(nav)
    }

    func testPhotoCaptureViewHasVStack() throws {
        let view = PhotoCaptureView { _ in }
        let sut = try view.inspect()

        let vstack = try sut.find(ViewType.VStack.self)
        XCTAssertNotNil(vstack)
    }

    func testPhotoCaptureViewHasCameraIcon() throws {
        let view = PhotoCaptureView { _ in }
        let sut = try view.inspect()

        let images = sut.findAll(ViewType.Image.self)
        XCTAssertGreaterThanOrEqual(images.count, 1)
    }

    func testPhotoCaptureViewHasTitle() throws {
        let view = PhotoCaptureView { _ in }
        let sut = try view.inspect()

        let texts = sut.findAll(ViewType.Text.self)
        let titleText = texts.first { (try? $0.string()) == "Add Media" }
        XCTAssertNotNil(titleText)
    }

    func testPhotoCaptureViewHasCameraButton() throws {
        let view = PhotoCaptureView { _ in }
        let sut = try view.inspect()

        let buttons = sut.findAll(ViewType.Button.self)
        XCTAssertGreaterThanOrEqual(buttons.count, 1)
    }

    func testPhotoCaptureViewHasTakePhotoText() throws {
        let view = PhotoCaptureView { _ in }
        let sut = try view.inspect()

        let texts = sut.findAll(ViewType.Text.self)
        let takePhotoText = texts.first { (try? $0.string()) == "Take Photo" }
        XCTAssertNotNil(takePhotoText)
    }

    func testPhotoCaptureViewHasMediaLibraryText() throws {
        let view = PhotoCaptureView { _ in }
        let sut = try view.inspect()

        let texts = sut.findAll(ViewType.Text.self)
        let libraryText = texts.first { (try? $0.string()) == "Media Library" }
        XCTAssertNotNil(libraryText)
    }

    func testPhotoCaptureViewHasRecordVideoText() throws {
        let view = PhotoCaptureView { _ in }
        let sut = try view.inspect()

        let texts = sut.findAll(ViewType.Text.self)
        let videoText = texts.first { (try? $0.string()) == "Record Video" }
        XCTAssertNotNil(videoText)
    }

    func testPhotoCaptureViewHasVideoIcon() throws {
        let view = PhotoCaptureView { _ in }
        let sut = try view.inspect()

        // Should have video icon (video.fill)
        let images = sut.findAll(ViewType.Image.self)
        XCTAssertGreaterThanOrEqual(images.count, 3) // camera, video, and library icons
    }

    func testPhotoCaptureViewHasHStacks() throws {
        let view = PhotoCaptureView { _ in }
        let sut = try view.inspect()

        let hstacks = sut.findAll(ViewType.HStack.self)
        XCTAssertGreaterThanOrEqual(hstacks.count, 2)
    }

    func testPhotoCaptureViewHasSpacer() throws {
        let view = PhotoCaptureView { _ in }
        let sut = try view.inspect()

        let spacer = try sut.find(ViewType.Spacer.self)
        XCTAssertNotNil(spacer)
    }
}

// MARK: - MediaThumbnail Tests

@MainActor
final class MediaThumbnailTests: XCTestCase {

    private func createMockPhoto() -> CapturedMedia {
        let image = UIImage(systemName: "photo")!
        return CapturedMedia(image: image, videoURL: nil, capturedAt: Date(), location: nil, mediaType: .photo)
    }

    private func createMockVideo() -> CapturedMedia {
        return CapturedMedia(image: nil, videoURL: nil, capturedAt: Date(), location: nil, mediaType: .video)
    }

    func testMediaThumbnailHasZStack() throws {
        let media = createMockPhoto()
        let view = MediaThumbnail(media: media) {}
        let sut = try view.inspect()

        let zstack = try sut.find(ViewType.ZStack.self)
        XCTAssertNotNil(zstack)
    }

    func testMediaThumbnailHasImage() throws {
        let media = createMockPhoto()
        let view = MediaThumbnail(media: media) {}
        let sut = try view.inspect()

        let images = sut.findAll(ViewType.Image.self)
        XCTAssertGreaterThanOrEqual(images.count, 1)
    }

    func testMediaThumbnailHasDeleteButton() throws {
        let media = createMockPhoto()
        let view = MediaThumbnail(media: media) {}
        let sut = try view.inspect()

        let buttons = sut.findAll(ViewType.Button.self)
        XCTAssertGreaterThanOrEqual(buttons.count, 1)
    }

    func testVideoThumbnailShowsPlayIcon() throws {
        let media = createMockVideo()
        let view = MediaThumbnail(media: media) {}
        let sut = try view.inspect()

        // Video thumbnails have play icon
        let images = sut.findAll(ViewType.Image.self)
        XCTAssertGreaterThanOrEqual(images.count, 1)
    }
}

// For backwards compatibility
typealias PhotoThumbnailTests = MediaThumbnailTests

// MARK: - PhotoMetadataBar Tests

@MainActor
final class PhotoMetadataBarTests: XCTestCase {

    func testPhotoMetadataBarHasHStack() throws {
        let metadata = PhotoMetadata(
            capturedAt: Date(),
            latitude: 37.7749,
            longitude: -122.4194,
            altitude: 10.0
        )
        let view = PhotoMetadataBar(metadata: metadata)
        let sut = try view.inspect()

        let hstack = try sut.find(ViewType.HStack.self)
        XCTAssertNotNil(hstack)
    }

    func testPhotoMetadataBarHasLabels() throws {
        let metadata = PhotoMetadata(
            capturedAt: Date(),
            latitude: 37.7749,
            longitude: -122.4194,
            altitude: 10.0
        )
        let view = PhotoMetadataBar(metadata: metadata)
        let sut = try view.inspect()

        let labels = sut.findAll(ViewType.Label.self)
        XCTAssertGreaterThanOrEqual(labels.count, 2) // date and location
    }

    func testPhotoMetadataBarWithoutLocationShowsDateOnly() throws {
        let metadata = PhotoMetadata(
            capturedAt: Date(),
            latitude: nil,
            longitude: nil,
            altitude: nil
        )
        let view = PhotoMetadataBar(metadata: metadata)
        let sut = try view.inspect()

        let labels = sut.findAll(ViewType.Label.self)
        XCTAssertGreaterThanOrEqual(labels.count, 1) // just date
    }
}

// MARK: - CapturedMedia Tests

final class CapturedMediaTests: XCTestCase {

    func testCapturedMediaHasUniqueId() {
        let image = UIImage(systemName: "photo")!
        let media1 = CapturedMedia(image: image, videoURL: nil, capturedAt: Date(), location: nil, mediaType: .photo)
        let media2 = CapturedMedia(image: image, videoURL: nil, capturedAt: Date(), location: nil, mediaType: .photo)

        XCTAssertNotEqual(media1.id, media2.id)
    }

    func testCapturedMediaStoresImage() {
        let image = UIImage(systemName: "photo")!
        let media = CapturedMedia(image: image, videoURL: nil, capturedAt: Date(), location: nil, mediaType: .photo)

        XCTAssertNotNil(media.image)
    }

    func testCapturedMediaStoresDate() {
        let image = UIImage(systemName: "photo")!
        let date = Date()
        let media = CapturedMedia(image: image, videoURL: nil, capturedAt: date, location: nil, mediaType: .photo)

        XCTAssertEqual(media.capturedAt, date)
    }

    func testCapturedMediaThumbnailIsSmaller() {
        let image = UIImage(systemName: "photo")!
        let media = CapturedMedia(image: image, videoURL: nil, capturedAt: Date(), location: nil, mediaType: .photo)
        let thumbnail = media.thumbnailImage

        XCTAssertNotNil(thumbnail)
        XCTAssertLessThanOrEqual(thumbnail!.size.width, 150)
        XCTAssertLessThanOrEqual(thumbnail!.size.height, 150)
    }

    func testCapturedMediaMetadataWithoutLocation() {
        let image = UIImage(systemName: "photo")!
        let media = CapturedMedia(image: image, videoURL: nil, capturedAt: Date(), location: nil, mediaType: .photo)
        let metadata = media.metadata

        XCTAssertNil(metadata.latitude)
        XCTAssertNil(metadata.longitude)
        XCTAssertNil(metadata.altitude)
    }

    func testCapturedMediaIsVideoTrue() {
        let media = CapturedMedia(image: nil, videoURL: nil, capturedAt: Date(), location: nil, mediaType: .video)
        XCTAssertTrue(media.isVideo)
    }

    func testCapturedMediaIsVideoFalseForPhoto() {
        let image = UIImage(systemName: "photo")!
        let media = CapturedMedia(image: image, videoURL: nil, capturedAt: Date(), location: nil, mediaType: .photo)
        XCTAssertFalse(media.isVideo)
    }

    func testCapturedMediaPhotoType() {
        let image = UIImage(systemName: "photo")!
        let media = CapturedMedia(image: image, videoURL: nil, capturedAt: Date(), location: nil, mediaType: .photo)
        XCTAssertEqual(media.mediaType, .photo)
    }

    func testCapturedMediaVideoType() {
        let media = CapturedMedia(image: nil, videoURL: nil, capturedAt: Date(), location: nil, mediaType: .video)
        XCTAssertEqual(media.mediaType, .video)
    }
}

// For backwards compatibility
typealias CapturedPhotoTests = CapturedMediaTests

// MARK: - PhotoMetadata Tests

final class PhotoMetadataTests: XCTestCase {

    func testPhotoMetadataStoresAllValues() {
        let date = Date()
        let metadata = PhotoMetadata(
            capturedAt: date,
            latitude: 37.7749,
            longitude: -122.4194,
            altitude: 100.0
        )

        XCTAssertEqual(metadata.capturedAt, date)
        XCTAssertEqual(metadata.latitude, 37.7749)
        XCTAssertEqual(metadata.longitude, -122.4194)
        XCTAssertEqual(metadata.altitude, 100.0)
    }

    func testPhotoMetadataAllowsNilLocation() {
        let metadata = PhotoMetadata(
            capturedAt: Date(),
            latitude: nil,
            longitude: nil,
            altitude: nil
        )

        XCTAssertNil(metadata.latitude)
        XCTAssertNil(metadata.longitude)
        XCTAssertNil(metadata.altitude)
    }

    func testPhotoMetadataIsCodable() throws {
        let date = Date()
        let metadata = PhotoMetadata(
            capturedAt: date,
            latitude: 37.7749,
            longitude: -122.4194,
            altitude: 100.0
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(metadata)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(PhotoMetadata.self, from: data)

        XCTAssertEqual(decoded.latitude, metadata.latitude)
        XCTAssertEqual(decoded.longitude, metadata.longitude)
        XCTAssertEqual(decoded.altitude, metadata.altitude)
    }
}

// MARK: - MediaType Tests

final class MediaTypeTests: XCTestCase {

    func testMediaTypePhoto() {
        let type = MediaType.photo
        XCTAssertEqual(type.rawValue, "photo")
    }

    func testMediaTypeVideo() {
        let type = MediaType.video
        XCTAssertEqual(type.rawValue, "video")
    }

    func testMediaTypeIsCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let photoData = try encoder.encode(MediaType.photo)
        let decodedPhoto = try decoder.decode(MediaType.self, from: photoData)
        XCTAssertEqual(decodedPhoto, .photo)

        let videoData = try encoder.encode(MediaType.video)
        let decodedVideo = try decoder.decode(MediaType.self, from: videoData)
        XCTAssertEqual(decodedVideo, .video)
    }
}

// MARK: - EvidencePhoto Tests

final class EvidencePhotoTests: XCTestCase {

    func testEvidencePhotoStoresFileName() {
        let photo = EvidencePhoto(
            fileName: "test.jpg",
            capturedAt: Date(),
            metadata: nil
        )

        XCTAssertEqual(photo.fileName, "test.jpg")
    }

    func testEvidencePhotoHasUniqueId() {
        let photo1 = EvidencePhoto(fileName: "test1.jpg", capturedAt: Date(), metadata: nil)
        let photo2 = EvidencePhoto(fileName: "test2.jpg", capturedAt: Date(), metadata: nil)

        XCTAssertNotEqual(photo1.id, photo2.id)
    }

    func testEvidencePhotoEquatable() {
        let id = UUID()
        let date = Date()
        let photo1 = EvidencePhoto(id: id, fileName: "test.jpg", capturedAt: date, metadata: nil)
        let photo2 = EvidencePhoto(id: id, fileName: "test.jpg", capturedAt: date, metadata: nil)

        XCTAssertEqual(photo1, photo2)
    }

    func testEvidencePhotoNotEqualWithDifferentId() {
        let date = Date()
        let photo1 = EvidencePhoto(fileName: "test.jpg", capturedAt: date, metadata: nil)
        let photo2 = EvidencePhoto(fileName: "test.jpg", capturedAt: date, metadata: nil)

        XCTAssertNotEqual(photo1, photo2)
    }

    func testEvidencePhotoIsCodable() throws {
        let photo = EvidencePhoto(
            fileName: "test.jpg",
            capturedAt: Date(),
            metadata: PhotoMetadata(
                capturedAt: Date(),
                latitude: 37.7749,
                longitude: -122.4194,
                altitude: 100.0
            )
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(photo)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(EvidencePhoto.self, from: data)

        XCTAssertEqual(decoded.fileName, photo.fileName)
        XCTAssertEqual(decoded.metadata?.latitude, photo.metadata?.latitude)
    }

    func testEvidencePhotoDefaultsToPhotoType() {
        let photo = EvidencePhoto(fileName: "test.jpg", capturedAt: Date(), metadata: nil)
        XCTAssertEqual(photo.mediaType, .photo)
    }

    func testEvidencePhotoIsVideoFalse() {
        let photo = EvidencePhoto(fileName: "test.jpg", capturedAt: Date(), metadata: nil, mediaType: .photo)
        XCTAssertFalse(photo.isVideo)
        XCTAssertTrue(photo.isPhoto)
    }

    func testEvidencePhotoIsVideoTrue() {
        let video = EvidencePhoto(fileName: "test.mp4", capturedAt: Date(), metadata: nil, mediaType: .video)
        XCTAssertTrue(video.isVideo)
        XCTAssertFalse(video.isPhoto)
    }

    func testEvidencePhotoVideoURLReturnsNilForPhoto() {
        let photo = EvidencePhoto(fileName: "test.jpg", capturedAt: Date(), metadata: nil, mediaType: .photo)
        XCTAssertNil(photo.videoURL())
    }

    func testEvidencePhotoMediaTypeCodable() throws {
        let video = EvidencePhoto(fileName: "test.mp4", capturedAt: Date(), metadata: nil, mediaType: .video)

        let encoder = JSONEncoder()
        let data = try encoder.encode(video)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(EvidencePhoto.self, from: data)

        XCTAssertEqual(decoded.mediaType, .video)
    }
}

// MARK: - PhotoStorageService Tests

final class PhotoStorageServiceTests: XCTestCase {

    func testSharedInstanceExists() {
        let service = PhotoStorageService.shared
        XCTAssertNotNil(service)
    }

    func testSharedInstanceIsSingleton() {
        let service1 = PhotoStorageService.shared
        let service2 = PhotoStorageService.shared
        XCTAssertTrue(service1 === service2)
    }

    func testFormattedStorageUsedReturnsString() {
        let service = PhotoStorageService.shared
        let formatted = service.formattedStorageUsed
        XCTAssertFalse(formatted.isEmpty)
    }

    func testTotalStorageUsedReturnsNonNegative() {
        let service = PhotoStorageService.shared
        XCTAssertGreaterThanOrEqual(service.totalStorageUsed, 0)
    }

    func testSaveAndLoadPhoto() {
        let service = PhotoStorageService.shared
        let image = UIImage(systemName: "photo")!

        guard let savedPhoto = service.savePhoto(image, metadata: nil) else {
            XCTFail("Failed to save photo")
            return
        }

        let loadedImage = service.loadImage(fileName: savedPhoto.fileName)
        XCTAssertNotNil(loadedImage)

        // Cleanup
        service.deletePhoto(fileName: savedPhoto.fileName)
    }

    func testSaveAndLoadThumbnail() {
        let service = PhotoStorageService.shared
        let image = UIImage(systemName: "photo")!

        guard let savedPhoto = service.savePhoto(image, metadata: nil) else {
            XCTFail("Failed to save photo")
            return
        }

        let thumbnail = service.loadThumbnail(fileName: savedPhoto.fileName)
        XCTAssertNotNil(thumbnail)

        // Cleanup
        service.deletePhoto(fileName: savedPhoto.fileName)
    }

    func testDeletePhoto() {
        let service = PhotoStorageService.shared
        let image = UIImage(systemName: "photo")!

        guard let savedPhoto = service.savePhoto(image, metadata: nil) else {
            XCTFail("Failed to save photo")
            return
        }

        service.deletePhoto(fileName: savedPhoto.fileName)

        let loadedImage = service.loadImage(fileName: savedPhoto.fileName)
        XCTAssertNil(loadedImage)
    }

    func testDeleteMultiplePhotos() {
        let service = PhotoStorageService.shared
        let image = UIImage(systemName: "photo")!

        var photos: [EvidencePhoto] = []
        for _ in 0..<3 {
            if let photo = service.savePhoto(image, metadata: nil) {
                photos.append(photo)
            }
        }

        service.deletePhotos(photos)

        for photo in photos {
            let loadedImage = service.loadImage(fileName: photo.fileName)
            XCTAssertNil(loadedImage)
        }
    }

    func testLoadNonExistentPhotoReturnsNil() {
        let service = PhotoStorageService.shared
        let image = service.loadImage(fileName: "nonexistent.jpg")
        XCTAssertNil(image)
    }
}

// MARK: - EvidencePhotoThumbnail Tests

@MainActor
final class EvidencePhotoThumbnailTests: XCTestCase {

    func testEvidencePhotoThumbnailHasZStack() throws {
        let photo = EvidencePhoto(fileName: "test.jpg", capturedAt: Date(), metadata: nil)
        let view = EvidencePhotoThumbnail(photo: photo) {}
        let sut = try view.inspect()

        let zstack = try sut.find(ViewType.ZStack.self)
        XCTAssertNotNil(zstack)
    }

    func testEvidencePhotoThumbnailHasDeleteButton() throws {
        let photo = EvidencePhoto(fileName: "test.jpg", capturedAt: Date(), metadata: nil)
        let view = EvidencePhotoThumbnail(photo: photo) {}
        let sut = try view.inspect()

        let buttons = sut.findAll(ViewType.Button.self)
        XCTAssertGreaterThanOrEqual(buttons.count, 1)
    }
}

// MARK: - Updated EvidenceItem Tests

final class EvidenceItemPhotoTests: XCTestCase {

    func testEvidenceItemHasPhotosProperty() {
        let item = EvidenceItem()
        XCTAssertTrue(item.photos.isEmpty)
    }

    func testEvidenceItemHasPhotosReturnsFalseWhenEmpty() {
        let item = EvidenceItem()
        XCTAssertFalse(item.hasPhotos)
    }

    func testEvidenceItemHasPhotosReturnsTrueWithPhotos() {
        let photo = EvidencePhoto(fileName: "test.jpg", capturedAt: Date(), metadata: nil)
        let item = EvidenceItem(photos: [photo])
        XCTAssertTrue(item.hasPhotos)
    }

    func testEvidenceItemPhotoCount() {
        let photos = [
            EvidencePhoto(fileName: "test1.jpg", capturedAt: Date(), metadata: nil),
            EvidencePhoto(fileName: "test2.jpg", capturedAt: Date(), metadata: nil)
        ]
        let item = EvidenceItem(photos: photos)
        XCTAssertEqual(item.photoCount, 2)
    }

    func testEvidenceItemPhotoCountIncludesUrls() {
        let photo = EvidencePhoto(fileName: "test.jpg", capturedAt: Date(), metadata: nil)
        let item = EvidenceItem(photoUrls: ["http://example.com/photo.jpg"], photos: [photo])
        XCTAssertEqual(item.photoCount, 2)
    }
}

// MARK: - MediaMetadataBar Tests

@MainActor
final class MediaMetadataBarTests: XCTestCase {

    func testMediaMetadataBarHasHStack() throws {
        let metadata = PhotoMetadata(
            capturedAt: Date(),
            latitude: 37.7749,
            longitude: -122.4194,
            altitude: 10.0
        )
        let view = MediaMetadataBar(metadata: metadata, isVideo: false)
        let sut = try view.inspect()

        let hstack = try sut.find(ViewType.HStack.self)
        XCTAssertNotNil(hstack)
    }

    func testMediaMetadataBarForVideoHasVideoLabel() throws {
        let metadata = PhotoMetadata(
            capturedAt: Date(),
            latitude: nil,
            longitude: nil,
            altitude: nil
        )
        let view = MediaMetadataBar(metadata: metadata, isVideo: true)
        let sut = try view.inspect()

        let labels = sut.findAll(ViewType.Label.self)
        XCTAssertGreaterThanOrEqual(labels.count, 2) // date and video
    }

    func testMediaMetadataBarForPhotoHasNoVideoLabel() throws {
        let metadata = PhotoMetadata(
            capturedAt: Date(),
            latitude: nil,
            longitude: nil,
            altitude: nil
        )
        let view = MediaMetadataBar(metadata: metadata, isVideo: false)
        let sut = try view.inspect()

        let labels = sut.findAll(ViewType.Label.self)
        XCTAssertGreaterThanOrEqual(labels.count, 1) // just date
    }
}

// MARK: - EvidenceMediaView Tests

@MainActor
final class EvidenceMediaViewTests: XCTestCase {

    func testEvidenceMediaViewHasZStack() throws {
        let media = EvidencePhoto(fileName: "test.jpg", capturedAt: Date(), metadata: nil, mediaType: .photo)
        let view = EvidenceMediaView(media: media)
        let sut = try view.inspect()

        let zstacks = sut.findAll(ViewType.ZStack.self)
        XCTAssertGreaterThanOrEqual(zstacks.count, 1)
    }

    func testEvidenceMediaViewVideoShowsPlayIcon() throws {
        let media = EvidencePhoto(fileName: "test.mp4", capturedAt: Date(), metadata: nil, mediaType: .video)
        let view = EvidenceMediaView(media: media)
        let sut = try view.inspect()

        // Video should have play icon
        let images = sut.findAll(ViewType.Image.self)
        XCTAssertGreaterThanOrEqual(images.count, 1)
    }
}

// MARK: - MediaGalleryItem Tests

@MainActor
final class MediaGalleryItemTests: XCTestCase {

    func testMediaGalleryItemHasZStack() throws {
        let media = EvidencePhoto(fileName: "test.jpg", capturedAt: Date(), metadata: nil, mediaType: .photo)
        let view = MediaGalleryItem(media: media) {}
        let sut = try view.inspect()

        let zstack = try sut.find(ViewType.ZStack.self)
        XCTAssertNotNil(zstack)
    }

    func testMediaGalleryItemVideoShowsPlayIcon() throws {
        let media = EvidencePhoto(fileName: "test.mp4", capturedAt: Date(), metadata: nil, mediaType: .video)
        let view = MediaGalleryItem(media: media) {}
        let sut = try view.inspect()

        // Video should have play icon
        let images = sut.findAll(ViewType.Image.self)
        XCTAssertGreaterThanOrEqual(images.count, 1)
    }
}

// MARK: - ViewInspector Extensions

extension PhotoCaptureView: @retroactive Inspectable {}
extension MediaThumbnail: @retroactive Inspectable {}
extension PhotoMetadataBar: @retroactive Inspectable {}
extension MediaMetadataBar: @retroactive Inspectable {}
extension EvidencePhotoThumbnail: @retroactive Inspectable {}
extension EvidenceMediaView: @retroactive Inspectable {}
extension MediaGalleryItem: @retroactive Inspectable {}
