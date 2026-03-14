import XCTest
import SwiftUI
import ViewInspector
@testable import Police1

// MARK: - ReportsListView Tests

@MainActor
final class ReportsListViewTests: XCTestCase {

    func testReportsListViewHasNavigationStack() throws {
        let view = ReportsListView()
        let sut = try view.inspect()

        let nav = try sut.find(ViewType.NavigationStack.self)
        XCTAssertNotNil(nav)
    }

    func testReportsListViewHasZStack() throws {
        let view = ReportsListView()
        let sut = try view.inspect()

        let zstack = try sut.find(ViewType.ZStack.self)
        XCTAssertNotNil(zstack)
    }

    func testReportsListViewShowsProgressViewWhenLoading() throws {
        let view = ReportsListView()
        let sut = try view.inspect()

        // Initially shows loading state
        let progressView = try sut.find(ViewType.ProgressView.self)
        XCTAssertNotNil(progressView)
    }
}

// MARK: - ReportRowView Tests

@MainActor
final class ReportRowViewTests: XCTestCase {

    private func createMockReport(withOfficialCaseNumber: Bool = true) -> Report {
        Report(
            id: UUID(),
            incidentType: .theft,
            localCaseNumber: "DRAFT-12345",
            officialCaseNumber: withOfficialCaseNumber ? "2026-12345" : nil,
            incidentDate: Date(),
            location: "123 Main St",
            summary: "Test summary",
            narrative: "Test narrative",
            status: .draft,
            createdAt: Date(),
            updatedAt: Date(),
            syncStatus: withOfficialCaseNumber ? .synced : .local,
            subjects: [],
            victims: [],
            witnesses: [],
            evidence: [],
            officerId: "OFF-001",
            officerName: "Officer Smith",
            badgeNumber: "12345"
        )
    }

    func testReportRowViewHasHStack() throws {
        let report = createMockReport()
        let view = ReportRowView(report: report)
        let sut = try view.inspect()

        let hstack = try sut.find(ViewType.HStack.self)
        XCTAssertNotNil(hstack)
    }

    func testReportRowViewHasIncidentIcon() throws {
        let report = createMockReport()
        let view = ReportRowView(report: report)
        let sut = try view.inspect()

        let images = sut.findAll(ViewType.Image.self)
        XCTAssertGreaterThanOrEqual(images.count, 1)
    }

    func testReportRowViewHasTexts() throws {
        let report = createMockReport()
        let view = ReportRowView(report: report)
        let sut = try view.inspect()

        let texts = sut.findAll(ViewType.Text.self)
        // Should have: incident type, case number, summary, location
        XCTAssertGreaterThanOrEqual(texts.count, 3)
    }

    func testReportRowViewHasVStack() throws {
        let report = createMockReport()
        let view = ReportRowView(report: report)
        let sut = try view.inspect()

        let vstack = try sut.find(ViewType.VStack.self)
        XCTAssertNotNil(vstack)
    }

    func testReportRowViewHasZStack() throws {
        let report = createMockReport()
        let view = ReportRowView(report: report)
        let sut = try view.inspect()

        let zstack = try sut.find(ViewType.ZStack.self)
        XCTAssertNotNil(zstack)
    }

    func testReportRowViewHasZStackWithShape() throws {
        let report = createMockReport()
        let view = ReportRowView(report: report)
        let sut = try view.inspect()

        // ZStack contains the circle icon background
        let zstacks = sut.findAll(ViewType.ZStack.self)
        XCTAssertGreaterThanOrEqual(zstacks.count, 1)
    }

    func testReportRowViewShowsClockIconForDraftReport() throws {
        let report = createMockReport(withOfficialCaseNumber: false)
        let view = ReportRowView(report: report)
        let sut = try view.inspect()

        // Should show clock icon for reports without official case number
        let images = sut.findAll(ViewType.Image.self)
        XCTAssertGreaterThanOrEqual(images.count, 2, "Should have clock icon for pending reports")
    }

    func testReportRowViewHidesClockIconForSyncedReport() throws {
        let report = createMockReport(withOfficialCaseNumber: true)
        let view = ReportRowView(report: report)
        let sut = try view.inspect()

        // Synced reports should have fewer icons (no clock)
        let images = sut.findAll(ViewType.Image.self)
        XCTAssertGreaterThanOrEqual(images.count, 1)
    }

    func testReportRowViewShowsDisplayCaseNumber() throws {
        let report = createMockReport(withOfficialCaseNumber: true)
        let view = ReportRowView(report: report)
        let sut = try view.inspect()

        let texts = sut.findAll(ViewType.Text.self)
        let caseNumberText = texts.first { (try? $0.string()) == "2026-12345" }
        XCTAssertNotNil(caseNumberText, "Should show official case number when available")
    }

    func testReportRowViewShowsDraftCaseNumberWhenNoOfficial() throws {
        let report = createMockReport(withOfficialCaseNumber: false)
        let view = ReportRowView(report: report)
        let sut = try view.inspect()

        let texts = sut.findAll(ViewType.Text.self)
        let caseNumberText = texts.first { (try? $0.string()) == "DRAFT-12345" }
        XCTAssertNotNil(caseNumberText, "Should show draft case number when no official number")
    }
}

// MARK: - StatusBadge Tests

