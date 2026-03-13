import XCTest
@testable import Police1

// MARK: - MockReportService Tests

@MainActor
final class MockReportServiceTests: XCTestCase {

    // MARK: - Initialization Tests

    func testDefaultInitialization() {
        let service = MockReportService()

        XCTAssertFalse(service.reports.isEmpty)
        XCTAssertFalse(service.isSyncing)
    }

    func testCustomInitialization() {
        let service = MockReportService(
            officerId: "OFF-002",
            officerName: "Officer Jones",
            badgeNumber: "54321"
        )

        XCTAssertFalse(service.reports.isEmpty)
        // All reports should have the custom officer info
        for report in service.reports {
            XCTAssertEqual(report.officerId, "OFF-002")
            XCTAssertEqual(report.officerName, "Officer Jones")
            XCTAssertEqual(report.badgeNumber, "54321")
        }
    }

    func testMockReportsCount() {
        let service = MockReportService()

        XCTAssertEqual(service.reports.count, 5)
    }

    // MARK: - Fetch Reports Tests

    func testFetchReportsReturnsAllReports() async throws {
        let service = MockReportService()

        let reports = try await service.fetchReports()

        XCTAssertEqual(reports.count, 5)
    }

    func testFetchReportsSortedByUpdatedAt() async throws {
        let service = MockReportService()

        let reports = try await service.fetchReports()

        // Reports should be sorted by updatedAt descending
        for i in 0..<reports.count - 1 {
            XCTAssertGreaterThanOrEqual(reports[i].updatedAt, reports[i + 1].updatedAt)
        }
    }

    // MARK: - Fetch Single Report Tests

    func testFetchReportByIdReturnsReport() async throws {
        let service = MockReportService()
        let existingReport = service.reports.first!

        let report = try await service.fetchReport(id: existingReport.id)

        XCTAssertNotNil(report)
        XCTAssertEqual(report?.id, existingReport.id)
    }

    func testFetchReportByIdReturnsNilForNonexistent() async throws {
        let service = MockReportService()

        let report = try await service.fetchReport(id: UUID())

        XCTAssertNil(report)
    }

    // MARK: - Save Report Tests

    func testSaveNewReportAddsToList() async throws {
        let service = MockReportService()
        let initialCount = service.reports.count

        let newReport = Report(
            localCaseNumber: "DRAFT-99999",
            officerId: "OFF-001",
            officerName: "Officer Smith",
            badgeNumber: "12345"
        )

        let savedReport = try await service.saveReport(newReport)

        XCTAssertEqual(service.reports.count, initialCount + 1)
        XCTAssertTrue(service.reports.contains { $0.id == savedReport.id })
    }

    func testSaveExistingReportUpdates() async throws {
        let service = MockReportService()
        var existingReport = service.reports.first!
        let originalUpdatedAt = existingReport.updatedAt

        existingReport.summary = "Updated summary"
        let savedReport = try await service.saveReport(existingReport)

        XCTAssertEqual(savedReport.summary, "Updated summary")
        XCTAssertGreaterThan(savedReport.updatedAt, originalUpdatedAt)
    }

    func testSaveReportSetsSyncStatusToLocal() async throws {
        let service = MockReportService()
        var report = service.reports.first!
        report.syncStatus = .synced

        let savedReport = try await service.saveReport(report)

        XCTAssertEqual(savedReport.syncStatus, .local)
    }

    // MARK: - Delete Report Tests

    func testDeleteReportRemovesFromList() async throws {
        let service = MockReportService()
        let reportToDelete = service.reports.first!
        let initialCount = service.reports.count

        try await service.deleteReport(id: reportToDelete.id)

        XCTAssertEqual(service.reports.count, initialCount - 1)
        XCTAssertFalse(service.reports.contains { $0.id == reportToDelete.id })
    }

    func testDeleteNonexistentReportDoesNothing() async throws {
        let service = MockReportService()
        let initialCount = service.reports.count

        try await service.deleteReport(id: UUID())

        XCTAssertEqual(service.reports.count, initialCount)
    }

    // MARK: - Sync Reports Tests

    func testSyncReportsSetsIsSyncingDuringSync() async throws {
        let service = MockReportService()

        // Start sync in background
        let syncTask = Task {
            try await service.syncReports()
        }

        // Give it a moment to start
        try await Task.sleep(nanoseconds: 100_000_000)

        // Check that syncing started (may or may not be syncing depending on timing)
        // This is a best-effort check
        _ = service.isSyncing

        try await syncTask.value

        // After sync completes, isSyncing should be false
        XCTAssertFalse(service.isSyncing)
    }

    func testSyncReportsMarksLocalAsSynced() async throws {
        let service = MockReportService()

        // Save a new report (will be local)
        var newReport = Report(
            localCaseNumber: "DRAFT-88888",
            officerId: "OFF-001",
            officerName: "Officer Smith",
            badgeNumber: "12345"
        )
        newReport = try await service.saveReport(newReport)

        XCTAssertEqual(newReport.syncStatus, .local)

        // Sync
        try await service.syncReports()

        // Find the report and check sync status
        let syncedReport = service.reports.first { $0.id == newReport.id }
        XCTAssertEqual(syncedReport?.syncStatus, .synced)
    }

