import XCTest
@testable import Police1

// MARK: - Report Model Tests

final class ReportModelTests: XCTestCase {

    // MARK: - Report Tests

    func testReportDefaultInitialization() {
        let report = Report()

        XCTAssertNotNil(report.id)
        XCTAssertEqual(report.incidentType, .other)
        XCTAssertEqual(report.localCaseNumber, "")
        XCTAssertNil(report.officialCaseNumber)
        XCTAssertEqual(report.location, "")
        XCTAssertEqual(report.summary, "")
        XCTAssertEqual(report.narrative, "")
        XCTAssertEqual(report.status, .draft)
        XCTAssertEqual(report.syncStatus, .local)
        XCTAssertTrue(report.subjects.isEmpty)
        XCTAssertTrue(report.victims.isEmpty)
        XCTAssertTrue(report.witnesses.isEmpty)
        XCTAssertTrue(report.evidence.isEmpty)
    }

    func testReportCustomInitialization() {
        let id = UUID()
        let date = Date()
        let report = Report(
            id: id,
            incidentType: .theft,
            localCaseNumber: "DRAFT-12345",
            officialCaseNumber: "2026-12345",
            incidentDate: date,
            location: "123 Main St",
            summary: "Test summary",
            narrative: "Test narrative",
            status: .approved,
            createdAt: date,
            updatedAt: date,
            syncStatus: .synced,
            subjects: [],
            victims: [],
            witnesses: [],
            evidence: [],
            officerId: "OFF-001",
            officerName: "Officer Smith",
            badgeNumber: "12345"
        )

        XCTAssertEqual(report.id, id)
        XCTAssertEqual(report.incidentType, .theft)
        XCTAssertEqual(report.localCaseNumber, "DRAFT-12345")
        XCTAssertEqual(report.officialCaseNumber, "2026-12345")
        XCTAssertEqual(report.location, "123 Main St")
        XCTAssertEqual(report.status, .approved)
        XCTAssertEqual(report.syncStatus, .synced)
        XCTAssertEqual(report.officerId, "OFF-001")
        XCTAssertEqual(report.officerName, "Officer Smith")
        XCTAssertEqual(report.badgeNumber, "12345")
    }

    func testReportEquatable() {
        let id = UUID()
        let date = Date()
        let report1 = Report(
            id: id,
            localCaseNumber: "DRAFT-12345",
            incidentDate: date,
            createdAt: date,
            updatedAt: date
        )
        let report2 = Report(
            id: id,
            localCaseNumber: "DRAFT-12345",
            incidentDate: date,
            createdAt: date,
            updatedAt: date
        )
        let report3 = Report(localCaseNumber: "DRAFT-12345")

        XCTAssertEqual(report1, report2)
        XCTAssertNotEqual(report1, report3)
    }

    // MARK: - Case Number Tests

    func testDisplayCaseNumberShowsOfficialWhenAvailable() {
        let report = Report(
            localCaseNumber: "DRAFT-12345",
            officialCaseNumber: "2026-12345"
        )

        XCTAssertEqual(report.displayCaseNumber, "2026-12345")
    }

    func testDisplayCaseNumberShowsLocalWhenNoOfficial() {
        let report = Report(
            localCaseNumber: "DRAFT-12345",
            officialCaseNumber: nil
        )

        XCTAssertEqual(report.displayCaseNumber, "DRAFT-12345")
    }

    func testHasOfficialCaseNumberTrueWhenAssigned() {
        let report = Report(
            localCaseNumber: "DRAFT-12345",
            officialCaseNumber: "2026-12345"
        )

        XCTAssertTrue(report.hasOfficialCaseNumber)
    }

    func testHasOfficialCaseNumberFalseWhenNotAssigned() {
        let report = Report(
            localCaseNumber: "DRAFT-12345",
            officialCaseNumber: nil
        )

        XCTAssertFalse(report.hasOfficialCaseNumber)
    }

    // MARK: - IncidentType Tests

    func testIncidentTypeAllCasesCount() {
        XCTAssertEqual(IncidentType.allCases.count, 15)
    }

    func testIncidentTypeRawValues() {
        XCTAssertEqual(IncidentType.theft.rawValue, "Theft")
        XCTAssertEqual(IncidentType.assault.rawValue, "Assault")
        XCTAssertEqual(IncidentType.burglary.rawValue, "Burglary")
        XCTAssertEqual(IncidentType.domesticDisturbance.rawValue, "Domestic Disturbance")
        XCTAssertEqual(IncidentType.trafficAccident.rawValue, "Traffic Accident")
        XCTAssertEqual(IncidentType.dui.rawValue, "DUI")
        XCTAssertEqual(IncidentType.vandalism.rawValue, "Vandalism")
        XCTAssertEqual(IncidentType.drugOffense.rawValue, "Drug Offense")
        XCTAssertEqual(IncidentType.fraud.rawValue, "Fraud")
        XCTAssertEqual(IncidentType.missingPerson.rawValue, "Missing Person")
        XCTAssertEqual(IncidentType.suspiciousActivity.rawValue, "Suspicious Activity")
        XCTAssertEqual(IncidentType.trespass.rawValue, "Trespass")
        XCTAssertEqual(IncidentType.disturbance.rawValue, "Disturbance")
        XCTAssertEqual(IncidentType.welfare.rawValue, "Welfare Check")
        XCTAssertEqual(IncidentType.other.rawValue, "Other")
    }

