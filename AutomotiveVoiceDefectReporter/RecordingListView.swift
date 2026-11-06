import SwiftUI
import SwiftData
import AVFoundation

struct DefectListView: View {
    let defects: [DefectReport]
    let recordings: [DefectRecording]
    let drives: [TestDrive]
    let onSelectForRecording: (DefectReport) -> Void
    @State private var search = ""
    @State private var player: AVAudioPlayer?
    @State private var playingID: UUID?
    @State private var playbackError: String?

    private var filtered: [DefectReport] {
        defects.filter { defect in
            search.isEmpty || defect.title.localizedCaseInsensitiveContains(search) ||
            defect.descriptionText.localizedCaseInsensitiveContains(search) ||
            defect.traceSessionID.localizedCaseInsensitiveContains(search) ||
            drives.first(where: { $0.id == defect.driveID })?.vehicleID.localizedCaseInsensitiveContains(search) == true
        }
    }

    var body: some View {
        List {
            ForEach(filtered) { defect in
                NavigationLink {
                    DefectDetailView(defect: defect,
                                     recordings: recordings.filter { $0.defectID == defect.id },
                                     onSelectForRecording: { onSelectForRecording(defect) })
                } label: {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(defect.title).font(.headline)
                        Text("\(recordings.filter { $0.defectID == defect.id }.count) voice recordings · \(defect.status)")
                            .font(.caption).foregroundStyle(.secondary)
                        if let drive = drives.first(where: { $0.id == defect.driveID }) {
                            Text("Vehicle: \(drive.vehicleID)").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 5)
                }
            }
        }
        .navigationTitle("Defect Reports")
        .searchable(text: $search, prompt: "Search defects")
        .overlay {
            if filtered.isEmpty {
                ContentUnavailableView(search.isEmpty ? "No Defect Reports Yet" : "No Matches",
                                       systemImage: "doc.text.magnifyingglass")
            }
        }
    }
}

struct DefectDetailView: View {
    @Environment(\.modelContext) private var context
    @Bindable var defect: DefectReport
    let recordings: [DefectRecording]
    let onSelectForRecording: () -> Void
    @State private var player: AVAudioPlayer?
    @State private var playingID: UUID?
    @State private var playbackError: String?

    var body: some View {
        Form {
            Section("Defect Report") {
                TextField("Title", text: $defect.title)
                TextField("Description / Notes", text: $defect.descriptionText, axis: .vertical)
                    .lineLimit(3...8)
                LabeledContent("Status", value: defect.status)
                LabeledContent("Defect Time", value: DefectTimeFormat.timestamp(defect.createdAt))
                TextField("Trace Session ID (Defect)", text: $defect.traceSessionID)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                Text("You can correct the defect Trace ID here. Each recording retains its own Trace ID.")
                    .font(.caption).foregroundStyle(.secondary)
                Text("AI transcription and automatic report updates are planned for Sprint 2.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("Voice Recordings (\(recordings.count))") {
                ForEach(recordings.sorted(by: { $0.createdAt < $1.createdAt })) { item in
                    VStack(alignment: .leading, spacing: 5) {
                        Text(DefectTimeFormat.timestamp(item.createdAt))
                        Text("Trace: " + (item.traceSessionID.isEmpty ? "Not specified" : item.traceSessionID))
                            .font(.caption).foregroundStyle(.secondary)
                        Text("\(Int(item.duration)) s · \(item.status)")
                            .font(.caption).foregroundStyle(.secondary)
                        Button {
                            if playingID == item.id {
                                player?.stop(); player = nil; playingID = nil
                            } else { play(item) }
                        } label: {
                            Label(playingID == item.id ? "Stop" : "Play Recording",
                                  systemImage: playingID == item.id ? "stop.fill" : "play.fill")
                        }
                    }
                }
                if recordings.isEmpty { Text("No recordings yet").foregroundStyle(.secondary) }
            }
            Section {
                Button("Add Recording to This Defect") { onSelectForRecording() }
            }
        }
        .navigationTitle(defect.title)
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { try? context.save(); player?.stop() }
        .alert("Playback", isPresented: Binding(get: { playbackError != nil }, set: { if !$0 { playbackError = nil } })) {
            Button("OK") { playbackError = nil }
        } message: { Text(playbackError ?? "") }
    }

    private func play(_ item: DefectRecording) {
        do {
            player?.stop()
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            let newPlayer = try AVAudioPlayer(contentsOf: AudioStore.url(for: item.relativeAudioPath))
            guard newPlayer.play() else { throw NSError(domain: "Playback", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not play audio file."]) }
            player = newPlayer
            playingID = item.id
        } catch { playbackError = error.localizedDescription }
    }
}
