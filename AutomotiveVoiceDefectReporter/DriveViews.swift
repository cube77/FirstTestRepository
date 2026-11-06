import SwiftUI
import SwiftData

struct DriveListView: View {
    let drives: [TestDrive]
    let defects: [DefectReport]
    let selectedDriveID: UUID?
    @Binding var showNewDrive: Bool
    let recordingInProgress: Bool
    let onSelectDrive: (UUID) -> Void
    let recordings: [DefectRecording]
    let onNewDefect: (UUID) -> Void
    let onAddRecording: (DefectReport) -> Void

    // Keep navigation state local to this tab. Updating the selected drive must not
    // recreate or dismiss the detail screen on a physical iPhone.
    @State private var drivePath: [UUID] = []

    var body: some View {
        NavigationStack(path: $drivePath) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Test Drives")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)
                        .padding(.top, 8)

                    HStack(spacing: 10) {
                        summary("\(drives.count)", "Total Drives")
                        summary(drives.isEmpty ? "0" : "1", "Selected")
                        summary("\(defects.count)", "Defects")
                    }

                    Button { showNewDrive = true } label: {
                        Label("New Test Drive", systemImage: "plus")
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 48)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(recordingInProgress)

                    Text("Your Test Drives")
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                        .padding(.top, 6)

                    ForEach(drives) { drive in
                        Button {
                            guard !recordingInProgress else { return }
                            // Select first, then push using a stable, explicit path.
                            onSelectDrive(drive.id)
                            drivePath.append(drive.id)
                        } label: {
                            HStack(alignment: .center, spacing: 12) {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text(drive.vehicleID)
                                            .font(.headline)
                                            .foregroundStyle(.white)
                                        Spacer(minLength: 6)
                                        if selectedDriveID == drive.id {
                                            Text("Selected")
                                                .font(.caption.bold())
                                                .foregroundStyle(.green)
                                        }
                                    }
                                    Text("SW: \(drive.softwareVersion) · Driver: \(drive.tester)")
                                        .font(.subheadline)
                                        .foregroundStyle(.white.opacity(0.75))
                                    Text("\(drive.startedAt.formatted(date: .abbreviated, time: .shortened)) · \(defects.filter { $0.driveID == drive.id }.count) defects")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.65))
                                }
                                Image(systemName: "chevron.right")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.white.opacity(0.65))
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(red: 0.09, green: 0.16, blue: 0.25), in: RoundedRectangle(cornerRadius: 16))
                            .contentShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .buttonStyle(.plain)
                        .disabled(recordingInProgress)
                        .accessibilityHint("Opens test drive details")
                    }

                    if drives.isEmpty {
                        ContentUnavailableView("No Test Drives Yet", systemImage: "car", description: Text("Create your first test drive."))
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 28)
            }
            .background(Color(red: 0.035, green: 0.065, blue: 0.11))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showNewDrive = true } label: { Image(systemName: "plus") }
                        .disabled(recordingInProgress)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: UUID.self) { driveID in
                if let drive = drives.first(where: { $0.id == driveID }) {
                    TestDriveDetailView(drive: drive,
                                        defects: defects.filter { $0.driveID == driveID },
                                        recordings: recordings,
                                        onNewDefect: { onNewDefect(driveID) },
                                        onAddRecording: onAddRecording)
                } else {
                    ContentUnavailableView("Test Drive Not Found", systemImage: "car")
                }
            }
        }
    }

    private func summary(_ value: String, _ caption: String) -> some View {
        VStack(spacing: 5) {
            Text(value).font(.title2.bold()).foregroundStyle(.white)
            Text(caption).font(.caption2).foregroundStyle(.white.opacity(0.75))
                .lineLimit(1).minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, minHeight: 70)
        .background(Color(red: 0.09, green: 0.16, blue: 0.25), in: RoundedRectangle(cornerRadius: 12))
    }

}