    func testIncidentTypeIcons() {
        XCTAssertEqual(IncidentType.theft.icon, "bag.fill")
        XCTAssertEqual(IncidentType.assault.icon, "figure.boxing")
        XCTAssertEqual(IncidentType.trafficAccident.icon, "car.fill")
        XCTAssertEqual(IncidentType.dui.icon, "wineglass.fill")
        XCTAssertEqual(IncidentType.missingPerson.icon, "person.fill.questionmark")
        XCTAssertEqual(IncidentType.other.icon, "doc.fill")
    }

    func testIncidentTypeColors() {
        XCTAssertEqual(IncidentType.assault.color, "red")
        XCTAssertEqual(IncidentType.domesticDisturbance.color, "red")
        XCTAssertEqual(IncidentType.dui.color, "orange")
        XCTAssertEqual(IncidentType.drugOffense.color, "orange")
        XCTAssertEqual(IncidentType.theft.color, "yellow")
        XCTAssertEqual(IncidentType.trafficAccident.color, "blue")
        XCTAssertEqual(IncidentType.missingPerson.color, "purple")
        XCTAssertEqual(IncidentType.other.color, "gray")
    }

    // MARK: - ReportStatus Tests

    func testReportStatusAllCasesCount() {
        XCTAssertEqual(ReportStatus.allCases.count, 5)
    }

    func testReportStatusRawValues() {
        XCTAssertEqual(ReportStatus.draft.rawValue, "Draft")
        XCTAssertEqual(ReportStatus.pending.rawValue, "Pending Review")
        XCTAssertEqual(ReportStatus.approved.rawValue, "Approved")
        XCTAssertEqual(ReportStatus.rejected.rawValue, "Needs Revision")
        XCTAssertEqual(ReportStatus.submitted.rawValue, "Submitted")
    }

    func testReportStatusIcons() {
        XCTAssertEqual(ReportStatus.draft.icon, "pencil")
        XCTAssertEqual(ReportStatus.pending.icon, "clock")
        XCTAssertEqual(ReportStatus.approved.icon, "checkmark.circle.fill")
        XCTAssertEqual(ReportStatus.rejected.icon, "exclamationmark.circle.fill")
        XCTAssertEqual(ReportStatus.submitted.icon, "paperplane.fill")
    }

    func testReportStatusColors() {
        XCTAssertEqual(ReportStatus.draft.color, "gray")
        XCTAssertEqual(ReportStatus.pending.color, "orange")
        XCTAssertEqual(ReportStatus.approved.color, "green")
        XCTAssertEqual(ReportStatus.rejected.color, "red")
        XCTAssertEqual(ReportStatus.submitted.color, "blue")
    }

    // MARK: - SyncStatus Tests

    func testSyncStatusRawValues() {
        XCTAssertEqual(SyncStatus.local.rawValue, "Local Only")
        XCTAssertEqual(SyncStatus.syncing.rawValue, "Syncing")
        XCTAssertEqual(SyncStatus.synced.rawValue, "Synced")
        XCTAssertEqual(SyncStatus.error.rawValue, "Sync Error")
    }

    func testSyncStatusIcons() {
        XCTAssertEqual(SyncStatus.local.icon, "icloud.slash")
        XCTAssertEqual(SyncStatus.syncing.icon, "arrow.triangle.2.circlepath")
        XCTAssertEqual(SyncStatus.synced.icon, "checkmark.icloud")
        XCTAssertEqual(SyncStatus.error.icon, "exclamationmark.icloud")
    }

    // MARK: - Person Tests

    func testPersonDefaultInitialization() {
        let person = Person()

        XCTAssertNotNil(person.id)
        XCTAssertEqual(person.firstName, "")
        XCTAssertEqual(person.lastName, "")
        XCTAssertNil(person.dateOfBirth)
        XCTAssertNil(person.gender)
        XCTAssertNil(person.phone)
        XCTAssertNil(person.address)
    }

