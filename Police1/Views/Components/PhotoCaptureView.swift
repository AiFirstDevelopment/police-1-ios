import SwiftUI
import PhotosUI
import CoreLocation
import AVKit
import UniformTypeIdentifiers

// MARK: - Media Capture View

struct PhotoCaptureView: View {
    @Environment(\.dismiss) private var dismiss
    let onPhotoCaptured: (CapturedMedia) -> Void

    @State private var showingCamera = false
    @State private var showingVideoCamera = false
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var capturedMedia: [CapturedMedia] = []
    @State private var isProcessing = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.15))
                            .frame(width: 80, height: 80)
                        Image(systemName: "camera.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(.blue)
                    }

                    Text("Add Media")
                        .font(.title2.weight(.bold))

                    Text("Capture photos, videos, or select from library")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)

                // Capture options
                VStack(spacing: 16) {
                    // Photo camera button
                    Button(action: { showingCamera = true }) {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.blue.opacity(0.15))
                                    .frame(width: 50, height: 50)
                                Image(systemName: "camera.fill")
                                    .font(.title2)
                                    .foregroundStyle(.blue)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Take Photo")
                                    .font(.body.weight(.semibold))
                                Text("Capture photo evidence")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundStyle(.tertiary)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)

                    // Video camera button
                    Button(action: { showingVideoCamera = true }) {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.red.opacity(0.15))
                                    .frame(width: 50, height: 50)
                                Image(systemName: "video.fill")
                                    .font(.title2)
                                    .foregroundStyle(.red)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Record Video")
                                    .font(.body.weight(.semibold))
                                Text("Capture video evidence")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundStyle(.tertiary)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)

                    // Media library button
                    PhotosPicker(
                        selection: $selectedItems,
                        maxSelectionCount: 10,
                        matching: .any(of: [.images, .videos])
                    ) {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.purple.opacity(0.15))
                                    .frame(width: 50, height: 50)
                                Image(systemName: "photo.on.rectangle")
                                    .font(.title2)
                                    .foregroundStyle(.purple)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Media Library")
                                    .font(.body.weight(.semibold))
                                Text("Select photos or videos")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundStyle(.tertiary)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)

                // Selected media preview
                if !capturedMedia.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Selected Media")
                                .font(.headline)
                            Spacer()
                            Text(mediaCountText)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(capturedMedia) { media in
                                    MediaThumbnail(media: media) {
                                        capturedMedia.removeAll { $0.id == media.id }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }

                Spacer()

                // Processing indicator
                if isProcessing {
                    ProgressView("Processing media...")
                        .padding()
                }

                // Add button
                if !capturedMedia.isEmpty {
                    Button(action: addMedia) {
                        Text("Add \(capturedMedia.count) Item\(capturedMedia.count == 1 ? "" : "s")")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .navigationTitle("Add Media")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .fullScreenCover(isPresented: $showingCamera) {
                CameraView { image, location in
                    let media = CapturedMedia(
                        image: image,
                        videoURL: nil,
                        capturedAt: Date(),
                        location: location,
                        mediaType: .photo
                    )
                    capturedMedia.append(media)
                }
            }
            .fullScreenCover(isPresented: $showingVideoCamera) {
                VideoCameraView { videoURL, location in
                    let media = CapturedMedia(
                        image: nil,
                        videoURL: videoURL,
                        capturedAt: Date(),
                        location: location,
                        mediaType: .video
                    )
                    capturedMedia.append(media)
                }
            }
            .onChange(of: selectedItems) { _, newItems in
                Task {
                    await loadSelectedMedia(newItems)
                }
            }
        }
    }

    private var mediaCountText: String {
        let photoCount = capturedMedia.filter { $0.mediaType == .photo }.count
        let videoCount = capturedMedia.filter { $0.mediaType == .video }.count

        var parts: [String] = []
        if photoCount > 0 {
            parts.append("\(photoCount) photo\(photoCount == 1 ? "" : "s")")
        }
        if videoCount > 0 {
            parts.append("\(videoCount) video\(videoCount == 1 ? "" : "s")")
        }
        return parts.joined(separator: ", ")
    }

    private func loadSelectedMedia(_ items: [PhotosPickerItem]) async {
        isProcessing = true
        defer { isProcessing = false }

        for item in items {
            // Try to load as video first
            if item.supportedContentTypes.contains(where: { $0.conforms(to: .movie) }) {
                if let videoURL = try? await item.loadTransferable(type: VideoTransferable.self)?.url {
                    let media = CapturedMedia(
                        image: nil,
                        videoURL: videoURL,
                        capturedAt: Date(),
                        location: nil,
                        mediaType: .video
                    )
                    await MainActor.run {
                        capturedMedia.append(media)
                    }
                    continue
                }
            }

            // Load as image
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                let media = CapturedMedia(
                    image: image,
                    videoURL: nil,
                    capturedAt: Date(),
                    location: nil,
                    mediaType: .photo
                )
                await MainActor.run {
                    capturedMedia.append(media)
                }
            }
        }
        await MainActor.run {
            selectedItems.removeAll()
        }
    }

    private func addMedia() {
        for media in capturedMedia {
            onPhotoCaptured(media)
        }
        dismiss()
    }
}