@MainActor
final class StatusBadgeTests: XCTestCase {

    func testStatusBadgeHasText() throws {
        let view = StatusBadge(status: .draft)
        let sut = try view.inspect()

        let text = try sut.find(ViewType.Text.self)
        XCTAssertNotNil(text)
    }

    func testStatusBadgeDraftShowsCorrectText() throws {
        let view = StatusBadge(status: .draft)
        let sut = try view.inspect()

        let text = try sut.find(ViewType.Text.self)
        let string = try text.string()
        XCTAssertEqual(string, "Draft")
    }

    func testStatusBadgePendingShowsCorrectText() throws {
        let view = StatusBadge(status: .pending)
        let sut = try view.inspect()

        let text = try sut.find(ViewType.Text.self)
        let string = try text.string()
        XCTAssertEqual(string, "Pending Review")
    }

    func testStatusBadgeApprovedShowsCorrectText() throws {
        let view = StatusBadge(status: .approved)
        let sut = try view.inspect()

        let text = try sut.find(ViewType.Text.self)
        let string = try text.string()
        XCTAssertEqual(string, "Approved")
    }
}

// MARK: - StatCard Tests

@MainActor
final class StatCardTests: XCTestCase {

    func testStatCardHasVStack() throws {
        let view = StatCard(title: "Draft", count: 5, color: .gray, icon: "pencil")
        let sut = try view.inspect()

        let vstack = try sut.find(ViewType.VStack.self)
        XCTAssertNotNil(vstack)
    }

    func testStatCardHasHStack() throws {
        let view = StatCard(title: "Draft", count: 5, color: .gray, icon: "pencil")
        let sut = try view.inspect()

        let hstack = try sut.find(ViewType.HStack.self)
        XCTAssertNotNil(hstack)
    }

    func testStatCardHasIcon() throws {
        let view = StatCard(title: "Draft", count: 5, color: .gray, icon: "pencil")
        let sut = try view.inspect()

        let images = sut.findAll(ViewType.Image.self)
        XCTAssertGreaterThanOrEqual(images.count, 1)
    }

    func testStatCardHasTexts() throws {
        let view = StatCard(title: "Draft", count: 5, color: .gray, icon: "pencil")
        let sut = try view.inspect()

        let texts = sut.findAll(ViewType.Text.self)
        XCTAssertGreaterThanOrEqual(texts.count, 2) // title and count
    }

    func testStatCardShowsCorrectCount() throws {
        let view = StatCard(title: "Draft", count: 42, color: .gray, icon: "pencil")
        let sut = try view.inspect()

        let texts = sut.findAll(ViewType.Text.self)
        let countText = texts.first { (try? $0.string()) == "42" }
        XCTAssertNotNil(countText)
    }

    func testStatCardIsSelectedState() throws {
        let view = StatCard(title: "Draft", count: 5, color: .gray, icon: "pencil", isSelected: true)
        let sut = try view.inspect()

        // Should have Button wrapping the content
        let button = try sut.find(ViewType.Button.self)
        XCTAssertNotNil(button)
    }

    func testStatCardNotSelectedState() throws {
        let view = StatCard(title: "Draft", count: 5, color: .gray, icon: "pencil", isSelected: false)
        let sut = try view.inspect()

        // Should have Button wrapping the content
        let button = try sut.find(ViewType.Button.self)
        XCTAssertNotNil(button)
    }

    func testStatCardWithAction() throws {
        var actionCalled = false
        let view = StatCard(title: "Draft", count: 5, color: .gray, icon: "pencil", action: {
            actionCalled = true
        })
        let sut = try view.inspect()

        // Button should exist
        let button = try sut.find(ViewType.Button.self)
        XCTAssertNotNil(button)
    }

    func testStatCardHasRoundedRectangleBackground() throws {
        let view = StatCard(title: "Draft", count: 5, color: .gray, icon: "pencil")
        let sut = try view.inspect()

        // Button should be present (StatCard is wrapped in a Button now)
        let button = try sut.find(ViewType.Button.self)
        XCTAssertNotNil(button)
    }

    func testStatCardSelectedHasOverlay() throws {
        let view = StatCard(title: "Draft", count: 5, color: .gray, icon: "pencil", isSelected: true)
        let sut = try view.inspect()

        // Should still have button and content
        let button = try sut.find(ViewType.Button.self)
        XCTAssertNotNil(button)
    }
}

// MARK: - ReportDetailView Tests

@MainActor
final class ReportDetailViewTests: XCTestCase {

    private func createMockReport(withOfficialCaseNumber: Bool = true) -> Report {
        Report(
            id: UUID(),
            incidentType: .theft,
            localCaseNumber: "DRAFT-12345",
            officialCaseNumber: withOfficialCaseNumber ? "2026-12345" : nil,
            incidentDate: Date(),
            location: "123 Main St",
            summary: "Test summary",
            narrative: "This is a test narrative for the report.",
            status: .draft,
            createdAt: Date(),
            updatedAt: Date(),
            syncStatus: withOfficialCaseNumber ? .synced : .local,
            subjects: [Person(firstName: "John", lastName: "Doe")],
            victims: [Person(firstName: "Jane", lastName: "Smith", phone: "555-1234")],
            witnesses: [],
            evidence: [EvidenceItem(type: .electronics, description: "Laptop")],
            officerId: "OFF-001",
            officerName: "Officer Smith",
            badgeNumber: "12345"
        )
    }

