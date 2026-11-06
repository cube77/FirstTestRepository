import SwiftUI

struct RecordingView: View {
    let activeDrive: TestDrive?
    let activeDefect: DefectReport?
    let driveDefects: [DefectReport]
    let recordings: [DefectRecording]
    @ObservedObject var audio: AudioRecordingService
    let onCreateDrive: () -> Void
    let onCreateDefect: () -> Void
    let onSelectDefect: (UUID) -> Void
    let onUpdateTrace: (String) -> Void
    @State private var traceDraft = ""

    private var isBusy: Bool { audio.isRecording || audio.isPaused }
    private var timeText: String {
        let seconds = Int(audio.elapsed)
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                if let drive = activeDrive {
                    VStack(spacing: 5) {
                        Text("Selected Test Drive").foregroundStyle(.secondary)
                        Text(drive.vehicleID).font(.title2.bold())
                        Text("SW \(drive.softwareVersion) · \(drive.tester)")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)

                    VStack(alignment: .leading, spacing: 10) {
                        Label("Active Trace Session", systemImage: "waveform.path")
                            .font(.headline)
                        TextField("Enter Trace Session ID", text: $traceDraft)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .textFieldStyle(.roundedBorder)
                            .disabled(isBusy)
                            .onSubmit { onUpdateTrace(traceDraft) }
                        HStack {
                            Text("Current: " + (drive.activeTraceID.isEmpty ? "Not specified" : drive.activeTraceID))
                                .font(.caption).foregroundStyle(.secondary)
                            Spacer()
                            Button("Apply") { onUpdateTrace(traceDraft) }
                                .buttonStyle(.borderedProminent)
                                .disabled(isBusy)
                        }
                        Text("New defects and recordings use the current Trace ID. Voice entry is planned for Sprint 2.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(activeDefect?.title ?? "No defect selected").font(.headline)
                                if let defect = activeDefect {
                                    let count = recordings.filter { $0.defectID == defect.id }.count
                                    Text("\(count) voice recording(s) · \(defect.status)")
                                    Text("Defect time: " + DefectTimeFormat.timestamp(defect.createdAt))
                                        .font(.caption).foregroundStyle(.secondary)
                                    Text("Trace at defect creation: " + (defect.traceSessionID.isEmpty ? "Not specified" : defect.traceSessionID))
                                        .font(.caption).foregroundStyle(.secondary)
                                } else {
                                    Text("Create a defect report first.")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            if activeDefect != nil { Label("Selected", systemImage: "checkmark.circle.fill").font(.caption).foregroundStyle(.green) }
                        }
                        if !driveDefects.isEmpty {
                            Picker("Select Defect", selection: Binding(
                                get: { activeDefect?.id },
                                set: { if let id = $0 { onSelectDefect(id) } }
                            )) {
                                Text("Please select").tag(Optional<UUID>.none)
                                ForEach(driveDefects.sorted(by: { $0.number < $1.number })) { defect in
                                    Text(defect.title).tag(Optional(defect.id))
                                }
                            }
                            .disabled(isBusy)
                        }
                    }
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))

                    Button(action: onCreateDefect) {
                        Label("New Defect", systemImage: "plus.rectangle.on.rectangle")
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 52)
                    }
                    .buttonStyle(.bordered)
                    .disabled(isBusy)

                    Text(timeText)
                        .font(.system(size: 48, weight: .medium, design: .monospaced))
                        .monospacedDigit()

                    HStack(alignment: .center, spacing: 4) {
                        ForEach(0..<21, id: \.self) { index in
                            Capsule()
                                .fill(audio.isRecording ? Color.red : Color.gray)
                                .frame(width: 5, height: CGFloat(8 + Int(audio.level * 65 * Float(index % 5 + 2)) / 6))
                        }
                    }.frame(height: 65)

                    Button {
                        if isBusy { audio.stop() }
                        else if let defect = activeDefect {
                            Task { await audio.start(driveID: drive.id, defectID: defect.id, traceSessionID: drive.activeTraceID) }
                        }
                    } label: {
                        VStack(spacing: 10) {
                            Image(systemName: isBusy ? "stop.fill" : "mic.fill")
                                .font(.system(size: 42))
                            Text(isBusy ? "Stop Recording" : "Start Recording").font(.headline)
                        }
                        .foregroundStyle(.white)
                        .frame(width: 194, height: 194)
                        .background(isBusy ? Color.red : Color.blue, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .disabled(activeDefect == nil && !isBusy)
                    .opacity(activeDefect == nil && !isBusy ? 0.45 : 1)

                    if audio.isPaused {
                        Label("Recording interrupted", systemImage: "pause.circle").foregroundStyle(.orange)
                        Button("Resume") { audio.resume() }.buttonStyle(.borderedProminent)
                    } else {
                        Label(audio.isRecording ? "Recording" : "Recorder ready",
                              systemImage: audio.isRecording ? "record.circle" : "checkmark.circle")
                            .foregroundStyle(audio.isRecording ? .red : .secondary)
                    }
                    Text("Select an existing defect later to add more recordings.")
                        .font(.caption).multilineTextAlignment(.center).foregroundStyle(.secondary)
                    Text("Do not operate while driving. Ask a passenger or stop safely.")
                        .font(.caption).multilineTextAlignment(.center).foregroundStyle(.secondary)
                } else {
                    ContentUnavailableView("No Test Drive Selected", systemImage: "car",
                                           description: Text("Create a test drive first."))
                    Button("New Test Drive") { onCreateDrive() }.buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Recorder")
        .onAppear { traceDraft = activeDrive?.activeTraceID ?? "" }
        .onChange(of: activeDrive?.id) { _, _ in traceDraft = activeDrive?.activeTraceID ?? "" }
        .alert("Audio Recording", isPresented: Binding(get: { audio.errorMessage != nil }, set: { if !$0 { audio.errorMessage = nil } })) {
            Button("OK") { audio.errorMessage = nil }
        } message: { Text(audio.errorMessage ?? "") }
    }
}
