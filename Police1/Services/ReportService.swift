import Foundation

// MARK: - Report Service Protocol

protocol ReportServiceProtocol {
    func fetchReports() async throws -> [Report]
    func fetchReport(id: UUID) async throws -> Report?
    func saveReport(_ report: Report) async throws -> Report
    func deleteReport(id: UUID) async throws
    func syncReports() async throws
}

// MARK: - Mock Report Service

@MainActor
final class MockReportService: ReportServiceProtocol, ObservableObject {
    @Published private(set) var reports: [Report] = []
    @Published private(set) var isSyncing = false

    private let officerId: String
    private let officerName: String
    private let badgeNumber: String

    init(officerId: String = "OFF-001", officerName: String = "Officer Smith", badgeNumber: String = "12345") {
        self.officerId = officerId
        self.officerName = officerName
        self.badgeNumber = badgeNumber
        self.reports = Self.generateMockReports(officerId: officerId, officerName: officerName, badgeNumber: badgeNumber)
    }

    func fetchReports() async throws -> [Report] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)
        return reports.sorted { $0.updatedAt > $1.updatedAt }
    }

    func fetchReport(id: UUID) async throws -> Report? {
        try await Task.sleep(nanoseconds: 200_000_000)
        return reports.first { $0.id == id }
    }

    func saveReport(_ report: Report) async throws -> Report {
        var updatedReport = report
        updatedReport.updatedAt = Date()
        updatedReport.syncStatus = .local

        if let index = reports.firstIndex(where: { $0.id == report.id }) {
            reports[index] = updatedReport
        } else {
            reports.append(updatedReport)
        }

        // Auto-save simulation
        try await Task.sleep(nanoseconds: 100_000_000)

        return updatedReport
    }

    func deleteReport(id: UUID) async throws {
        reports.removeAll { $0.id == id }
    }

    func syncReports() async throws {
        isSyncing = true
        defer { isSyncing = false }

        // Simulate sync delay
        try await Task.sleep(nanoseconds: 1_500_000_000)

        // Mark all local reports as synced
        for i in reports.indices {
            if reports[i].syncStatus == .local {
                reports[i].syncStatus = .synced
            }
        }
    }

    func createNewReport() -> Report {
        let caseNumber = generateCaseNumber()
        return Report(
            caseNumber: caseNumber,
            officerId: officerId,
            officerName: officerName,
            badgeNumber: badgeNumber
        )
    }

    private func generateCaseNumber() -> String {
        let year = Calendar.current.component(.year, from: Date())
        let random = Int.random(in: 10000...99999)
        return "\(year)-\(random)"
    }

    // MARK: - Mock Data Generation

    static func generateMockReports(officerId: String, officerName: String, badgeNumber: String) -> [Report] {
        let calendar = Calendar.current

        return [
            Report(
                id: UUID(),
                incidentType: .theft,
                caseNumber: "2026-45892",
                incidentDate: calendar.date(byAdding: .hour, value: -3, to: Date())!,
                location: "1247 Oak Street, Apt 4B",
                summary: "Residential theft - electronics stolen from unlocked apartment",
                narrative: """
                    On March 13, 2026 at approximately 1430 hours, I responded to a report of a residential theft at 1247 Oak Street, Apt 4B.

                    Upon arrival, I made contact with the victim, Sarah Johnson, who stated she returned home from work to find her front door unlocked and several items missing from her residence.

                    The victim reported the following items stolen:
                    - MacBook Pro laptop (silver, 16-inch)
                    - iPad Pro with Magic Keyboard
                    - Sony WH-1000XM5 headphones
                    - Approximately $200 in cash from bedroom drawer

                    The victim stated she left for work at approximately 0730 hours and returned at 1415 hours. She is certain she locked the door when leaving. No signs of forced entry were observed.

                    I canvassed the area and spoke with neighbor Tom Williams (Apt 4A) who reported seeing an unknown male in his 20s, wearing a dark hoodie, exiting the building around 1100 hours carrying a backpack.

                    Evidence technician requested for fingerprint collection. Case remains open pending investigation.
                    """,
                status: .draft,
                createdAt: calendar.date(byAdding: .hour, value: -2, to: Date())!,
                updatedAt: calendar.date(byAdding: .minute, value: -15, to: Date())!,
                syncStatus: .local,
                subjects: [],
                victims: [
                    Person(
                        firstName: "Sarah",
                        lastName: "Johnson",
                        dateOfBirth: calendar.date(byAdding: .year, value: -34, to: Date()),
                        gender: "Female",
                        address: "1247 Oak Street, Apt 4B",
                        phone: "555-234-5678"
                    )
                ],
                witnesses: [
                    Person(
                        firstName: "Tom",
                        lastName: "Williams",
                        address: "1247 Oak Street, Apt 4A",
                        phone: "555-345-6789"
                    )
                ],
                evidence: [],
                officerId: officerId,
                officerName: officerName,
                badgeNumber: badgeNumber
            ),

            Report(
                id: UUID(),
                incidentType: .trafficAccident,
                caseNumber: "2026-45801",
                incidentDate: calendar.date(byAdding: .day, value: -1, to: Date())!,
                location: "Intersection of Main St and 5th Ave",
                summary: "Two-vehicle collision, minor injuries, one citation issued",
                narrative: """
                    On March 12, 2026 at approximately 0845 hours, I was dispatched to a two-vehicle traffic collision at the intersection of Main Street and 5th Avenue.

                    Upon arrival, I observed a blue 2022 Honda Civic (CA plate 8ABC123) with front-end damage and a white 2021 Toyota Camry (CA plate 7XYZ789) with rear-end damage. Both vehicles were blocking the eastbound lane of Main Street.

                    Driver 1 (Honda): Michael Chen, male, DOB 05/15/1990. Mr. Chen stated he was traveling eastbound on Main Street when the light turned yellow. He attempted to stop but was unable to do so in time and struck the rear of the Toyota.

                    Driver 2 (Toyota): Emily Rodriguez, female, DOB 11/22/1985. Ms. Rodriguez stated she was stopped at the red light when she felt the impact from behind.

                    Ms. Rodriguez complained of neck pain and was transported to General Hospital by AMR unit 447 for evaluation.

                    Based on my investigation, I determined Mr. Chen was following too closely and failed to stop in time. Citation issued: CVC 21703 (Following Too Closely).

                    Both vehicles were towed from the scene. Roadway cleared at 0945 hours.
                    """,
                status: .approved,
                createdAt: calendar.date(byAdding: .day, value: -1, to: Date())!,
                updatedAt: calendar.date(byAdding: .hour, value: -20, to: Date())!,
                syncStatus: .synced,
                subjects: [
                    Person(
                        firstName: "Michael",
                        lastName: "Chen",
                        dateOfBirth: calendar.date(from: DateComponents(year: 1990, month: 5, day: 15)),
                        gender: "Male",
                        driversLicense: "D1234567"
                    )
                ],
                victims: [
                    Person(
                        firstName: "Emily",
                        lastName: "Rodriguez",
                        dateOfBirth: calendar.date(from: DateComponents(year: 1985, month: 11, day: 22)),
                        gender: "Female",
                        driversLicense: "D7654321"
                    )
                ],
                witnesses: [],
                evidence: [],
                officerId: officerId,
                officerName: officerName,
                badgeNumber: badgeNumber
            ),

            Report(
                id: UUID(),
                incidentType: .domesticDisturbance,
                caseNumber: "2026-45756",
                incidentDate: calendar.date(byAdding: .day, value: -2, to: Date())!,
                location: "892 Pine Lane",
                summary: "Verbal domestic dispute, both parties separated, no arrests",
                narrative: """
                    On March 11, 2026 at approximately 2215 hours, I responded to a domestic disturbance call at 892 Pine Lane.

                    Upon arrival, I could hear loud voices from inside the residence. I knocked and announced police presence. The door was opened by James Wilson, male, who appeared agitated but cooperative.

                    I separated the parties and spoke with each individually. James Wilson stated he and his wife Patricia Wilson had been arguing about finances. He denied any physical altercation.

                    Patricia Wilson confirmed the argument was verbal only and stated she did not feel threatened or unsafe. No visible injuries observed on either party.

                    Both parties were advised of domestic violence resources and provided with information cards. Patricia stated she would be staying with her sister for the evening to allow tensions to cool.

                    No further police action required at this time.
                    """,
                status: .submitted,
                createdAt: calendar.date(byAdding: .day, value: -2, to: Date())!,
                updatedAt: calendar.date(byAdding: .day, value: -2, to: Date())!,
                syncStatus: .synced,
                subjects: [],
                victims: [],
                witnesses: [],
                evidence: [],
                officerId: officerId,
                officerName: officerName,
                badgeNumber: badgeNumber
            ),

            Report(
                id: UUID(),
                incidentType: .suspiciousActivity,
                caseNumber: "2026-45912",
                incidentDate: Date(),
                location: "Central Park, near fountain",
                summary: "Suspicious person reported - unable to locate",
                narrative: "",
                status: .draft,
                createdAt: Date(),
                updatedAt: Date(),
                syncStatus: .local,
                subjects: [],
                victims: [],
                witnesses: [],
                evidence: [],
                officerId: officerId,
                officerName: officerName,
                badgeNumber: badgeNumber
            ),

            Report(
                id: UUID(),
                incidentType: .dui,
                caseNumber: "2026-45623",
                incidentDate: calendar.date(byAdding: .day, value: -5, to: Date())!,
                location: "Highway 101 NB, Mile Marker 42",
                summary: "DUI arrest - driver failed field sobriety, BAC 0.14",
                narrative: """
                    On March 8, 2026 at approximately 0130 hours, I observed a silver 2019 BMW 330i traveling northbound on Highway 101 at approximately Mile Marker 42. The vehicle was weaving between lanes and traveling at inconsistent speeds between 45-70 mph in a 65 mph zone.

                    I initiated a traffic stop. The driver, identified as Robert Thompson (DOB 08/03/1982), exhibited signs of intoxication including slurred speech, bloodshot watery eyes, and a strong odor of alcohol emanating from the vehicle.

                    I asked Mr. Thompson to exit the vehicle and performed field sobriety tests:
                    - Horizontal Gaze Nystagmus: Failed (lack of smooth pursuit, distinct nystagmus at maximum deviation)
                    - Walk and Turn: Failed (started before instructions finished, stepped off line, used arms for balance)
                    - One Leg Stand: Failed (swayed, put foot down twice)

                    Mr. Thompson was placed under arrest for suspicion of DUI. A preliminary breath test showed a BAC of 0.14%. He was transported to the station where a blood draw was conducted at 0245 hours.

                    Vehicle was impounded. Mr. Thompson was booked at County Jail.
                    """,
                status: .approved,
                createdAt: calendar.date(byAdding: .day, value: -5, to: Date())!,
                updatedAt: calendar.date(byAdding: .day, value: -4, to: Date())!,
                syncStatus: .synced,
                subjects: [
                    Person(
                        firstName: "Robert",
                        lastName: "Thompson",
                        dateOfBirth: calendar.date(from: DateComponents(year: 1982, month: 8, day: 3)),
                        gender: "Male",
                        driversLicense: "D9876543"
                    )
                ],
                victims: [],
                witnesses: [],
                evidence: [
                    EvidenceItem(
                        type: .other,
                        description: "Blood sample - BAC test",
                        location: "County Lab",
                        collectedAt: calendar.date(byAdding: .day, value: -5, to: Date())!
                    )
                ],
                officerId: officerId,
                officerName: officerName,
                badgeNumber: badgeNumber
            )
        ]
    }
}