struct NewDriveView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let onCreated: (UUID) -> Void
    @State private var vehicleID = ""
    @State private var softwareVersion = ""
    @State private var tester = ""
    @State private var traceID = ""
    @State private var saveError: String?

    var body: some View {
        NavigationStack {
            Form {
                TextField("Vehicle ID / VIN", text: $vehicleID)
                TextField("Software Version", text: $softwareVersion)
                TextField("Driver / Initials", text: $tester)
                TextField("Initial Trace Session ID (optional)", text: $traceID)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                LabeledContent("Start Time", value: Date().formatted(date: .abbreviated, time: .shortened))
            }
            .navigationTitle("New Test Drive")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { createDrive() }
                        .disabled(vehicleID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                                  softwareVersion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                                  tester.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert("Could Not Save Test Drive", isPresented: Binding(get: { saveError != nil }, set: { if !$0 { saveError = nil } })) {
                Button("OK") { saveError = nil }
            } message: { Text(saveError ?? "") }
        }
    }

    private func createDrive() {
        let drive = TestDrive(vehicleID: vehicleID.trimmingCharacters(in: .whitespacesAndNewlines),
                              softwareVersion: softwareVersion.trimmingCharacters(in: .whitespacesAndNewlines),
                              tester: tester.trimmingCharacters(in: .whitespacesAndNewlines))
        drive.activeTraceID = traceID.trimmingCharacters(in: .whitespacesAndNewlines)
        context.insert(drive)
        do {
            try context.save()
            onCreated(drive.id)
            dismiss()
        } catch {
            context.delete(drive)
            saveError = error.localizedDescription
        }
    }
}


// Original navigation restored: Test Drives -> Test Drive Details -> Defect Details.
struct TestDriveDetailView: View {
    @Environment(\.modelContext) private var context
    @Bindable var drive: TestDrive
    let defects: [DefectReport]
    let recordings: [DefectRecording]
    let onNewDefect: () -> Void
    let onAddRecording: (DefectReport) -> Void
    @State private var traceDraft = ""
    @State private var saveError: String?

    var body: some View {
        List {
            Section("Test Drive") {
                LabeledContent("Vehicle ID", value: drive.vehicleID)
                LabeledContent("Software Version", value: drive.softwareVersion)
                LabeledContent("Driver", value: drive.tester)
                LabeledContent("Start Time", value: DefectTimeFormat.timestamp(drive.startedAt))
                Label("Selected – editable anytime", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
            Section("Active Trace Session") {
                TextField("Trace Session ID", text: $traceDraft)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .onSubmit(saveTrace)
                HStack {
                    Text("Current: " + (drive.activeTraceID.isEmpty ? "Not specified" : drive.activeTraceID))
                        .font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Button("Apply", action: saveTrace).buttonStyle(.borderedProminent)
                }
            }
            Section("Recorded Defects (\(defects.count))") {
                ForEach(defects.sorted(by: { $0.number < $1.number })) { defect in
                    NavigationLink {
                        DefectDetailView(defect: defect,
                                         recordings: recordings.filter { $0.defectID == defect.id },
                                         onSelectForRecording: { onAddRecording(defect) })
                    } label: {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(defect.title).font(.headline)
                            Text("\(recordings.filter { $0.defectID == defect.id }.count) voice recordings · \(defect.status)")
                                .font(.caption).foregroundStyle(.secondary)
                            Text(DefectTimeFormat.timestamp(defect.createdAt))
                                .font(.caption2).foregroundStyle(.secondary)
                        }.padding(.vertical, 5)
                    }
                }
                Button(action: onNewDefect) {
                    Label("New Defect", systemImage: "plus.rectangle.on.rectangle")
                        .frame(maxWidth: .infinity, minHeight: 42)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .navigationTitle(drive.vehicleID)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { traceDraft = drive.activeTraceID }
        .alert("Could Not Save Trace ID", isPresented: Binding(get: { saveError != nil }, set: { if !$0 { saveError = nil } })) {
            Button("OK") { saveError = nil }
        } message: { Text(saveError ?? "") }
    }

    private func saveTrace() {
        let previous = drive.activeTraceID
        drive.activeTraceID = traceDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        do { try context.save() }
        catch { drive.activeTraceID = previous; saveError = error.localizedDescription }
    }
}
