import SwiftUI
import SwiftData
import AVFoundation

struct RootView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \TestDrive.startedAt, order: .reverse) private var drives: [TestDrive]
    @Query(sort: \DefectReport.createdAt, order: .reverse) private var defects: [DefectReport]
    @Query(sort: \DefectRecording.createdAt, order: .reverse) private var recordings: [DefectRecording]
    @AppStorage("selectedDriveUUID") private var selectedDriveUUID = ""
    @StateObject private var audio = AudioRecordingService()
    @State private var selectedTab = 0
    @State private var showNewDrive = false
    @State private var showRecoveryMessage = false
    @State private var selectedDefectID: UUID?

    // Selection is independent from completion. A new drive never closes another one.
    private var selectedDrive: TestDrive? {
        drives.first(where: { $0.id.uuidString == selectedDriveUUID }) ?? drives.first
    }
    private var selectedDefect: DefectReport? {
        guard let drive = selectedDrive else { return nil }
        return defects.first { $0.id == selectedDefectID && $0.driveID == drive.id }
    }
    private var recordingInProgress: Bool { audio.isRecording || audio.isPaused }

    var body: some View {
        TabView(selection: $selectedTab) {
            DriveListView(drives: drives, defects: defects, selectedDriveID: selectedDrive?.id,
                              showNewDrive: $showNewDrive, recordingInProgress: recordingInProgress,
                              onSelectDrive: selectDrive, recordings: recordings,
                              onNewDefect: { driveID in
                                  guard !recordingInProgress else { return }
                                  selectedDriveUUID = driveID.uuidString
                                  createDefect()
                                  selectedTab = 1
                              },
                              onAddRecording: { defect in
                                  guard !recordingInProgress else { return }
                                  selectedDriveUUID = defect.driveID.uuidString
                                  selectedDefectID = defect.id
                                  selectedTab = 1
                              })
            .tabItem { Label("Test Drives", systemImage: "car.fill") }.tag(0)

            NavigationStack {
                RecordingView(activeDrive: selectedDrive, activeDefect: selectedDefect,
                              driveDefects: defects.filter { $0.driveID == selectedDrive?.id },
                              recordings: recordings, audio: audio, onCreateDrive: { showNewDrive = true },
                              onCreateDefect: createDefect, onSelectDefect: { selectedDefectID = $0 },
                              onUpdateTrace: updateTrace)
            }
            .tabItem { Label("Recorder", systemImage: "mic.fill") }.tag(1)

            NavigationStack {
                DefectListView(defects: defects, recordings: recordings, drives: drives,
                               onSelectForRecording: { defect in
                    guard !recordingInProgress else { return }
                    selectedDriveUUID = defect.driveID.uuidString
                    selectedDefectID = defect.id
                    selectedTab = 1
                })
            }
            .tabItem { Label("Defects", systemImage: "list.bullet.rectangle") }.tag(2)
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showNewDrive) {
            NewDriveView(onCreated: { driveID in
                selectedDriveUUID = driveID.uuidString
                selectedDefectID = nil
                selectedTab = 1
            })
        }
        .onAppear {
            selectedTab = 0
            audio.onFinished = { id, driveID, defectID, path, duration, traceID, recordedAt in
                context.insert(DefectRecording(id: id, driveID: driveID, defectID: defectID,
                                               relativeAudioPath: path, duration: duration,
                                               status: "Saved", traceSessionID: traceID,
                                               recordedAt: recordedAt))
                if let defect = defects.first(where: { $0.id == defectID }) { defect.updatedAt = Date() }
                do { try context.save() }
                catch { audio.errorMessage = "Could not save recording metadata: \(error.localizedDescription)" }
                // Sprint 2: transcribe locally and update report automatically after each recording.
            }
            recoverPendingRecording()
        }
        .onChange(of: selectedDrive?.id) { _, _ in
            // Preserve a defect explicitly selected from the Defects tab for the destination drive.
            if !defects.contains(where: { $0.id == selectedDefectID && $0.driveID == selectedDrive?.id }) {
                selectedDefectID = nil
            }
        }
        .alert("Recovered Recording", isPresented: $showRecoveryMessage) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("An audio file from an interrupted session was found. Please check it in the defect details.")
        }
    }

    private func selectDrive(_ id: UUID) {
        guard !recordingInProgress else { return }
        selectedDriveUUID = id.uuidString
        selectedDefectID = nil
        // Keep Test Drive Details visible; the user explicitly navigates to Recorder.
    }

    private func createDefect() {
        guard let drive = selectedDrive, !recordingInProgress else { return }
        let number = (defects.filter { $0.driveID == drive.id }.map(\.number).max() ?? 0) + 1
        let defect = DefectReport(driveID: drive.id, number: number, traceSessionID: drive.activeTraceID)
        context.insert(defect)
        do {
            try context.save()
            selectedDefectID = defect.id
        } catch {
            context.delete(defect)
            audio.errorMessage = "Could not save defect: \(error.localizedDescription)"
        }
    }

    private func updateTrace(_ value: String) {
        guard let drive = selectedDrive, !recordingInProgress else { return }
        drive.activeTraceID = value.trimmingCharacters(in: .whitespacesAndNewlines)
        do { try context.save() }
        catch { audio.errorMessage = "Could not save Trace ID: \(error.localizedDescription)" }
    }

    private func recoverPendingRecording() {
        guard let marker = UserDefaults.standard.dictionary(forKey: "pendingRecording") as? [String: String],
              let idString = marker["id"], let id = UUID(uuidString: idString),
              let driveString = marker["driveID"], let driveID = UUID(uuidString: driveString),
              let defectString = marker["defectID"], let defectID = UUID(uuidString: defectString),
              let path = marker["file"] else { return }
        let url = AudioStore.url(for: path)
        guard FileManager.default.fileExists(atPath: url.path) else {
            UserDefaults.standard.removeObject(forKey: "pendingRecording")
            return
        }
        guard !recordings.contains(where: { $0.id == id }) else {
            UserDefaults.standard.removeObject(forKey: "pendingRecording")
            return
        }
        let duration = (try? AVAudioPlayer(contentsOf: url).duration) ?? 0
        context.insert(DefectRecording(id: id, driveID: driveID, defectID: defectID,
                                       relativeAudioPath: path, duration: duration, status: "Recovered – review",
                                       traceSessionID: marker["traceID"] ?? "",
                                       recordedAt: marker["recordedAt"].flatMap { ISO8601DateFormatter().date(from: $0) } ?? Date()))
        do {
            try context.save()
            UserDefaults.standard.removeObject(forKey: "pendingRecording")
            showRecoveryMessage = true
        } catch {
            audio.errorMessage = "Recovery could not be saved: \(error.localizedDescription)"
        }
    }
}