// MARK: - Video Transferable

struct VideoTransferable: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { video in
            SentTransferredFile(video.url)
        } importing: { received in
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mp4")
            try FileManager.default.copyItem(at: received.file, to: tempURL)
            return Self(url: tempURL)
        }
    }
}

// MARK: - Captured Media Model

struct CapturedMedia: Identifiable {
    let id = UUID()
    let image: UIImage?
    let videoURL: URL?
    let capturedAt: Date
    let location: CLLocation?
    let mediaType: MediaType

    var thumbnailImage: UIImage? {
        if let image = image {
            let size = CGSize(width: 150, height: 150)
            let renderer = UIGraphicsImageRenderer(size: size)
            return renderer.image { _ in
                image.draw(in: CGRect(origin: .zero, size: size))
            }
        } else if let videoURL = videoURL {
            return generateVideoThumbnail(from: videoURL)
        }
        return nil
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
            return nil
        }
    }

    var metadata: PhotoMetadata {
        PhotoMetadata(
            capturedAt: capturedAt,
            latitude: location?.coordinate.latitude,
            longitude: location?.coordinate.longitude,
            altitude: location?.altitude
        )
    }

    var isVideo: Bool {
        mediaType == .video
    }
}

// For backwards compatibility
typealias CapturedPhoto = CapturedMedia

struct PhotoMetadata: Codable {
    let capturedAt: Date
    let latitude: Double?
    let longitude: Double?
    let altitude: Double?
}

// MARK: - Media Thumbnail

struct MediaThumbnail: View {
    let media: CapturedMedia
    let onDelete: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if let thumbnail = media.thumbnailImage {
                ZStack {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    // Video indicator
                    if media.isVideo {
                        ZStack {
                            Circle()
                                .fill(.black.opacity(0.5))
                                .frame(width: 36, height: 36)
                            Image(systemName: "play.fill")
                                .foregroundStyle(.white)
                        }
                    }
                }
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 100, height: 100)
                    .overlay {
                        Image(systemName: media.isVideo ? "video" : "photo")
                            .foregroundStyle(.secondary)
                    }
            }

            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.white)
                    .shadow(radius: 2)
            }
            .offset(x: 6, y: -6)
        }
    }
}

// For backwards compatibility
typealias PhotoThumbnail = MediaThumbnail

// MARK: - Camera View

struct CameraView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    let onCapture: (UIImage, CLLocation?) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        let locationManager = CLLocationManager()
        var currentLocation: CLLocation?

        init(_ parent: CameraView) {
            self.parent = parent
            super.init()
            setupLocationManager()
        }

        private func setupLocationManager() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onCapture(image, currentLocation)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

extension CameraView.Coordinator: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
    }
}

// MARK: - Video Camera View

struct VideoCameraView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    let onCapture: (URL, CLLocation?) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.mediaTypes = [UTType.movie.identifier]
        picker.videoQuality = .typeMedium
        picker.videoMaximumDuration = 300 // 5 minutes max
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: VideoCameraView
        let locationManager = CLLocationManager()
        var currentLocation: CLLocation?

        init(_ parent: VideoCameraView) {
            self.parent = parent
            super.init()
            setupLocationManager()
        }

        private func setupLocationManager() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let videoURL = info[.mediaURL] as? URL {
                // Copy to temp location so it persists
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mp4")
                try? FileManager.default.copyItem(at: videoURL, to: tempURL)
                parent.onCapture(tempURL, currentLocation)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

extension VideoCameraView.Coordinator: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
    }
}