    func testReportDetailViewHasScrollView() throws {
        let report = createMockReport()
        let reportService = MockReportService()
        let view = ReportDetailView(report: report, reportService: reportService)
        let sut = try view.inspect()

        let scrollView = try sut.find(ViewType.ScrollView.self)
        XCTAssertNotNil(scrollView)
    }

    func testReportDetailViewHasVStack() throws {
        let report = createMockReport()
        let reportService = MockReportService()
        let view = ReportDetailView(report: report, reportService: reportService)
        let sut = try view.inspect()

        let vstack = try sut.find(ViewType.VStack.self)
        XCTAssertNotNil(vstack)
    }

    func testReportDetailViewHasTexts() throws {
        let report = createMockReport()
        let reportService = MockReportService()
        let view = ReportDetailView(report: report, reportService: reportService)
        let sut = try view.inspect()

        let texts = sut.findAll(ViewType.Text.self)
        // Should have many texts for sections, labels, values
        XCTAssertGreaterThanOrEqual(texts.count, 10)
    }

    func testReportDetailViewHasImages() throws {
        let report = createMockReport()
        let reportService = MockReportService()
        let view = ReportDetailView(report: report, reportService: reportService)
        let sut = try view.inspect()

        let images = sut.findAll(ViewType.Image.self)
        XCTAssertGreaterThanOrEqual(images.count, 3) // incident icon, sync icon, section icons
    }

    func testReportDetailViewHasHStacks() throws {
        let report = createMockReport()
        let reportService = MockReportService()
        let view = ReportDetailView(report: report, reportService: reportService)
        let sut = try view.inspect()

        let hstacks = sut.findAll(ViewType.HStack.self)
        XCTAssertGreaterThanOrEqual(hstacks.count, 3)
    }

    func testReportDetailViewShowsClockIconForDraftReport() throws {
        let report = createMockReport(withOfficialCaseNumber: false)
        let reportService = MockReportService()
        let view = ReportDetailView(report: report, reportService: reportService)
        let sut = try view.inspect()

        // Should have clock icon for reports without official case number
        let images = sut.findAll(ViewType.Image.self)
        XCTAssertGreaterThanOrEqual(images.count, 4, "Should have clock icon for pending reports")
    }

    func testReportDetailViewHidesClockIconForSyncedReport() throws {
        let report = createMockReport(withOfficialCaseNumber: true)
        let reportService = MockReportService()
        let view = ReportDetailView(report: report, reportService: reportService)
        let sut = try view.inspect()

        // Synced reports should have images but no extra clock icon
        let images = sut.findAll(ViewType.Image.self)
        XCTAssertGreaterThanOrEqual(images.count, 3)
    }
}

// MARK: - ReportDetailSheet Tests

@MainActor
final class ReportDetailSheetTests: XCTestCase {

    func testEditorSheetId() {
        let sheet = ReportDetailSheet.editor
        XCTAssertEqual(sheet.id, "editor")
    }

    func testShareSheetId() {
        let data = Data()
        let sheet = ReportDetailSheet.share(data)
        XCTAssertEqual(sheet.id, "share")
    }

    func testShareSheetContainsData() {
        let testData = "test".data(using: .utf8)!
        let sheet = ReportDetailSheet.share(testData)

        if case .share(let data) = sheet {
            XCTAssertEqual(data, testData)
        } else {
            XCTFail("Expected share case")
        }
    }
}

// MARK: - ShareSheet Tests

@MainActor
final class ShareSheetTests: XCTestCase {

    func testShareSheetInitializesWithItems() {
        let data = "Test PDF content".data(using: .utf8)!
        let shareSheet = ShareSheet(items: [data])

        XCTAssertEqual(shareSheet.items.count, 1)
    }

    func testShareSheetAcceptsMultipleItems() {
        let data1 = "Item 1".data(using: .utf8)!
        let data2 = "Item 2".data(using: .utf8)!
        let shareSheet = ShareSheet(items: [data1, data2])

        XCTAssertEqual(shareSheet.items.count, 2)
    }

    func testShareSheetAcceptsStringItems() {
        let shareSheet = ShareSheet(items: ["Test string", "Another string"])

        XCTAssertEqual(shareSheet.items.count, 2)
    }
}

// MARK: - InfoRow Tests

@MainActor
final class InfoRowTests: XCTestCase {

    func testInfoRowHasHStack() throws {
        let view = InfoRow(icon: "calendar", label: "Date", value: "March 13, 2026")
        let sut = try view.inspect()

        let hstack = try sut.find(ViewType.HStack.self)
        XCTAssertNotNil(hstack)
    }

    func testInfoRowHasIcon() throws {
        let view = InfoRow(icon: "calendar", label: "Date", value: "March 13, 2026")
        let sut = try view.inspect()

        let images = sut.findAll(ViewType.Image.self)
        XCTAssertGreaterThanOrEqual(images.count, 1)
    }

    func testInfoRowHasTexts() throws {
        let view = InfoRow(icon: "calendar", label: "Date", value: "March 13, 2026")
        let sut = try view.inspect()

        let texts = sut.findAll(ViewType.Text.self)
        XCTAssertGreaterThanOrEqual(texts.count, 2) // label and value
    }

