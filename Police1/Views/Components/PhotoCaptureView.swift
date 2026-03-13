import SwiftUI
import PhotosUI
import CoreLocation

// MARK: - Photo Capture View

struct PhotoCaptureView: View {
    @Environment(\.dismiss) private var dismiss
    let onPhotoCaptured: (CapturedPhoto) -> Void

    @State private var showingCamera = false
    @State private var showingPhotoLibrary = false
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var capturedPhotos: [CapturedPhoto] = []
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

                    Text("Add Photos")
                        .font(.title2.weight(.bold))

                    Text("Capture evidence or select from library")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 20)

                // Capture options
                VStack(spacing: 16) {
                    // Camera button
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
                                Text("Use camera to capture evidence")
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

                    // Photo library button
                    PhotosPicker(
                        selection: $selectedItems,
                        maxSelectionCount: 10,
                        matching: .images
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
                                Text("Photo Library")
                                    .font(.body.weight(.semibold))
                                Text("Select existing photos")
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

                // Selected photos preview
                if !capturedPhotos.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Selected Photos")
                                .font(.headline)
                            Spacer()
                            Text("\(capturedPhotos.count) photo\(capturedPhotos.count == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(capturedPhotos) { photo in
                                    PhotoThumbnail(photo: photo) {
                                        capturedPhotos.removeAll { $0.id == photo.id }
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
                    ProgressView("Processing photos...")
                        .padding()
                }

                // Add button
                if !capturedPhotos.isEmpty {
                    Button(action: addPhotos) {
                        Text("Add \(capturedPhotos.count) Photo\(capturedPhotos.count == 1 ? "" : "s")")
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
            .navigationTitle("Add Photos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .fullScreenCover(isPresented: $showingCamera) {
                CameraView { image, location in
                    let photo = CapturedPhoto(
                        image: image,
                        capturedAt: Date(),
                        location: location
                    )
                    capturedPhotos.append(photo)
                }
            }
            .onChange(of: selectedItems) { _, newItems in
                Task {
                    await loadSelectedPhotos(newItems)
                }
            }
        }
    }

    private func loadSelectedPhotos(_ items: [PhotosPickerItem]) async {
        isProcessing = true
        defer { isProcessing = false }

        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                let photo = CapturedPhoto(
                    image: image,
                    capturedAt: Date(),
                    location: nil
                )
                await MainActor.run {
                    capturedPhotos.append(photo)
                }
            }
        }
        await MainActor.run {
            selectedItems.removeAll()
        }
    }

    private func addPhotos() {
        for photo in capturedPhotos {
            onPhotoCaptured(photo)
        }
        dismiss()
    }
}

// MARK: - Captured Photo Model

struct CapturedPhoto: Identifiable {
    let id = UUID()
    let image: UIImage
    let capturedAt: Date
    let location: CLLocation?

    var thumbnailImage: UIImage {
        let size = CGSize(width: 150, height: 150)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
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
}

struct PhotoMetadata: Codable {
    let capturedAt: Date
    let latitude: Double?
    let longitude: Double?
    let altitude: Double?
}

// MARK: - Photo Thumbnail

struct PhotoThumbnail: View {
    let photo: CapturedPhoto
    let onDelete: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: photo.thumbnailImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 8))

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

// MARK: - Photo Gallery View

struct PhotoGalleryView: View {
    let photos: [EvidencePhoto]
    @State private var selectedPhoto: EvidencePhoto?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(photos) { photo in
                    if let image = photo.loadImage() {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .onTapGesture {
                                selectedPhoto = photo
                            }
                    }
                }
            }
        }
        .sheet(item: $selectedPhoto) { photo in
            PhotoDetailView(photo: photo)
        }
    }
}

// MARK: - Photo Detail View

struct PhotoDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let photo: EvidencePhoto

    var body: some View {
        NavigationStack {
            VStack {
                if let image = photo.loadImage() {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    ContentUnavailableView(
                        "Photo Unavailable",
                        systemImage: "photo",
                        description: Text("Unable to load this photo")
                    )
                }
            }
            .navigationTitle("Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if let metadata = photo.metadata {
                    PhotoMetadataBar(metadata: metadata)
                }
            }
        }
    }
}

// MARK: - Photo Metadata Bar

struct PhotoMetadataBar: View {
    let metadata: PhotoMetadata

    var body: some View {
        HStack(spacing: 16) {
            Label {
                Text(metadata.capturedAt, style: .date)
                Text(metadata.capturedAt, style: .time)
            } icon: {
                Image(systemName: "calendar")
            }
            .font(.caption)

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

// MARK: - Preview

#Preview {
    PhotoCaptureView { photo in
        print("Captured: \(photo.id)")
    }
}