// MARK: - Photo Gallery View

struct PhotoGalleryView: View {
    let photos: [EvidencePhoto]
    @State private var selectedMedia: EvidencePhoto?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(photos) { photo in
                    MediaGalleryItem(media: photo) {
                        selectedMedia = photo
                    }
                }
            }
        }
        .sheet(item: $selectedMedia) { media in
            MediaDetailView(media: media)
        }
    }
}

// MARK: - Media Gallery Item

struct MediaGalleryItem: View {
    let media: EvidencePhoto
    let onTap: () -> Void

    var body: some View {
        ZStack {
            if let thumbnail = media.loadThumbnail() {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 80)
                    .overlay {
                        Image(systemName: media.isVideo ? "video" : "photo")
                            .foregroundStyle(.secondary)
                    }
            }

            // Video indicator
            if media.isVideo {
                ZStack {
                    Circle()
                        .fill(.black.opacity(0.5))
                        .frame(width: 30, height: 30)
                    Image(systemName: "play.fill")
                        .font(.caption)
                        .foregroundStyle(.white)
                }
            }
        }
        .onTapGesture(perform: onTap)
    }
}

// MARK: - Media Detail View

struct MediaDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let media: EvidencePhoto

    var body: some View {
        NavigationStack {
            VStack {
                if media.isVideo {
                    VideoPlayerView(media: media)
                } else if let image = media.loadImage() {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    ContentUnavailableView(
                        "Media Unavailable",
                        systemImage: media.isVideo ? "video.slash" : "photo",
                        description: Text("Unable to load this \(media.isVideo ? "video" : "photo")")
                    )
                }
            }
            .navigationTitle(media.isVideo ? "Video" : "Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if let metadata = media.metadata {
                    MediaMetadataBar(metadata: metadata, isVideo: media.isVideo)
                }
            }
        }
    }
}

// For backwards compatibility
typealias PhotoDetailView = MediaDetailView

// MARK: - Video Player View

struct VideoPlayerView: View {
    let media: EvidencePhoto
    @State private var player: AVPlayer?

    var body: some View {
        Group {
            if let url = media.videoURL(), let player = player {
                VideoPlayer(player: player)
                    .onAppear {
                        player.play()
                    }
                    .onDisappear {
                        player.pause()
                    }
            } else {
                ContentUnavailableView(
                    "Video Unavailable",
                    systemImage: "video.slash",
                    description: Text("Unable to load this video")
                )
            }
        }
        .onAppear {
            if let url = media.videoURL() {
                player = AVPlayer(url: url)
            }
        }
    }
}

// MARK: - Media Metadata Bar

struct MediaMetadataBar: View {
    let metadata: PhotoMetadata
    let isVideo: Bool

    var body: some View {
        HStack(spacing: 16) {
            Label {
                Text(metadata.capturedAt, style: .date)
                Text(metadata.capturedAt, style: .time)
            } icon: {
                Image(systemName: "calendar")
            }
            .font(.caption)

            if isVideo {
                Divider()
                    .frame(height: 20)

                Label {
                    Text("Video")
                } icon: {
                    Image(systemName: "video.fill")
                }
                .font(.caption)
            }

            if let lat = metadata.latitude, let lon = metadata.longitude {
                Divider()
                    .frame(height: 20)

                Label {
                    Text(String(format: "%.4f, %.4f", lat, lon))
                } icon: {
                    Image(systemName: "location.fill")
                }
                .font(.caption)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
    }
}

// MARK: - Photo Metadata Bar (backwards compatibility)

struct PhotoMetadataBar: View {
    let metadata: PhotoMetadata

    var body: some View {
        MediaMetadataBar(metadata: metadata, isVideo: false)
    }
}

// MARK: - Preview

#Preview {
    PhotoCaptureView { photo in
        print("Captured: \(photo.id)")
    }
}
