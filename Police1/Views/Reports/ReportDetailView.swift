import SwiftUI

// MARK: - Report Detail View

enum ReportDetailSheet: Identifiable {
    case editor
    case share(Data)

    var id: String {
        switch self {
        case .editor: return "editor"
        case .share: return "share"
        }
    }
}

struct ReportDetailView: View {
    @State private var report: Report
    let reportService: MockReportService

    @State private var activeSheet: ReportDetailSheet?
    @State private var showingSubmitAlert = false
    @Environment(\.dismiss) private var dismiss

    init(report: Report, reportService: MockReportService) {
        self._report = State(initialValue: report)
        self.reportService = reportService
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header card
                headerCard

                // Quick info
                quickInfoSection

                // Narrative
                if !report.narrative.isEmpty {
                    narrativeSection
                }

                // Involved parties
                if !report.victims.isEmpty || !report.subjects.isEmpty || !report.witnesses.isEmpty {
                    partiesSection
                }

                // Evidence
                if !report.evidence.isEmpty {
                    evidenceSection
                }

                // Officer info
                officerSection

                // Metadata
                metadataSection
            }
            .padding()
        }
        .navigationTitle("Case \(report.displayCaseNumber)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        activeSheet = .editor
                    } label: {
                        Label("Edit Report", systemImage: "pencil")
                    }

                    Button {
                        if let data = generatePDF() {
                            activeSheet = .share(data)
                        }
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }

                    if report.status == .draft {
                        Divider()
                        Button {
                            showingSubmitAlert = true
                        } label: {
                            Label("Submit for Review", systemImage: "paperplane")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .editor:
                ReportEditorView(report: report, reportService: reportService)
            case .share(let data):
                ShareSheet(items: [data])
            }
        }
        .alert("Submit for Review", isPresented: $showingSubmitAlert) {
            Button("Submit", role: .none) { performSubmit() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This report will be sent to your supervisor for review. You can still make edits until it's approved.")
        }
    }

    // MARK: - Header Card

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(incidentColor.opacity(0.15))
                        .frame(width: 50, height: 50)
                    Image(systemName: report.incidentType.icon)
                        .font(.title2)
                        .foregroundStyle(incidentColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(report.incidentType.rawValue)
                        .font(.title2.weight(.bold))
                    HStack(spacing: 4) {
                        Text(report.displayCaseNumber)
                        if !report.hasOfficialCaseNumber {
                            Image(systemName: "clock")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    StatusBadge(status: report.status)

                    HStack(spacing: 4) {
                        Image(systemName: report.syncStatus.icon)
                        Text(report.syncStatus.rawValue)
                    }
                    .font(.caption)
                    .foregroundStyle(report.syncStatus == .synced ? .green : .orange)
                }
            }

            if !report.summary.isEmpty {
                Text(report.summary)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 10)
    }

    // MARK: - Quick Info Section

    private var quickInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Incident Details")
                .font(.headline)

            VStack(spacing: 8) {
                InfoRow(icon: "calendar", label: "Date & Time", value: formattedDate)
                InfoRow(icon: "location", label: "Location", value: report.location)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Narrative Section

    private var narrativeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Narrative")
                .font(.headline)

            Text(report.narrative)
                .font(.body)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Parties Section

    private var partiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Involved Parties")
                .font(.headline)

            VStack(spacing: 8) {
                if !report.subjects.isEmpty {
                    ForEach(report.subjects) { person in
                        PersonRow(person: person, role: "Subject")
                    }
                }

                if !report.victims.isEmpty {
                    ForEach(report.victims) { person in
                        PersonRow(person: person, role: "Victim")
                    }
                }

                if !report.witnesses.isEmpty {
                    ForEach(report.witnesses) { person in
                        PersonRow(person: person, role: "Witness")
                    }
                }
            }
        }
    }

    // MARK: - Evidence Section

    private var evidenceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Evidence")
                .font(.headline)

            ForEach(report.evidence) { item in
                EvidenceRow(item: item)
            }
        }
    }

    // MARK: - Officer Section

    private var officerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reporting Officer")
                .font(.headline)

            HStack {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: "person.fill")
                        .foregroundStyle(.blue)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(report.officerName)
                        .font(.body.weight(.medium))
                    Text("Badge #\(report.badgeNumber)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Metadata Section

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Report Info")
                .font(.headline)

            VStack(spacing: 8) {
                InfoRow(icon: "plus.circle", label: "Created", value: formatDateTime(report.createdAt))
                InfoRow(icon: "pencil.circle", label: "Last Updated", value: formatDateTime(report.updatedAt))
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Computed Properties

    private var incidentColor: Color {
        switch report.incidentType.color {
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "blue": return .blue
        case "purple": return .purple
        default: return .gray
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: report.incidentDate)
    }

    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    // MARK: - Actions

    private func performSubmit() {
        Task {
            var updatedReport = report
            updatedReport.status = .pending
            if let saved = try? await reportService.saveReport(updatedReport) {
                report = saved
            }
        }
    }

    private func generatePDF() -> Data? {
        let pageWidth: CGFloat = 612
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 50

        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))

        let data = pdfRenderer.pdfData { context in
            context.beginPage()

            var yPosition: CGFloat = margin

            // Title
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 24),
                .foregroundColor: UIColor.black
            ]
            let title = "Police Incident Report"
            title.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: titleAttributes)
            yPosition += 40

            // Case Number
            let headerAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 14),
                .foregroundColor: UIColor.darkGray
            ]
            let bodyAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.black
            ]

            "Case Number: \(report.displayCaseNumber)".draw(at: CGPoint(x: margin, y: yPosition), withAttributes: headerAttributes)
            yPosition += 25

            // Incident Type
            "Incident Type: \(report.incidentType.rawValue)".draw(at: CGPoint(x: margin, y: yPosition), withAttributes: bodyAttributes)
            yPosition += 20

            // Status
            "Status: \(report.status.rawValue)".draw(at: CGPoint(x: margin, y: yPosition), withAttributes: bodyAttributes)
            yPosition += 20

            // Date
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .long
            dateFormatter.timeStyle = .short
            "Date: \(dateFormatter.string(from: report.incidentDate))".draw(at: CGPoint(x: margin, y: yPosition), withAttributes: bodyAttributes)
            yPosition += 20

            // Location
            "Location: \(report.location)".draw(at: CGPoint(x: margin, y: yPosition), withAttributes: bodyAttributes)
            yPosition += 30

            // Summary
            if !report.summary.isEmpty {
                "Summary:".draw(at: CGPoint(x: margin, y: yPosition), withAttributes: headerAttributes)
                yPosition += 20
                let summaryRect = CGRect(x: margin, y: yPosition, width: pageWidth - (margin * 2), height: 60)
                report.summary.draw(in: summaryRect, withAttributes: bodyAttributes)
                yPosition += 70
            }

            // Narrative
            if !report.narrative.isEmpty {
                "Narrative:".draw(at: CGPoint(x: margin, y: yPosition), withAttributes: headerAttributes)
                yPosition += 20
                let narrativeRect = CGRect(x: margin, y: yPosition, width: pageWidth - (margin * 2), height: 300)
                report.narrative.draw(in: narrativeRect, withAttributes: bodyAttributes)
                yPosition += 310
            }

            // Officer Info
            yPosition = pageHeight - 100
            "Reporting Officer: \(report.officerName)".draw(at: CGPoint(x: margin, y: yPosition), withAttributes: bodyAttributes)
            yPosition += 20
            "Badge Number: \(report.badgeNumber)".draw(at: CGPoint(x: margin, y: yPosition), withAttributes: bodyAttributes)
            yPosition += 20

            let generatedDate = "Generated: \(dateFormatter.string(from: Date()))"
            generatedDate.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: bodyAttributes)

            // Evidence Photos - add on new pages
            let allPhotos = report.evidence.flatMap { $0.photos }
            if !allPhotos.isEmpty {
                context.beginPage()
                yPosition = margin

                "Evidence Photos".draw(at: CGPoint(x: margin, y: yPosition), withAttributes: titleAttributes)
                yPosition += 50

                let photoSize: CGFloat = 200
                let photosPerRow = 2
                var photoIndex = 0

                for photo in allPhotos {
                    if let image = photo.loadImage() {
                        let col = photoIndex % photosPerRow
                        let row = photoIndex / photosPerRow

                        let xPos = margin + CGFloat(col) * (photoSize + 20)
                        let yPos = yPosition + CGFloat(row) * (photoSize + 40)

                        // Check if we need a new page
                        if yPos + photoSize > pageHeight - margin {
                            context.beginPage()
                            yPosition = margin
                            photoIndex = 0
                            continue
                        }

                        let photoRect = CGRect(x: xPos, y: yPos, width: photoSize, height: photoSize)
                        image.draw(in: photoRect)

                        // Draw caption
                        let captionY = yPos + photoSize + 5
                        "Photo \(photoIndex + 1)".draw(at: CGPoint(x: xPos, y: captionY), withAttributes: bodyAttributes)

                        photoIndex += 1
                    }
                }
            }
        }

        return data
    }
}

