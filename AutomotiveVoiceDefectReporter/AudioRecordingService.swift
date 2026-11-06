import Foundation
import AVFoundation
import Combine

@MainActor
final class AudioRecordingService: NSObject, ObservableObject, AVAudioRecorderDelegate {
    @Published private(set) var isRecording = false
    @Published private(set) var isPaused = false
    @Published private(set) var elapsed: TimeInterval = 0
    @Published private(set) var level: Float = 0
    @Published var errorMessage: String?

    private var recorder: AVAudioRecorder?
    private var ticker: Timer?
    private var currentID: UUID?
    private var currentDriveID: UUID?
    private var currentDefectID: UUID?
    private var currentTraceID = ""
    private var currentRecordedAt = Date()
    private var startDate: Date?
    private var pausedDuration: TimeInterval = 0
    private var pauseStartedAt: Date?
    var onFinished: ((UUID, UUID, UUID, String, TimeInterval, String, Date) -> Void)?

    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption(_:)), name: AVAudioSession.interruptionNotification, object: nil)
    }

    func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    func start(driveID: UUID, defectID: UUID, traceSessionID: String) async {
        guard !isRecording, !isPaused else { return }
        guard await requestPermission() else {
            errorMessage = "Bitte erlaube den Mikrofonzugriff in den iPhone-Einstellungen."
            return
        }
        do {
            try AudioStore.prepare()
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothHFP])
            try session.setActive(true)
            let id = UUID()
            let fileName = "\(id.uuidString).m4a"
            let url = AudioStore.url(for: fileName)
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 1,
                AVEncoderBitRateKey: 96000
            ]
            let newRecorder = try AVAudioRecorder(url: url, settings: settings)
            newRecorder.delegate = self
            newRecorder.isMeteringEnabled = true
            guard newRecorder.record() else { throw NSError(domain: "Audio", code: 1, userInfo: [NSLocalizedDescriptionKey: "Aufnahme konnte nicht gestartet werden."]) }
            try AudioStore.protect(url)
            recorder = newRecorder
            currentID = id
            currentDriveID = driveID
            currentDefectID = defectID
            currentTraceID = traceSessionID
            currentRecordedAt = Date()
            startDate = Date()
            pausedDuration = 0
            pauseStartedAt = nil
            elapsed = 0
            isRecording = true
            isPaused = false
            startTicker()
            // Persisted recovery marker is written before returning to UI.
            UserDefaults.standard.set(["id": id.uuidString, "driveID": driveID.uuidString, "defectID": defectID.uuidString, "file": fileName, "traceID": traceSessionID, "recordedAt": ISO8601DateFormatter().string(from: currentRecordedAt)], forKey: "pendingRecording")
        } catch {
            errorMessage = "Aufnahme fehlgeschlagen: \(error.localizedDescription)"
        }
    }

    func stop() {
        guard let recorder, let id = currentID, let driveID = currentDriveID, let defectID = currentDefectID else { return }
        let path = recorder.url.lastPathComponent
        let length = recorder.currentTime
        recorder.stop()
        finish(id: id, driveID: driveID, defectID: defectID, path: path, duration: length)
    }

    private func finish(id: UUID, driveID: UUID, defectID: UUID, path: String, duration: TimeInterval) {
        ticker?.invalidate()
        ticker = nil
        recorder = nil
        isRecording = false
        isPaused = false
        elapsed = duration
        level = 0
        currentID = nil
        currentDriveID = nil
        currentDefectID = nil
        let finishedTraceID = currentTraceID
        let finishedRecordedAt = currentRecordedAt
        currentTraceID = ""
        startDate = nil
        pauseStartedAt = nil
        onFinished?(id, driveID, defectID, path, duration, finishedTraceID, finishedRecordedAt)
        UserDefaults.standard.removeObject(forKey: "pendingRecording")
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func startTicker() {
        ticker?.invalidate()
        ticker = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let recorder = self.recorder else { return }
                self.elapsed = recorder.currentTime
                if self.isRecording {
                    recorder.updateMeters()
                    self.level = max(0, min(1, (recorder.averagePower(forChannel: 0) + 55) / 55))
                }
            }
        }
    }

    @objc private nonisolated func handleInterruption(_ notification: Notification) {
        let raw = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
        let optionsRaw = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
        Task { @MainActor in
            guard let raw, let kind = AVAudioSession.InterruptionType(rawValue: raw) else { return }
            switch kind {
            case .began:
                if self.isRecording {
                    self.recorder?.pause()
                    self.isRecording = false
                    self.isPaused = true
                }
            case .ended:
                guard self.isPaused else { return }
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsRaw)
                if options.contains(.shouldResume) {
                    do {
                        try AVAudioSession.sharedInstance().setActive(true)
                        if self.recorder?.record() == true {
                            self.isRecording = true
                            self.isPaused = false
                        }
                    } catch { self.errorMessage = "Aufnahme pausiert. Bitte erneut fortsetzen." }
                }
            @unknown default: break
            }
        }
    }

    func resume() {
        guard isPaused else { return }
        do {
            try AVAudioSession.sharedInstance().setActive(true)
            if recorder?.record() == true { isPaused = false; isRecording = true }
        } catch { errorMessage = error.localizedDescription }
    }

    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        Task { @MainActor in
            self.errorMessage = error?.localizedDescription ?? "Fehler beim Schreiben der Audiodatei."
            self.stop()
        }
    }
}
