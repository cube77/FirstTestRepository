import Foundation

struct AudioStore {
    static var directory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("Recordings", isDirectory: true)
    }

    static func prepare() throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    static func url(for relativePath: String) -> URL {
        directory.appendingPathComponent((relativePath as NSString).lastPathComponent)
    }

    static func protect(_ url: URL) throws {
        // Allows a file opened while unlocked to continue being written after device lock.
        try FileManager.default.setAttributes([.protectionKey: FileProtectionType.completeUnlessOpen], ofItemAtPath: url.path)
    }
}