// MARK: - Info Row

struct InfoRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 24)
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
        }
    }
}

// MARK: - Person Row

struct PersonRow: View {
    let person: Person
    let role: String

    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(roleColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: "person.fill")
                    .foregroundStyle(roleColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(person.fullName)
                    .font(.body.weight(.medium))
                Text(role)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let phone = person.phone {
                Button(action: {}) {
                    Image(systemName: "phone.fill")
                        .foregroundStyle(.blue)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var roleColor: Color {
        switch role {
        case "Subject": return .red
        case "Victim": return .orange
        case "Witness": return .blue
        default: return .gray
        }
    }
}

// MARK: - Evidence Row

struct EvidenceRow: View {
    let item: EvidenceItem
    @State private var showingPhotos = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.purple.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: item.type.icon)
                        .foregroundStyle(.purple)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(item.type.rawValue)
                            .font(.body.weight(.medium))

                        if item.hasPhotos {
                            HStack(spacing: 2) {
                                Image(systemName: "photo.fill")
                                Text("\(item.photoCount)")
                            }
                            .font(.caption2)
                            .foregroundStyle(.blue)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Capsule())
                        }
                    }

                    Text(item.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if item.hasPhotos {
                    Button(action: { showingPhotos.toggle() }) {
                        Image(systemName: showingPhotos ? "chevron.up" : "chevron.down")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Photo gallery
            if showingPhotos && !item.photos.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(item.photos) { photo in
                            EvidencePhotoView(photo: photo)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Evidence Photo View

struct EvidencePhotoView: View {
    let photo: EvidencePhoto
    @State private var showingFullScreen = false

    var body: some View {
        Group {
            if let thumbnail = photo.loadThumbnail() {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .onTapGesture {
                        showingFullScreen = true
                    }
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 100, height: 100)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    }
            }
        }
        .sheet(isPresented: $showingFullScreen) {
            PhotoDetailView(photo: photo)
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ReportDetailView(
            report: MockReportService.generateMockReports(
                officerId: "OFF-001",
                officerName: "Officer Smith",
                badgeNumber: "12345"
            ).first!,
            reportService: MockReportService()
        )
    }
}