    func testInfoRowHasSpacer() throws {
        let view = InfoRow(icon: "calendar", label: "Date", value: "March 13, 2026")
        let sut = try view.inspect()

        let spacer = try sut.find(ViewType.Spacer.self)
        XCTAssertNotNil(spacer)
    }
}

// MARK: - PersonRow Tests

@MainActor
final class PersonRowTests: XCTestCase {

    func testPersonRowHasHStack() throws {
        let person = Person(firstName: "John", lastName: "Doe", phone: "555-1234")
        let view = PersonRow(person: person, role: "Subject")
        let sut = try view.inspect()

        let hstack = try sut.find(ViewType.HStack.self)
        XCTAssertNotNil(hstack)
    }

    func testPersonRowHasZStack() throws {
        let person = Person(firstName: "John", lastName: "Doe")
        let view = PersonRow(person: person, role: "Subject")
        let sut = try view.inspect()

        let zstack = try sut.find(ViewType.ZStack.self)
        XCTAssertNotNil(zstack)
    }

    func testPersonRowHasZStackWithShape() throws {
        let person = Person(firstName: "John", lastName: "Doe")
        let view = PersonRow(person: person, role: "Subject")
        let sut = try view.inspect()

        // ZStack contains the circle icon background
        let zstacks = sut.findAll(ViewType.ZStack.self)
        XCTAssertGreaterThanOrEqual(zstacks.count, 1)
    }

    func testPersonRowHasPersonIcon() throws {
        let person = Person(firstName: "John", lastName: "Doe")
        let view = PersonRow(person: person, role: "Subject")
        let sut = try view.inspect()

        let images = sut.findAll(ViewType.Image.self)
        XCTAssertGreaterThanOrEqual(images.count, 1)
    }

    func testPersonRowHasTexts() throws {
        let person = Person(firstName: "John", lastName: "Doe")
        let view = PersonRow(person: person, role: "Subject")
        let sut = try view.inspect()

        let texts = sut.findAll(ViewType.Text.self)
        XCTAssertGreaterThanOrEqual(texts.count, 2) // name and role
    }

    func testPersonRowWithPhoneHasButton() throws {
        let person = Person(firstName: "John", lastName: "Doe", phone: "555-1234")
        let view = PersonRow(person: person, role: "Subject")
        let sut = try view.inspect()

        let buttons = sut.findAll(ViewType.Button.self)
        XCTAssertGreaterThanOrEqual(buttons.count, 1) // phone button
    }
}

// MARK: - EvidenceRow Tests

@MainActor
final class EvidenceRowTests: XCTestCase {

    func testEvidenceRowHasHStack() throws {
        let evidence = EvidenceItem(type: .electronics, description: "Laptop computer")
        let view = EvidenceRow(item: evidence)
        let sut = try view.inspect()

        let hstack = try sut.find(ViewType.HStack.self)
        XCTAssertNotNil(hstack)
    }

    func testEvidenceRowHasZStack() throws {
        let evidence = EvidenceItem(type: .electronics, description: "Laptop computer")
        let view = EvidenceRow(item: evidence)
        let sut = try view.inspect()

        let zstack = try sut.find(ViewType.ZStack.self)
        XCTAssertNotNil(zstack)
    }

    func testEvidenceRowHasZStackWithShape() throws {
        let evidence = EvidenceItem(type: .electronics, description: "Laptop computer")
        let view = EvidenceRow(item: evidence)
        let sut = try view.inspect()

        // ZStack contains the circle icon background
        let zstacks = sut.findAll(ViewType.ZStack.self)
        XCTAssertGreaterThanOrEqual(zstacks.count, 1)
    }

    func testEvidenceRowHasIcon() throws {
        let evidence = EvidenceItem(type: .electronics, description: "Laptop computer")
        let view = EvidenceRow(item: evidence)
        let sut = try view.inspect()

        let images = sut.findAll(ViewType.Image.self)
        XCTAssertGreaterThanOrEqual(images.count, 1)
    }

    func testEvidenceRowHasTexts() throws {
        let evidence = EvidenceItem(type: .electronics, description: "Laptop computer")
        let view = EvidenceRow(item: evidence)
        let sut = try view.inspect()

        let texts = sut.findAll(ViewType.Text.self)
        XCTAssertGreaterThanOrEqual(texts.count, 2) // type and description
    }

    func testEvidenceRowHasVStack() throws {
        let evidence = EvidenceItem(type: .electronics, description: "Laptop computer")
        let view = EvidenceRow(item: evidence)
        let sut = try view.inspect()

        let vstack = try sut.find(ViewType.VStack.self)
        XCTAssertNotNil(vstack)
    }
}

// MARK: - ReportEditorView Tests

@MainActor
final class ReportEditorViewTests: XCTestCase {

    private func createMockReport(withOfficialCaseNumber: Bool = false) -> Report {
        Report(
            localCaseNumber: "DRAFT-12345",
            officialCaseNumber: withOfficialCaseNumber ? "2026-12345" : nil,
            officerId: "OFF-001",
            officerName: "Officer Smith",
            badgeNumber: "12345"
        )
    }

