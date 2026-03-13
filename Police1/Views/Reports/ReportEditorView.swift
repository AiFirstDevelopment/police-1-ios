import SwiftUI

// MARK: - Report Editor View

struct ReportEditorView: View {
    @Environment(\.dismiss) private var dismiss
    let reportService: MockReportService

    @State private var report: Report
    @State private var isSaving = false
    @State private var showingPersonPicker: PersonPickerType?
    @State private var showingEvidencePicker = false
    @State private var showingDiscardAlert = false
    @State private var hasChanges = false

    private let isNewReport: Bool

    init(report: Report, reportService: MockReportService) {
        self._report = State(initialValue: report)
        self.reportService = reportService
        self.isNewReport = report.narrative.isEmpty && report.summary.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                // Basic Info Section
                basicInfoSection

                // Location & Date Section
                locationDateSection

                // Narrative Section
                narrativeSection

                // Involved Parties Section
                partiesSection

                // Evidence Section
                evidenceSection
            }
            .navigationTitle(isNewReport ? "New Report" : "Edit Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if hasChanges {
                            showingDiscardAlert = true
                        } else {
                            dismiss()
                        }
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(action: saveReport) {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Save")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(isSaving || !isValid)
                }
            }
            .alert("Discard Changes?", isPresented: $showingDiscardAlert) {
                Button("Discard", role: .destructive) { dismiss() }
                Button("Keep Editing", role: .cancel) {}
            } message: {
                Text("You have unsaved changes that will be lost.")
            }
            .sheet(item: $showingPersonPicker) { pickerType in
                PersonEditorView(
                    title: pickerType.title,
                    person: nil
                ) { person in
                    addPerson(person, type: pickerType)
                }
            }
            .sheet(isPresented: $showingEvidencePicker) {
                EvidenceEditorView { evidence in
                    report.evidence.append(evidence)
                    hasChanges = true
                }
            }
            .onChange(of: report) { _, _ in
                hasChanges = true
            }
        }
    }

    // MARK: - Basic Info Section

    private var basicInfoSection: some View {
        Section("Incident Information") {
            Picker("Incident Type", selection: $report.incidentType) {
                ForEach(IncidentType.allCases, id: \.self) { type in
                    Label(type.rawValue, systemImage: type.icon)
                        .tag(type)
                }
            }

            HStack {
                Text("Case Number")
                    .foregroundStyle(.secondary)
                Spacer()
                HStack(spacing: 4) {
                    Text(report.displayCaseNumber)
                    if !report.hasOfficialCaseNumber {
                        Text("(Pending)")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
                .foregroundStyle(.primary)
            }

            TextField("Summary", text: $report.summary, axis: .vertical)
                .lineLimit(2...4)
        }
    }

    // MARK: - Location & Date Section

    private var locationDateSection: some View {
        Section("When & Where") {
            DatePicker("Incident Date", selection: $report.incidentDate, displayedComponents: [.date, .hourAndMinute])

            TextField("Location", text: $report.location)
        }
    }

    // MARK: - Narrative Section

    private var narrativeSection: some View {
        Section {
            TextEditor(text: $report.narrative)
                .frame(minHeight: 200)
        } header: {
            Text("Narrative")
        } footer: {
            Text("Describe the incident in detail, including what you observed, actions taken, and statements made.")
        }
    }

    // MARK: - Parties Section

    private var partiesSection: some View {
        Section("Involved Parties") {
            // Subjects
            DisclosureGroup {
                ForEach(report.subjects) { person in
                    PersonListRow(person: person, role: "Subject")
                }
                .onDelete { indexSet in
                    report.subjects.remove(atOffsets: indexSet)
                    hasChanges = true
                }

                Button(action: { showingPersonPicker = .subject }) {
                    Label("Add Subject", systemImage: "plus.circle")
                }
            } label: {
                HStack {
                    Label("Subjects", systemImage: "person.fill")
                    Spacer()
                    Text("\(report.subjects.count)")
                        .foregroundStyle(.secondary)
                }
            }

            // Victims
            DisclosureGroup {
                ForEach(report.victims) { person in
                    PersonListRow(person: person, role: "Victim")
                }
                .onDelete { indexSet in
                    report.victims.remove(atOffsets: indexSet)
                    hasChanges = true
                }

                Button(action: { showingPersonPicker = .victim }) {
                    Label("Add Victim", systemImage: "plus.circle")
                }
            } label: {
                HStack {
                    Label("Victims", systemImage: "person.fill")
                    Spacer()
                    Text("\(report.victims.count)")
                        .foregroundStyle(.secondary)
                }
            }

            // Witnesses
            DisclosureGroup {
                ForEach(report.witnesses) { person in
                    PersonListRow(person: person, role: "Witness")
                }
                .onDelete { indexSet in
                    report.witnesses.remove(atOffsets: indexSet)
                    hasChanges = true
                }

                Button(action: { showingPersonPicker = .witness }) {
                    Label("Add Witness", systemImage: "plus.circle")
                }
            } label: {
                HStack {
                    Label("Witnesses", systemImage: "person.fill")
                    Spacer()
                    Text("\(report.witnesses.count)")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Evidence Section

    private var evidenceSection: some View {
        Section("Evidence") {
            ForEach(report.evidence) { item in
                EvidenceListRow(item: item)
            }
            .onDelete { indexSet in
                report.evidence.remove(atOffsets: indexSet)
                hasChanges = true
            }

            Button(action: { showingEvidencePicker = true }) {
                Label("Add Evidence", systemImage: "plus.circle")
            }
        }
    }

    // MARK: - Validation

    private var isValid: Bool {
        !report.location.isEmpty && report.incidentType != .other
    }

    // MARK: - Actions

    private func saveReport() {
        isSaving = true
        Task {
            do {
                _ = try await reportService.saveReport(report)
                dismiss()
            } catch {
                // Handle error
                isSaving = false
            }
        }
    }

    private func addPerson(_ person: Person, type: PersonPickerType) {
        switch type {
        case .subject:
            report.subjects.append(person)
        case .victim:
            report.victims.append(person)
        case .witness:
            report.witnesses.append(person)
        }
        hasChanges = true
    }
}

// MARK: - Person Picker Type

enum PersonPickerType: Identifiable {
    case subject, victim, witness

    var id: String { title }

    var title: String {
        switch self {
        case .subject: return "Add Subject"
        case .victim: return "Add Victim"
        case .witness: return "Add Witness"
        }
    }
}

// MARK: - Person List Row

struct PersonListRow: View {
    let person: Person
    let role: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(person.fullName)
                .font(.body)
            if let phone = person.phone {
                Text(phone)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Evidence List Row

struct EvidenceListRow: View {
    let item: EvidenceItem

    var body: some View {
        HStack {
            Image(systemName: item.type.icon)
                .foregroundStyle(.purple)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(item.type.rawValue)
                        .font(.body)

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
                    .lineLimit(1)
            }

            Spacer()

            // Show first photo thumbnail if available
            if let firstPhoto = item.photos.first,
               let thumbnail = firstPhoto.loadThumbnail() {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
    }
}

// MARK: - Person Editor View

struct PersonEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    let person: Person?
    let onSave: (Person) -> Void

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var phone = ""
    @State private var address = ""
    @State private var gender = ""
    @State private var dateOfBirth: Date?
    @State private var showDatePicker = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                }

                Section("Contact") {
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                    TextField("Address", text: $address)
                }

                Section("Details") {
                    Picker("Gender", selection: $gender) {
                        Text("Not Specified").tag("")
                        Text("Male").tag("Male")
                        Text("Female").tag("Female")
                        Text("Other").tag("Other")
                    }

                    Toggle("Date of Birth", isOn: $showDatePicker)

                    if showDatePicker {
                        DatePicker(
                            "Date of Birth",
                            selection: Binding(
                                get: { dateOfBirth ?? Date() },
                                set: { dateOfBirth = $0 }
                            ),
                            displayedComponents: .date
                        )
                        .datePickerStyle(.graphical)
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let newPerson = Person(
                            firstName: firstName,
                            lastName: lastName,
                            dateOfBirth: dateOfBirth,
                            gender: gender.isEmpty ? nil : gender,
                            address: address.isEmpty ? nil : address,
                            phone: phone.isEmpty ? nil : phone
                        )
                        onSave(newPerson)
                        dismiss()
                    }
                    .disabled(firstName.isEmpty && lastName.isEmpty)
                }
            }
            .onAppear {
                if let person = person {
                    firstName = person.firstName
                    lastName = person.lastName
                    phone = person.phone ?? ""
                    address = person.address ?? ""
                    gender = person.gender ?? ""
                    dateOfBirth = person.dateOfBirth
                    showDatePicker = person.dateOfBirth != nil
                }
            }
        }
    }
}

// MARK: - Evidence Editor View

struct EvidenceEditorView: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (EvidenceItem) -> Void

    @State private var type: EvidenceType = .other
    @State private var description = ""
    @State private var location = ""
    @State private var photos: [EvidencePhoto] = []
    @State private var showingPhotoCapture = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Evidence Type") {
                    Picker("Type", selection: $type) {
                        ForEach(EvidenceType.allCases, id: \.self) { evidenceType in
                            Label(evidenceType.rawValue, systemImage: evidenceType.icon)
                                .tag(evidenceType)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }

                Section("Details") {
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(2...4)
                    TextField("Collection Location", text: $location)
                }

                Section {
                    if !photos.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(photos) { photo in
                                    EvidencePhotoThumbnail(photo: photo) {
                                        photos.removeAll { $0.id == photo.id }
                                    }
                                }
                            }
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }

                    Button(action: { showingPhotoCapture = true }) {
                        Label("Add Photos", systemImage: "camera.fill")
                    }
                } header: {
                    HStack {
                        Text("Photos")
                        Spacer()
                        if !photos.isEmpty {
                            Text("\(photos.count)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } footer: {
                    Text("Photos are stored locally and synced when connected.")
                }
            }
            .navigationTitle("Add Evidence")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let evidence = EvidenceItem(
                            type: type,
                            description: description,
                            location: location,
                            photos: photos
                        )
                        onSave(evidence)
                        dismiss()
                    }
                    .disabled(description.isEmpty)
                }
            }
            .sheet(isPresented: $showingPhotoCapture) {
                PhotoCaptureView { capturedPhoto in
                    if let savedPhoto = PhotoStorageService.shared.savePhoto(
                        capturedPhoto.image,
                        metadata: capturedPhoto.metadata
                    ) {
                        photos.append(savedPhoto)
                    }
                }
            }
        }
    }
}

// MARK: - Evidence Photo Thumbnail

struct EvidencePhotoThumbnail: View {
    let photo: EvidencePhoto
    let onDelete: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if let image = photo.loadThumbnail() {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 80)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    }
            }

            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.white)
                    .shadow(radius: 1)
            }
            .offset(x: 4, y: -4)
        }
    }
}

// MARK: - Preview

#Preview {
    ReportEditorView(
        report: Report(
            localCaseNumber: "DRAFT-12345",
            officialCaseNumber: nil,
            officerId: "OFF-001",
            officerName: "Officer Smith",
            badgeNumber: "12345"
        ),
        reportService: MockReportService()
    )
}
