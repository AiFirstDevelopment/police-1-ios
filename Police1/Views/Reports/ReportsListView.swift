import SwiftUI

// MARK: - Reports List View

struct ReportsListView: View {
    @StateObject private var reportService = MockReportService()
    @State private var searchText = ""
    @State private var selectedFilter: ReportFilter = .all
    @State private var showingNewReport = false
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            ZStack {
                if isLoading {
                    ProgressView("Loading reports...")
                } else if filteredReports.isEmpty {
                    emptyState
                } else {
                    reportsList
                }
            }
            .navigationTitle("Reports")
            .searchable(text: $searchText, prompt: "Search reports...")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingNewReport = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }

                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Picker("Filter", selection: $selectedFilter) {
                            ForEach(ReportFilter.allCases, id: \.self) { filter in
                                Label(filter.rawValue, systemImage: filter.icon)
                                    .tag(filter)
                            }
                        }
                    } label: {
                        Label("Filter", systemImage: selectedFilter == .all ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                    }
                }
            }
            .refreshable {
                try? await reportService.syncReports()
            }
            .sheet(isPresented: $showingNewReport) {
                ReportEditorView(report: reportService.createNewReport(), reportService: reportService)
            }
            .task {
                _ = try? await reportService.fetchReports()
                isLoading = false
            }
        }
    }

    // MARK: - Reports List

    private var reportsList: some View {
        List {
            // Stats header
            statsHeader
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())

            // Reports grouped by date
            ForEach(groupedReports.keys.sorted().reversed(), id: \.self) { date in
                Section(header: Text(formatSectionDate(date))) {
                    ForEach(groupedReports[date] ?? []) { report in
                        NavigationLink(destination: ReportDetailView(report: report, reportService: reportService)) {
                            ReportRowView(report: report)
                        }
                    }
                    .onDelete { indexSet in
                        deleteReports(at: indexSet, from: date)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Stats Header

    private var statsHeader: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                StatCard(
                    title: "Draft",
                    count: reportService.reports.filter { $0.status == .draft }.count,
                    color: .gray,
                    icon: "pencil",
                    isSelected: selectedFilter == .drafts,
                    action: { selectedFilter = selectedFilter == .drafts ? .all : .drafts }
                )
                StatCard(
                    title: "Pending",
                    count: reportService.reports.filter { $0.status == .pending }.count,
                    color: .orange,
                    icon: "clock",
                    isSelected: selectedFilter == .pending,
                    action: { selectedFilter = selectedFilter == .pending ? .all : .pending }
                )
                StatCard(
                    title: "Approved",
                    count: reportService.reports.filter { $0.status == .approved }.count,
                    color: .green,
                    icon: "checkmark.circle",
                    isSelected: selectedFilter == .approved,
                    action: { selectedFilter = selectedFilter == .approved ? .all : .approved }
                )
                StatCard(
                    title: "Local",
                    count: reportService.reports.filter { $0.syncStatus == .local }.count,
                    color: .blue,
                    icon: "icloud.slash",
                    isSelected: selectedFilter == .needsSync,
                    action: { selectedFilter = selectedFilter == .needsSync ? .all : .needsSync }
                )
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Reports", systemImage: "doc.text")
        } description: {
            if selectedFilter != .all {
                Text("No \(selectedFilter.rawValue.lowercased()) reports found")
            } else if !searchText.isEmpty {
                Text("No reports match '\(searchText)'")
            } else {
                Text("Tap + to create your first report")
            }
        } actions: {
            Button("New Report") {
                showingNewReport = true
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Computed Properties

    private var filteredReports: [Report] {
        var reports = reportService.reports

        // Apply status filter
        switch selectedFilter {
        case .all:
            break
        case .drafts:
            reports = reports.filter { $0.status == .draft }
        case .pending:
            reports = reports.filter { $0.status == .pending }
        case .approved:
            reports = reports.filter { $0.status == .approved }
        case .needsSync:
            reports = reports.filter { $0.syncStatus == .local }
        }

        // Apply search filter
        if !searchText.isEmpty {
            reports = reports.filter { report in
                report.displayCaseNumber.localizedCaseInsensitiveContains(searchText) ||
                report.summary.localizedCaseInsensitiveContains(searchText) ||
                report.location.localizedCaseInsensitiveContains(searchText) ||
                report.incidentType.rawValue.localizedCaseInsensitiveContains(searchText)
            }
        }

        return reports
    }

    private var groupedReports: [Date: [Report]] {
        Dictionary(grouping: filteredReports) { report in
            Calendar.current.startOfDay(for: report.incidentDate)
        }
    }

    // MARK: - Helper Methods

    private func formatSectionDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }

    private func deleteReports(at offsets: IndexSet, from date: Date) {
        guard let reports = groupedReports[date] else { return }
        for index in offsets {
            let report = reports[index]
            Task {
                try? await reportService.deleteReport(id: report.id)
            }
        }
    }
}

// MARK: - Report Filter

enum ReportFilter: String, CaseIterable {
    case all = "All Reports"
    case drafts = "Drafts"
    case pending = "Pending"
    case approved = "Approved"
    case needsSync = "Needs Sync"

    var icon: String {
        switch self {
        case .all: return "doc.text"
        case .drafts: return "pencil"
        case .pending: return "clock"
        case .approved: return "checkmark.circle"
        case .needsSync: return "icloud.slash"
        }
    }
}

// MARK: - Report Row View

struct ReportRowView: View {
    let report: Report

    var body: some View {
        HStack(spacing: 12) {
            // Incident type icon
            ZStack {
                Circle()
                    .fill(incidentColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: report.incidentType.icon)
                    .foregroundStyle(incidentColor)
            }

            // Report info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(report.incidentType.rawValue)
                        .font(.headline)

                    Spacer()

                    // Sync status
                    Image(systemName: report.syncStatus.icon)
                        .font(.caption)
                        .foregroundStyle(report.syncStatus == .synced ? .green : .orange)
                }

                HStack(spacing: 4) {
                    Text(report.displayCaseNumber)
                    if !report.hasOfficialCaseNumber {
                        Image(systemName: "clock")
                            .foregroundStyle(.orange)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                if !report.summary.isEmpty {
                    Text(report.summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                HStack {
                    Label(report.location, systemImage: "location")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Spacer()

                    StatusBadge(status: report.status)
                }
            }
        }
        .padding(.vertical, 4)
    }

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
}

// MARK: - Status Badge

struct StatusBadge: View {
    let status: ReportStatus

    var body: some View {
        Text(status.rawValue)
            .font(.caption2.weight(.medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(statusColor.opacity(0.15))
            .foregroundStyle(statusColor)
            .clipShape(Capsule())
    }

    private var statusColor: Color {
        switch status.color {
        case "gray": return .gray
        case "orange": return .orange
        case "green": return .green
        case "red": return .red
        case "blue": return .blue
        default: return .gray
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let count: Int
    let color: Color
    let icon: String
    var isSelected: Bool = false
    var action: (() -> Void)? = nil

    var body: some View {
        Button(action: { action?() }) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: icon)
                        .font(.caption)
                    Text(title)
                        .font(.caption)
                }
                .foregroundStyle(color)

                Text("\(count)")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.primary)
            }
            .frame(minWidth: 80)
            .padding()
            .background(color.opacity(isSelected ? 0.25 : 0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? color : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    ReportsListView()
}