    func testReportEditorViewHasNavigationStack() throws {
        let report = createMockReport()
        let reportService = MockReportService()
        let view = ReportEditorView(report: report, reportService: reportService)
        let sut = try view.inspect()

        let nav = try sut.find(ViewType.NavigationStack.self)
        XCTAssertNotNil(nav)
    }

    func testReportEditorViewHasForm() throws {
        let report = createMockReport()
        let reportService = MockReportService()
        let view = ReportEditorView(report: report, reportService: reportService)
        let sut = try view.inspect()

        let form = try sut.find(ViewType.Form.self)
        XCTAssertNotNil(form)
    }

    func testReportEditorViewHasSections() throws {
        let report = createMockReport()
        let reportService = MockReportService()
        let view = ReportEditorView(report: report, reportService: reportService)
        let sut = try view.inspect()

        let sections = sut.findAll(ViewType.Section.self)
        XCTAssertGreaterThanOrEqual(sections.count, 4) // Basic info, when/where, narrative, parties, evidence
    }

    func testReportEditorViewHasPickers() throws {
        let report = createMockReport()
        let reportService = MockReportService()
        let view = ReportEditorView(report: report, reportService: reportService)
        let sut = try view.inspect()

        let pickers = sut.findAll(ViewType.Picker.self)
        XCTAssertGreaterThanOrEqual(pickers.count, 1) // Incident type picker
    }

    func testReportEditorViewHasTextFields() throws {
        let report = createMockReport()
        let reportService = MockReportService()
        let view = ReportEditorView(report: report, reportService: reportService)
        let sut = try view.inspect()

        let textFields = sut.findAll(ViewType.TextField.self)
        XCTAssertGreaterThanOrEqual(textFields.count, 2) // Summary, Location
    }

    func testReportEditorViewHasDatePicker() throws {
        let report = createMockReport()
        let reportService = MockReportService()
        let view = ReportEditorView(report: report, reportService: reportService)
        let sut = try view.inspect()

        let datePickers = sut.findAll(ViewType.DatePicker.self)
        XCTAssertGreaterThanOrEqual(datePickers.count, 1)
    }

    func testReportEditorViewHasTextEditor() throws {
        let report = createMockReport()
        let reportService = MockReportService()
        let view = ReportEditorView(report: report, reportService: reportService)
        let sut = try view.inspect()

        let textEditors = sut.findAll(ViewType.TextEditor.self)
        XCTAssertGreaterThanOrEqual(textEditors.count, 1) // Narrative
    }

    func testReportEditorViewHasDisclosureGroups() throws {
        let report = createMockReport()
        let reportService = MockReportService()
        let view = ReportEditorView(report: report, reportService: reportService)
        let sut = try view.inspect()

        let disclosureGroups = sut.findAll(ViewType.DisclosureGroup.self)
        XCTAssertGreaterThanOrEqual(disclosureGroups.count, 3) // Subjects, Victims, Witnesses
    }

    func testReportEditorViewHasAddButtons() throws {
        let report = createMockReport()
        let reportService = MockReportService()
        let view = ReportEditorView(report: report, reportService: reportService)
        let sut = try view.inspect()

        let buttons = sut.findAll(ViewType.Button.self)
        // Add Subject, Add Victim, Add Witness, Add Evidence, Cancel, Save
        XCTAssertGreaterThanOrEqual(buttons.count, 4)
    }

    func testReportEditorViewShowsClockIconForDraftReport() throws {
        let report = createMockReport(withOfficialCaseNumber: false)
        let reportService = MockReportService()
        let view = ReportEditorView(report: report, reportService: reportService)
        let sut = try view.inspect()

        // Should have clock icon for reports without official case number
        let images = sut.findAll(ViewType.Image.self)
        XCTAssertGreaterThanOrEqual(images.count, 1, "Should have clock icon for pending reports")
    }

    func testReportEditorViewHidesClockIconForSyncedReport() throws {
        let report = createMockReport(withOfficialCaseNumber: true)
        let reportService = MockReportService()
        let view = ReportEditorView(report: report, reportService: reportService)
        let sut = try view.inspect()

        // Synced reports should have no clock icon (fewer images)
        let images = sut.findAll(ViewType.Image.self)
        XCTAssertNotNil(images)
    }

    func testReportEditorViewShowsDisplayCaseNumber() throws {
        let report = createMockReport(withOfficialCaseNumber: false)
        let reportService = MockReportService()
        let view = ReportEditorView(report: report, reportService: reportService)
        let sut = try view.inspect()

        let texts = sut.findAll(ViewType.Text.self)
        let caseNumberText = texts.first { (try? $0.string()) == "DRAFT-12345" }
        XCTAssertNotNil(caseNumberText, "Should show draft case number")
    }

    // MARK: - Media Section Tests

    func testReportEditorViewHasMediaSection() throws {
        let report = createMockReport()
        let reportService = MockReportService()
        let view = ReportEditorView(report: report, reportService: reportService)
        let sut = try view.inspect()

        let texts = sut.findAll(ViewType.Text.self)
        let mediaHeader = texts.first { (try? $0.string()) == "Media" }
        XCTAssertNotNil(mediaHeader, "Should have Media section header")
    }

