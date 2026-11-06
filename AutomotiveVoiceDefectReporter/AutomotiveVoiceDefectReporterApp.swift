import SwiftUI
import SwiftData

@main
struct AutomotiveVoiceDefectReporterApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [TestDrive.self, DefectReport.self, DefectRecording.self])
    }
}
