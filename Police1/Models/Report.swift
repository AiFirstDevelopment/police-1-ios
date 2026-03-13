import Foundation

// MARK: - Report Model

struct Report: Identifiable, Codable, Equatable {
    let id: UUID
    var incidentType: IncidentType
    var caseNumber: String
    var incidentDate: Date
    var location: String
    var summary: String
    var narrative: String
    var status: ReportStatus
    var createdAt: Date
    var updatedAt: Date
    var syncStatus: SyncStatus

    // Involved parties
    var subjects: [Person]
    var victims: [Person]
    var witnesses: [Person]

    // Evidence
    var evidence: [EvidenceItem]

    // Officer info
    var officerId: String
    var officerName: String
    var badgeNumber: String

    init(
        id: UUID = UUID(),
        incidentType: IncidentType = .other,
        caseNumber: String = "",
        incidentDate: Date = Date(),
        location: String = "",
        summary: String = "",
        narrative: String = "",
        status: ReportStatus = .draft,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        syncStatus: SyncStatus = .local,
        subjects: [Person] = [],
        victims: [Person] = [],
        witnesses: [Person] = [],
        evidence: [EvidenceItem] = [],
        officerId: String = "",
        officerName: String = "",
        badgeNumber: String = ""
    ) {
        self.id = id
        self.incidentType = incidentType
        self.caseNumber = caseNumber
        self.incidentDate = incidentDate
        self.location = location
        self.summary = summary
        self.narrative = narrative
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.syncStatus = syncStatus
        self.subjects = subjects
        self.victims = victims
        self.witnesses = witnesses
        self.evidence = evidence
        self.officerId = officerId
        self.officerName = officerName
        self.badgeNumber = badgeNumber
    }
}

// MARK: - Incident Types

enum IncidentType: String, Codable, CaseIterable {
    case theft = "Theft"
    case assault = "Assault"
    case burglary = "Burglary"
    case domesticDisturbance = "Domestic Disturbance"
    case trafficAccident = "Traffic Accident"
    case dui = "DUI"
    case vandalism = "Vandalism"
    case drugOffense = "Drug Offense"
    case fraud = "Fraud"
    case missingPerson = "Missing Person"
    case suspiciousActivity = "Suspicious Activity"
    case trespass = "Trespass"
    case disturbance = "Disturbance"
    case welfare = "Welfare Check"
    case other = "Other"

    var icon: String {
        switch self {
        case .theft: return "bag.fill"
        case .assault: return "figure.boxing"
        case .burglary: return "door.left.hand.open"
        case .domesticDisturbance: return "house.fill"
        case .trafficAccident: return "car.fill"
        case .dui: return "wineglass.fill"
        case .vandalism: return "paintbrush.fill"
        case .drugOffense: return "pills.fill"
        case .fraud: return "creditcard.fill"
        case .missingPerson: return "person.fill.questionmark"
        case .suspiciousActivity: return "eye.fill"
        case .trespass: return "figure.walk"
        case .disturbance: return "speaker.wave.3.fill"
        case .welfare: return "heart.fill"
        case .other: return "doc.fill"
        }
    }

    var color: String {
        switch self {
        case .assault, .domesticDisturbance: return "red"
        case .dui, .drugOffense: return "orange"
        case .theft, .burglary, .fraud: return "yellow"
        case .trafficAccident: return "blue"
        case .missingPerson, .welfare: return "purple"
        default: return "gray"
        }
    }
}

// MARK: - Report Status

enum ReportStatus: String, Codable, CaseIterable {
    case draft = "Draft"
    case pending = "Pending Review"
    case approved = "Approved"
    case rejected = "Needs Revision"
    case submitted = "Submitted"

    var icon: String {
        switch self {
        case .draft: return "pencil"
        case .pending: return "clock"
        case .approved: return "checkmark.circle.fill"
        case .rejected: return "exclamationmark.circle.fill"
        case .submitted: return "paperplane.fill"
        }
    }

    var color: String {
        switch self {
        case .draft: return "gray"
        case .pending: return "orange"
        case .approved: return "green"
        case .rejected: return "red"
        case .submitted: return "blue"
        }
    }
}

// MARK: - Sync Status

enum SyncStatus: String, Codable {
    case local = "Local Only"
    case syncing = "Syncing"
    case synced = "Synced"
    case error = "Sync Error"

    var icon: String {
        switch self {
        case .local: return "icloud.slash"
        case .syncing: return "arrow.triangle.2.circlepath"
        case .synced: return "checkmark.icloud"
        case .error: return "exclamationmark.icloud"
        }
    }
}

// MARK: - Person

struct Person: Identifiable, Codable, Equatable {
    let id: UUID
    var firstName: String
    var lastName: String
    var dateOfBirth: Date?
    var gender: String?
    var race: String?
    var height: String?
    var weight: String?
    var hairColor: String?
    var eyeColor: String?
    var address: String?
    var phone: String?
    var driversLicense: String?
    var notes: String?

    init(
        id: UUID = UUID(),
        firstName: String = "",
        lastName: String = "",
        dateOfBirth: Date? = nil,
        gender: String? = nil,
        race: String? = nil,
        height: String? = nil,
        weight: String? = nil,
        hairColor: String? = nil,
        eyeColor: String? = nil,
        address: String? = nil,
        phone: String? = nil,
        driversLicense: String? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.dateOfBirth = dateOfBirth
        self.gender = gender
        self.race = race
        self.height = height
        self.weight = weight
        self.hairColor = hairColor
        self.eyeColor = eyeColor
        self.address = address
        self.phone = phone
        self.driversLicense = driversLicense
        self.notes = notes
    }

    var fullName: String {
        "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
    }
}

// MARK: - Evidence Item

struct EvidenceItem: Identifiable, Codable, Equatable {
    let id: UUID
    var type: EvidenceType
    var description: String
    var location: String
    var collectedAt: Date
    var photoUrls: [String]

    init(
        id: UUID = UUID(),
        type: EvidenceType = .other,
        description: String = "",
        location: String = "",
        collectedAt: Date = Date(),
        photoUrls: [String] = []
    ) {
        self.id = id
        self.type = type
        self.description = description
        self.location = location
        self.collectedAt = collectedAt
        self.photoUrls = photoUrls
    }
}

enum EvidenceType: String, Codable, CaseIterable {
    case weapon = "Weapon"
    case drugs = "Drugs/Paraphernalia"
    case documents = "Documents"
    case electronics = "Electronics"
    case clothing = "Clothing"
    case vehicle = "Vehicle"
    case currency = "Currency"
    case biologicalSample = "Biological Sample"
    case other = "Other"

    var icon: String {
        switch self {
        case .weapon: return "shield.fill"
        case .drugs: return "pills.fill"
        case .documents: return "doc.fill"
        case .electronics: return "iphone"
        case .clothing: return "tshirt.fill"
        case .vehicle: return "car.fill"
        case .currency: return "dollarsign.circle.fill"
        case .biologicalSample: return "drop.fill"
        case .other: return "archivebox.fill"
        }
    }
}