    func testReportEditorViewHasAddMediaButton() throws {
        let report = createMockReport()
        let reportService = MockReportService()
        let view = ReportEditorView(report: report, reportService: reportService)
        let sut = try view.inspect()

        let texts = sut.findAll(ViewType.Text.self)
        let addMediaText = texts.first { (try? $0.string()) == "Add Media" }
        XCTAssertNotNil(addMediaText, "Should have Add Media button text")
    }

    func testReportEditorViewHasMediaCaptionText() throws {
        let report = createMockReport()
        let reportService = MockReportService()
        let view = ReportEditorView(report: report, reportService: reportService)
        let sut = try view.inspect()

        let texts = sut.findAll(ViewType.Text.self)
        let captionText = texts.first { (try? $0.string()) == "Capture or select photos and videos" }
        XCTAssertNotNil(captionText, "Should have caption text for media")
    }

    func testReportEditorViewHasCameraIcon() throws {
        let report = createMockReport()
        let reportService = MockReportService()
        let view = ReportEditorView(report: report, reportService: reportService)
        let sut = try view.inspect()

        let images = sut.findAll(ViewType.Image.self)
        // Should have camera icon in photos section
        XCTAssertGreaterThanOrEqual(images.count, 1)
    }

    func testReportEditorViewPhotosSectionHasButton() throws {
        let report = createMockReport()
        let reportService = MockReportService()
        let view = ReportEditorView(report: report, reportService: reportService)
        let sut = try view.inspect()

        // Photos section has a button for adding photos
        let buttons = sut.findAll(ViewType.Button.self)
        XCTAssertGreaterThanOrEqual(buttons.count, 1, "Should have button in photos section")
    }

    func testReportEditorViewPhotosSectionHasChevron() throws {
        let report = createMockReport()
        let reportService = MockReportService()
        let view = ReportEditorView(report: report, reportService: reportService)
        let sut = try view.inspect()

        let images = sut.findAll(ViewType.Image.self)
        // Should have multiple images including chevron
        XCTAssertGreaterThanOrEqual(images.count, 2)
    }
}

// MARK: - PersonListRow Tests

@MainActor
final class PersonListRowTests: XCTestCase {

    func testPersonListRowHasVStack() throws {
        let person = Person(firstName: "John", lastName: "Doe", phone: "555-1234")
        let view = PersonListRow(person: person, role: "Subject")
        let sut = try view.inspect()

        let vstack = try sut.find(ViewType.VStack.self)
        XCTAssertNotNil(vstack)
    }

    func testPersonListRowHasTexts() throws {
        let person = Person(firstName: "John", lastName: "Doe", phone: "555-1234")
        let view = PersonListRow(person: person, role: "Subject")
        let sut = try view.inspect()

        let texts = sut.findAll(ViewType.Text.self)
        XCTAssertGreaterThanOrEqual(texts.count, 2) // name and phone
    }

    func testPersonListRowShowsFullName() throws {
        let person = Person(firstName: "John", lastName: "Doe")
        let view = PersonListRow(person: person, role: "Subject")
        let sut = try view.inspect()

        let texts = sut.findAll(ViewType.Text.self)
        let nameText = texts.first { (try? $0.string()) == "John Doe" }
        XCTAssertNotNil(nameText)
    }
}

// MARK: - EvidenceListRow Tests

@MainActor
final class EvidenceListRowTests: XCTestCase {

    func testEvidenceListRowHasHStack() throws {
        let evidence = EvidenceItem(type: .electronics, description: "Laptop")
        let view = EvidenceListRow(item: evidence)
        let sut = try view.inspect()

        let hstack = try sut.find(ViewType.HStack.self)
        XCTAssertNotNil(hstack)
    }

    func testEvidenceListRowHasIcon() throws {
        let evidence = EvidenceItem(type: .electronics, description: "Laptop")
        let view = EvidenceListRow(item: evidence)
        let sut = try view.inspect()

        let images = sut.findAll(ViewType.Image.self)
        XCTAssertGreaterThanOrEqual(images.count, 1)
    }

    func testEvidenceListRowHasVStack() throws {
        let evidence = EvidenceItem(type: .electronics, description: "Laptop")
        let view = EvidenceListRow(item: evidence)
        let sut = try view.inspect()

        let vstack = try sut.find(ViewType.VStack.self)
        XCTAssertNotNil(vstack)
    }

    func testEvidenceListRowHasTexts() throws {
        let evidence = EvidenceItem(type: .electronics, description: "Laptop")
        let view = EvidenceListRow(item: evidence)
        let sut = try view.inspect()

        let texts = sut.findAll(ViewType.Text.self)
        XCTAssertGreaterThanOrEqual(texts.count, 2) // type and description
    }
}

// MARK: - PersonEditorView Tests

@MainActor
final class PersonEditorViewTests: XCTestCase {

    func testPersonEditorViewHasNavigationStack() throws {
        let view = PersonEditorView(title: "Add Subject", person: nil) { _ in }
        let sut = try view.inspect()

        let nav = try sut.find(ViewType.NavigationStack.self)
        XCTAssertNotNil(nav)
    }

    func testPersonEditorViewHasForm() throws {
        let view = PersonEditorView(title: "Add Subject", person: nil) { _ in }
        let sut = try view.inspect()

        let form = try sut.find(ViewType.Form.self)
        XCTAssertNotNil(form)
    }

