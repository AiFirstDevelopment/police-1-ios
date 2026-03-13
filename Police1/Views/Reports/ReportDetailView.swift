import SwiftUI

// MARK: - Report Detail View

struct ReportDetailView: View {
    let report: Report
    let reportService: MockReportService

    @State private var showingEditor = false
    @Environment(\.dismiss) private var dismiss

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
        .navigationTitle("Case \(report.caseNumber)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(action: { showingEditor = true }) {
                        Label("Edit Report", systemImage: "pencil")
                    }

                    Button(action: exportPDF) {
                        Label("Export PDF", systemImage: "arrow.down.doc")
                    }

                    Button(action: shareReport) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }

                    if report.status == .draft {
                        Divider()
                        Button(action: submitReport) {
                            Label("Submit for Review", systemImage: "paperplane")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditor) {
            ReportEditorView(report: report, reportService: reportService)
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
                    Text(report.caseNumber)
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

    private func exportPDF() {
        // TODO: Implement PDF export
    }

    private func shareReport() {
        // TODO: Implement share
    }

    private func submitReport() {
        // TODO: Implement submit for review
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

    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: item.type.icon)
                    .foregroundStyle(.purple)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.type.rawValue)
                    .font(.body.weight(.medium))
                Text(item.description)
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