    func testPersonCustomInitialization() {
        let dob = Date()
        let person = Person(
            firstName: "John",
            lastName: "Doe",
            dateOfBirth: dob,
            gender: "Male",
            address: "123 Main St",
            phone: "555-1234",
            driversLicense: "D1234567"
        )

        XCTAssertEqual(person.firstName, "John")
        XCTAssertEqual(person.lastName, "Doe")
        XCTAssertEqual(person.dateOfBirth, dob)
        XCTAssertEqual(person.gender, "Male")
        XCTAssertEqual(person.address, "123 Main St")
        XCTAssertEqual(person.phone, "555-1234")
        XCTAssertEqual(person.driversLicense, "D1234567")
    }

    func testPersonFullName() {
        let person1 = Person(firstName: "John", lastName: "Doe")
        XCTAssertEqual(person1.fullName, "John Doe")

        let person2 = Person(firstName: "John", lastName: "")
        XCTAssertEqual(person2.fullName, "John")

        let person3 = Person(firstName: "", lastName: "Doe")
        XCTAssertEqual(person3.fullName, "Doe")

        let person4 = Person(firstName: "", lastName: "")
        XCTAssertEqual(person4.fullName, "")
    }

    func testPersonEquatable() {
        let id = UUID()
        let person1 = Person(id: id, firstName: "John", lastName: "Doe")
        let person2 = Person(id: id, firstName: "John", lastName: "Doe")
        let person3 = Person(firstName: "John", lastName: "Doe")

        XCTAssertEqual(person1, person2)
        XCTAssertNotEqual(person1, person3)
    }

    // MARK: - EvidenceItem Tests

    func testEvidenceItemDefaultInitialization() {
        let evidence = EvidenceItem()

        XCTAssertNotNil(evidence.id)
        XCTAssertEqual(evidence.type, .other)
        XCTAssertEqual(evidence.description, "")
        XCTAssertEqual(evidence.location, "")
        XCTAssertTrue(evidence.photoUrls.isEmpty)
    }

    func testEvidenceItemCustomInitialization() {
        let date = Date()
        let evidence = EvidenceItem(
            type: .electronics,
            description: "MacBook Pro",
            location: "Living room",
            collectedAt: date,
            photoUrls: ["photo1.jpg", "photo2.jpg"]
        )

        XCTAssertEqual(evidence.type, .electronics)
        XCTAssertEqual(evidence.description, "MacBook Pro")
        XCTAssertEqual(evidence.location, "Living room")
        XCTAssertEqual(evidence.collectedAt, date)
        XCTAssertEqual(evidence.photoUrls.count, 2)
    }

    func testEvidenceItemEquatable() {
        let id = UUID()
        let date = Date()
        let evidence1 = EvidenceItem(id: id, type: .electronics, description: "Laptop", collectedAt: date)
        let evidence2 = EvidenceItem(id: id, type: .electronics, description: "Laptop", collectedAt: date)
        let evidence3 = EvidenceItem(type: .electronics, description: "Laptop")

        XCTAssertEqual(evidence1, evidence2)
        XCTAssertNotEqual(evidence1, evidence3)
    }

    // MARK: - EvidenceType Tests

    func testEvidenceTypeAllCasesCount() {
        XCTAssertEqual(EvidenceType.allCases.count, 9)
    }

    func testEvidenceTypeRawValues() {
        XCTAssertEqual(EvidenceType.weapon.rawValue, "Weapon")
        XCTAssertEqual(EvidenceType.drugs.rawValue, "Drugs/Paraphernalia")
        XCTAssertEqual(EvidenceType.documents.rawValue, "Documents")
        XCTAssertEqual(EvidenceType.electronics.rawValue, "Electronics")
        XCTAssertEqual(EvidenceType.clothing.rawValue, "Clothing")
        XCTAssertEqual(EvidenceType.vehicle.rawValue, "Vehicle")
        XCTAssertEqual(EvidenceType.currency.rawValue, "Currency")
        XCTAssertEqual(EvidenceType.biologicalSample.rawValue, "Biological Sample")
        XCTAssertEqual(EvidenceType.other.rawValue, "Other")
    }

    func testEvidenceTypeIcons() {
        XCTAssertEqual(EvidenceType.weapon.icon, "shield.fill")
        XCTAssertEqual(EvidenceType.drugs.icon, "pills.fill")
        XCTAssertEqual(EvidenceType.documents.icon, "doc.fill")
        XCTAssertEqual(EvidenceType.electronics.icon, "iphone")
        XCTAssertEqual(EvidenceType.clothing.icon, "tshirt.fill")
        XCTAssertEqual(EvidenceType.vehicle.icon, "car.fill")
        XCTAssertEqual(EvidenceType.currency.icon, "dollarsign.circle.fill")
        XCTAssertEqual(EvidenceType.biologicalSample.icon, "drop.fill")
        XCTAssertEqual(EvidenceType.other.icon, "archivebox.fill")
    }
}