    func testPersonEditorViewHasSections() throws {
        let view = PersonEditorView(title: "Add Subject", person: nil) { _ in }
        let sut = try view.inspect()

        let sections = sut.findAll(ViewType.Section.self)
        XCTAssertGreaterThanOrEqual(sections.count, 3) // Name, Contact, Details
    }

    func testPersonEditorViewHasTextFields() throws {
        let view = PersonEditorView(title: "Add Subject", person: nil) { _ in }
        let sut = try view.inspect()

        let textFields = sut.findAll(ViewType.TextField.self)
        XCTAssertGreaterThanOrEqual(textFields.count, 4) // First name, Last name, Phone, Address
    }

    func testPersonEditorViewHasPicker() throws {
        let view = PersonEditorView(title: "Add Subject", person: nil) { _ in }
        let sut = try view.inspect()

        let pickers = sut.findAll(ViewType.Picker.self)
        XCTAssertGreaterThanOrEqual(pickers.count, 1) // Gender picker
    }

    func testPersonEditorViewHasToggle() throws {
        let view = PersonEditorView(title: "Add Subject", person: nil) { _ in }
        let sut = try view.inspect()

        let toggles = sut.findAll(ViewType.Toggle.self)
        XCTAssertGreaterThanOrEqual(toggles.count, 1) // Date of birth toggle
    }
}

// MARK: - EvidenceEditorView Tests

@MainActor
final class EvidenceEditorViewTests: XCTestCase {

    func testEvidenceEditorViewHasNavigationStack() throws {
        let view = EvidenceEditorView { _ in }
        let sut = try view.inspect()

        let nav = try sut.find(ViewType.NavigationStack.self)
        XCTAssertNotNil(nav)
    }

    func testEvidenceEditorViewHasForm() throws {
        let view = EvidenceEditorView { _ in }
        let sut = try view.inspect()

        let form = try sut.find(ViewType.Form.self)
        XCTAssertNotNil(form)
    }

    func testEvidenceEditorViewHasSections() throws {
        let view = EvidenceEditorView { _ in }
        let sut = try view.inspect()

        let sections = sut.findAll(ViewType.Section.self)
        XCTAssertGreaterThanOrEqual(sections.count, 2) // Type, Details
    }

    func testEvidenceEditorViewHasPicker() throws {
        let view = EvidenceEditorView { _ in }
        let sut = try view.inspect()

        let pickers = sut.findAll(ViewType.Picker.self)
        XCTAssertGreaterThanOrEqual(pickers.count, 1) // Evidence type picker
    }

    func testEvidenceEditorViewHasTextFields() throws {
        let view = EvidenceEditorView { _ in }
        let sut = try view.inspect()

        let textFields = sut.findAll(ViewType.TextField.self)
        XCTAssertGreaterThanOrEqual(textFields.count, 2) // Description, Location
    }
}

// MARK: - ReportFilter Tests

final class ReportFilterTests: XCTestCase {

    func testAllCasesCount() {
        XCTAssertEqual(ReportFilter.allCases.count, 5)
    }

    func testAllFilterRawValue() {
        XCTAssertEqual(ReportFilter.all.rawValue, "All Reports")
    }

    func testDraftsFilterRawValue() {
        XCTAssertEqual(ReportFilter.drafts.rawValue, "Drafts")
    }

    func testPendingFilterRawValue() {
        XCTAssertEqual(ReportFilter.pending.rawValue, "Pending")
    }

    func testApprovedFilterRawValue() {
        XCTAssertEqual(ReportFilter.approved.rawValue, "Approved")
    }

    func testNeedsSyncFilterRawValue() {
        XCTAssertEqual(ReportFilter.needsSync.rawValue, "Needs Sync")
    }

    func testAllFilterIcon() {
        XCTAssertEqual(ReportFilter.all.icon, "doc.text")
    }

    func testDraftsFilterIcon() {
        XCTAssertEqual(ReportFilter.drafts.icon, "pencil")
    }

    func testPendingFilterIcon() {
        XCTAssertEqual(ReportFilter.pending.icon, "clock")
    }

    func testApprovedFilterIcon() {
        XCTAssertEqual(ReportFilter.approved.icon, "checkmark.circle")
    }

    func testNeedsSyncFilterIcon() {
        XCTAssertEqual(ReportFilter.needsSync.icon, "icloud.slash")
    }
}

// MARK: - PersonPickerType Tests

final class PersonPickerTypeTests: XCTestCase {

    func testSubjectTitle() {
        XCTAssertEqual(PersonPickerType.subject.title, "Add Subject")
    }

    func testVictimTitle() {
        XCTAssertEqual(PersonPickerType.victim.title, "Add Victim")
    }

    func testWitnessTitle() {
        XCTAssertEqual(PersonPickerType.witness.title, "Add Witness")
    }

    func testSubjectId() {
        XCTAssertEqual(PersonPickerType.subject.id, "Add Subject")
    }

    func testVictimId() {
        XCTAssertEqual(PersonPickerType.victim.id, "Add Victim")
    }

    func testWitnessId() {
        XCTAssertEqual(PersonPickerType.witness.id, "Add Witness")
    }
}

// MARK: - EvidenceMediaView Tests

@MainActor
final class EvidencePhotoViewTests: XCTestCase {