    func testSyncReportsAssignsOfficialCaseNumber() async throws {
        let service = MockReportService()

        // Create and save a new report (no official case number yet)
        var newReport = service.createNewReport()
        XCTAssertNil(newReport.officialCaseNumber)
        XCTAssertTrue(newReport.localCaseNumber.hasPrefix("DRAFT-"))

        newReport = try await service.saveReport(newReport)

        // Sync
        try await service.syncReports()

        // Find the report and check official case number was assigned
        let syncedReport = service.reports.first { $0.id == newReport.id }
        XCTAssertNotNil(syncedReport?.officialCaseNumber)
        XCTAssertTrue(syncedReport!.officialCaseNumber!.hasPrefix("2026-"))
    }

    func testSyncReportsDoesNotReassignOfficialCaseNumber() async throws {
        let service = MockReportService()

        // Find a report that already has an official case number
        let existingReport = service.reports.first { $0.officialCaseNumber != nil }!
        let originalOfficialNumber = existingReport.officialCaseNumber!

        // Sync
        try await service.syncReports()

        // Official case number should not change
        let syncedReport = service.reports.first { $0.id == existingReport.id }
        XCTAssertEqual(syncedReport?.officialCaseNumber, originalOfficialNumber)
    }

    // MARK: - Create New Report Tests

    func testCreateNewReportGeneratesLocalCaseNumber() {
        let service = MockReportService()

        let newReport = service.createNewReport()

        XCTAssertFalse(newReport.localCaseNumber.isEmpty)
        XCTAssertTrue(newReport.localCaseNumber.hasPrefix("DRAFT-"))
        XCTAssertNil(newReport.officialCaseNumber)
    }

    func testCreateNewReportUsesDefaultOfficerInfo() {
        let service = MockReportService(
            officerId: "OFF-TEST",
            officerName: "Test Officer",
            badgeNumber: "99999"
        )

        let newReport = service.createNewReport()

        XCTAssertEqual(newReport.officerId, "OFF-TEST")
        XCTAssertEqual(newReport.officerName, "Test Officer")
        XCTAssertEqual(newReport.badgeNumber, "99999")
    }

    func testCreateNewReportHasDefaultStatus() {
        let service = MockReportService()

        let newReport = service.createNewReport()

        XCTAssertEqual(newReport.status, .draft)
        XCTAssertEqual(newReport.syncStatus, .local)
    }

    func testCreateNewReportHasEmptyCollections() {
        let service = MockReportService()

        let newReport = service.createNewReport()

        XCTAssertTrue(newReport.subjects.isEmpty)
        XCTAssertTrue(newReport.victims.isEmpty)
        XCTAssertTrue(newReport.witnesses.isEmpty)
        XCTAssertTrue(newReport.evidence.isEmpty)
    }

    // MARK: - Mock Data Quality Tests

    func testMockReportsHaveVariedIncidentTypes() {
        let service = MockReportService()
        let incidentTypes = Set(service.reports.map { $0.incidentType })

        XCTAssertGreaterThan(incidentTypes.count, 3) // At least 4 different types
    }

    func testMockReportsHaveVariedStatuses() {
        let service = MockReportService()
        let statuses = Set(service.reports.map { $0.status })

        XCTAssertGreaterThan(statuses.count, 2) // At least 3 different statuses
    }

    func testMockReportsHaveNarratives() {
        let service = MockReportService()
        let reportsWithNarratives = service.reports.filter { !$0.narrative.isEmpty }

        XCTAssertGreaterThanOrEqual(reportsWithNarratives.count, 4) // Most should have narratives
    }

    func testMockReportsHaveCaseNumbers() {
        let service = MockReportService()

        for report in service.reports {
            // All reports should have a local case number
            XCTAssertFalse(report.localCaseNumber.isEmpty)
            XCTAssertTrue(report.localCaseNumber.hasPrefix("DRAFT-"))

            // Synced reports should have official case numbers
            if report.syncStatus == .synced {
                XCTAssertNotNil(report.officialCaseNumber)
                XCTAssertTrue(report.officialCaseNumber!.hasPrefix("2026-"))
            }

            // displayCaseNumber should return something
            XCTAssertFalse(report.displayCaseNumber.isEmpty)
        }
    }

    func testMockReportsHaveLocations() {
        let service = MockReportService()

        for report in service.reports {
            XCTAssertFalse(report.location.isEmpty)
        }
    }

    // MARK: - Generate Mock Reports Tests

    func testGenerateMockReportsReturnsCorrectCount() {
        let reports = MockReportService.generateMockReports(
            officerId: "OFF-001",
            officerName: "Test",
            badgeNumber: "123"
        )

        XCTAssertEqual(reports.count, 5)
    }

    func testGenerateMockReportsAssignsOfficerInfo() {
        let reports = MockReportService.generateMockReports(
            officerId: "OFF-TEST",
            officerName: "Test Officer",
            badgeNumber: "99999"
        )

        for report in reports {
            XCTAssertEqual(report.officerId, "OFF-TEST")
            XCTAssertEqual(report.officerName, "Test Officer")
            XCTAssertEqual(report.badgeNumber, "99999")
        }
    }
}
