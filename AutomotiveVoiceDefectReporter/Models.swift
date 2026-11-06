import Foundation
import SwiftData

@Model
final class TestDrive {
    @Attribute(.unique) var id: UUID
    var vehicleID: String
    var softwareVersion: String
    var tester: String
    var startedAt: Date
    // Retained only for compatibility with Sprint 1.2 SwiftData stores.
    // No longer used to determine selection or to restrict editing.
    var endedAt: Date?
    var activeTraceID: String = ""

    init(vehicleID: String, softwareVersion: String, tester: String) {
        self.id = UUID()
        self.vehicleID = vehicleID
        self.softwareVersion = softwareVersion
        self.tester = tester
        self.startedAt = Date()
    }

    var shortID: String { String(id.uuidString.prefix(8)) }
}

@Model
final class DefectReport {
    @Attribute(.unique) var id: UUID
    var driveID: UUID
    var number: Int
    var createdAt: Date
    var title: String
    var descriptionText: String
    var status: String
    var updatedAt: Date
    var traceSessionID: String = ""

    init(driveID: UUID, number: Int, traceSessionID: String = "") {
        self.id = UUID()
        self.driveID = driveID
        self.number = number
        self.traceSessionID = traceSessionID
        self.createdAt = Date()
        self.updatedAt = Date()
        self.title = "Defect #" + String(format: "%03d", number)
        self.descriptionText = ""
        self.status = "Draft"
    }
}

@Model
final class DefectRecording {
    @Attribute(.unique) var id: UUID
    var driveID: UUID
    var defectID: UUID
    var createdAt: Date
    var relativeAudioPath: String
    var traceSessionID: String = ""
    var duration: TimeInterval
    var title: String
    var status: String

    init(id: UUID = UUID(), driveID: UUID, defectID: UUID, relativeAudioPath: String, duration: TimeInterval = 0, status: String = "Recording", traceSessionID: String = "", recordedAt: Date = Date()) {
        self.id = id
        self.driveID = driveID
        self.defectID = defectID
        self.createdAt = recordedAt
        self.traceSessionID = traceSessionID
        self.relativeAudioPath = relativeAudioPath
        self.duration = duration
        self.title = "Voice recording " + recordedAt.formatted(date: .omitted, time: .shortened)
        self.status = status
    }
}


enum DefectTimeFormat {
    static func timestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd (EEEE), HH:mm:ss"
        return formatter.string(from: date)
    }
}
