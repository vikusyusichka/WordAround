import Foundation
import AVFoundation

enum ListeningAudioImportError: LocalizedError, Equatable {
    case unsupportedFormat
    case fileTooLarge
    case unreadable
    case copyFailed(String)

    var errorDescription: String? {
        switch self {
        case .unsupportedFormat:
            return "That file type isn't supported. Use MP3, M4A, WAV or AAC."
        case .fileTooLarge:
            return "That audio file is too large. Please pick a file under 50 MB."
        case .unreadable:
            return "We couldn't read that audio file. Try a different one."
        case .copyFailed(let message):
            return "Couldn't import the audio: \(message)"
        }
    }
}

struct ListeningImportedAudio: Equatable {
    let fileName: String          // stored filename inside the audio cache dir
    let originalName: String      // user-facing display name
    let url: URL
    let durationSeconds: Double
    let fileSizeBytes: Int

    var durationText: String {
        let seconds = Int(durationSeconds.rounded())
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    var fileSizeText: String {
        ByteCountFormatter.string(fromByteCount: Int64(fileSizeBytes), countStyle: .file)
    }
}

/// Copies an imported audio file into a dedicated cache directory and reads its
/// metadata (duration, size). Validation guards unsupported formats and
/// oversized files before any expensive work.
struct ListeningAudioImporter {

    static let supportedExtensions: Set<String> = ["mp3", "m4a", "wav", "aac"]
    private static let maxBytes = 50 * 1024 * 1024  // 50 MB

    /// Folder where imported audio lives. Created lazily.
    static func audioDirectory() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let dir = base.appendingPathComponent("ListeningAudio", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    func importAudio(from sourceURL: URL) async throws -> ListeningImportedAudio {
        let ext = sourceURL.pathExtension.lowercased()
        guard Self.supportedExtensions.contains(ext) else {
            throw ListeningAudioImportError.unsupportedFormat
        }

        // Security-scoped access is required for files outside the sandbox.
        let needsScope = sourceURL.startAccessingSecurityScopedResource()
        defer { if needsScope { sourceURL.stopAccessingSecurityScopedResource() } }

        let destination = Self.audioDirectory()
            .appendingPathComponent("\(UUID().uuidString).\(ext)")

        do {
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.copyItem(at: sourceURL, to: destination)
        } catch {
            throw ListeningAudioImportError.copyFailed(error.localizedDescription)
        }

        let attributes = try? FileManager.default.attributesOfItem(atPath: destination.path)
        let fileSize = (attributes?[.size] as? Int) ?? 0
        guard fileSize <= Self.maxBytes else {
            try? FileManager.default.removeItem(at: destination)
            throw ListeningAudioImportError.fileTooLarge
        }

        let asset = AVURLAsset(url: destination)
        let duration: Double
        do {
            let cmDuration = try await asset.load(.duration)
            duration = CMTimeGetSeconds(cmDuration)
        } catch {
            try? FileManager.default.removeItem(at: destination)
            throw ListeningAudioImportError.unreadable
        }
        guard duration.isFinite, duration > 0 else {
            try? FileManager.default.removeItem(at: destination)
            throw ListeningAudioImportError.unreadable
        }

        return ListeningImportedAudio(
            fileName: destination.lastPathComponent,
            originalName: sourceURL.lastPathComponent,
            url: destination,
            durationSeconds: duration,
            fileSizeBytes: fileSize
        )
    }

    /// Removes a stored audio file (e.g. when a session is deleted).
    static func deleteAudio(fileName: String) {
        let url = audioDirectory().appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: url)
    }
}