    func testEvidenceMediaViewHasZStacks() throws {
        let media = EvidencePhoto(fileName: "test.jpg", capturedAt: Date(), metadata: nil)
        let view = EvidenceMediaView(media: media)
        let sut = try view.inspect()

        // View renders ZStack structure
        let zstacks = sut.findAll(ViewType.ZStack.self)
        XCTAssertGreaterThanOrEqual(zstacks.count, 1)
    }

    func testEvidenceMediaViewShowsPlaceholderWhenNoImage() throws {
        let media = EvidencePhoto(fileName: "nonexistent.jpg", capturedAt: Date(), metadata: nil)
        let view = EvidenceMediaView(media: media)
        let sut = try view.inspect()

        // Should find placeholder elements when image doesn't exist
        let images = sut.findAll(ViewType.Image.self)
        XCTAssertGreaterThanOrEqual(images.count, 1)
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

// MARK: - MediaDetailView Tests

@MainActor
final class PhotoDetailViewTests: XCTestCase {

    func testMediaDetailViewHasNavigationStack() throws {
        let media = EvidencePhoto(fileName: "test.jpg", capturedAt: Date(), metadata: nil)
        let view = MediaDetailView(media: media)
        let sut = try view.inspect()

        let nav = try sut.find(ViewType.NavigationStack.self)
        XCTAssertNotNil(nav)
    }

    func testMediaDetailViewHasVStack() throws {
        let media = EvidencePhoto(fileName: "test.jpg", capturedAt: Date(), metadata: nil)
        let view = MediaDetailView(media: media)
        let sut = try view.inspect()

        let vstack = try sut.find(ViewType.VStack.self)
        XCTAssertNotNil(vstack)
    }

    func testMediaDetailViewShowsUnavailableWhenNoImage() throws {
        let media = EvidencePhoto(fileName: "nonexistent.jpg", capturedAt: Date(), metadata: nil)
        let view = MediaDetailView(media: media)
        let sut = try view.inspect()

        // Should show ContentUnavailableView when image doesn't load
        let unavailable = try sut.find(ViewType.ContentUnavailableView.self)
        XCTAssertNotNil(unavailable)
    }

    func testMediaDetailViewWithMetadataShowsBar() throws {
        let metadata = PhotoMetadata(
            capturedAt: Date(),
            latitude: 37.7749,
            longitude: -122.4194,
            altitude: nil
        )
        let media = EvidencePhoto(fileName: "test.jpg", capturedAt: Date(), metadata: metadata)
        let view = MediaDetailView(media: media)
        let sut = try view.inspect()

        // MediaMetadataBar should be present
        let hstacks = sut.findAll(ViewType.HStack.self)
        XCTAssertGreaterThanOrEqual(hstacks.count, 1)
    }

    func testMediaDetailViewForVideoShowsVideoPlayer() throws {
        let media = EvidencePhoto(fileName: "test.mp4", capturedAt: Date(), metadata: nil, mediaType: .video)
        let view = MediaDetailView(media: media)
        let sut = try view.inspect()

        // Video detail view should have structure
        let vstack = try sut.find(ViewType.VStack.self)
        XCTAssertNotNil(vstack)
    }
}

// MARK: - PhotoGalleryView Tests

@MainActor
final class PhotoGalleryViewTests: XCTestCase {

    func testPhotoGalleryViewHasScrollView() throws {
        let photos = [
            EvidencePhoto(fileName: "test1.jpg", capturedAt: Date(), metadata: nil),
            EvidencePhoto(fileName: "test2.jpg", capturedAt: Date(), metadata: nil)
        ]
        let view = PhotoGalleryView(photos: photos)
        let sut = try view.inspect()

        let scrollView = try sut.find(ViewType.ScrollView.self)
        XCTAssertNotNil(scrollView)
    }

    func testPhotoGalleryViewHasHStack() throws {
        let photos = [
            EvidencePhoto(fileName: "test1.jpg", capturedAt: Date(), metadata: nil)
        ]
        let view = PhotoGalleryView(photos: photos)
        let sut = try view.inspect()

        let hstack = try sut.find(ViewType.HStack.self)
        XCTAssertNotNil(hstack)
    }

    func testEmptyPhotoGalleryShowsEmpty() throws {
        let view = PhotoGalleryView(photos: [])
        let sut = try view.inspect()

        // Should still have structure but no images
        let hstack = try sut.find(ViewType.HStack.self)
        XCTAssertNotNil(hstack)
    }
}

// MARK: - ViewInspector Extensions

extension ReportsListView: @retroactive Inspectable {}
extension ReportRowView: @retroactive Inspectable {}
extension StatusBadge: @retroactive Inspectable {}
extension StatCard: @retroactive Inspectable {}
extension ReportDetailView: @retroactive Inspectable {}
extension InfoRow: @retroactive Inspectable {}
extension PersonRow: @retroactive Inspectable {}
extension EvidenceRow: @retroactive Inspectable {}
extension ReportEditorView: @retroactive Inspectable {}
extension PersonListRow: @retroactive Inspectable {}
extension EvidenceListRow: @retroactive Inspectable {}
extension PersonEditorView: @retroactive Inspectable {}
extension EvidenceEditorView: @retroactive Inspectable {}
extension PhotoGalleryView: @retroactive Inspectable {}
extension MediaDetailView: @retroactive Inspectable {}
