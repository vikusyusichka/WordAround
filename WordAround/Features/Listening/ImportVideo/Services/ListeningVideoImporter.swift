import Foundation
import AVFoundation

enum ListeningVideoImportError: LocalizedError, Equatable {
    case unsupportedFormat
    case fileTooLarge
    case unreadable
    case copyFailed(String)

    var errorDescription: String? {
        switch self {
        case .unsupportedFormat:
            return "That file type isn't supported. Use MP4, MOV or M4V."
        case .fileTooLarge:
            return "That video is too large. Please pick a file under 80 MB."
        case .unreadable:
            return "We couldn't read that video file. Try a different one."
        case .copyFailed(let message):
            return "Couldn't import the video: \(message)"
        }
    }
}

struct ListeningImportedVideo: Equatable {
    let fileName: String
    let originalName: String
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

struct ListeningVideoImporter {
    static let supportedExtensions: Set<String> = ["mp4", "mov", "m4v"]
    /// 80 MB keeps the upload under the Cloudflare 100 MB request-body limit.
    static let maxBytes = 80 * 1024 * 1024

    static func videoDirectory() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let dir = base.appendingPathComponent("ListeningVideo", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    func importVideo(from sourceURL: URL) async throws -> ListeningImportedVideo {
        let ext = sourceURL.pathExtension.lowercased()
        guard Self.supportedExtensions.contains(ext) else {
            throw ListeningVideoImportError.unsupportedFormat
        }

        let needsScope = sourceURL.startAccessingSecurityScopedResource()
        defer { if needsScope { sourceURL.stopAccessingSecurityScopedResource() } }

        if let preSize = (try? sourceURL.resourceValues(forKeys: [.fileSizeKey]))?.fileSize,
           preSize > Self.maxBytes {
            throw ListeningVideoImportError.fileTooLarge
        }

        let destination = Self.videoDirectory()
            .appendingPathComponent("\(UUID().uuidString).\(ext)")
        do {
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.copyItem(at: sourceURL, to: destination)
        } catch {
            throw ListeningVideoImportError.copyFailed(error.localizedDescription)
        }

        let attributes = try? FileManager.default.attributesOfItem(atPath: destination.path)
        let fileSize = (attributes?[.size] as? Int) ?? 0
        guard fileSize <= Self.maxBytes else {
            try? FileManager.default.removeItem(at: destination)
            throw ListeningVideoImportError.fileTooLarge
        }

        let asset = AVURLAsset(url: destination)
        let duration: Double
        do {
            duration = CMTimeGetSeconds(try await asset.load(.duration))
        } catch {
            try? FileManager.default.removeItem(at: destination)
            throw ListeningVideoImportError.unreadable
        }
        guard duration.isFinite, duration > 0 else {
            try? FileManager.default.removeItem(at: destination)
            throw ListeningVideoImportError.unreadable
        }

        return ListeningImportedVideo(
            fileName: destination.lastPathComponent,
            originalName: sourceURL.lastPathComponent,
            url: destination,
            durationSeconds: duration,
            fileSizeBytes: fileSize
        )
    }

    func extractAudio(from videoURL: URL) async -> URL {
        let asset = AVURLAsset(url: videoURL)
        let outputURL = Self.videoDirectory()
            .appendingPathComponent("\(UUID().uuidString).m4a")
        try? FileManager.default.removeItem(at: outputURL)

        guard let export = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            return videoURL
        }
        do {
            try await export.export(to: outputURL, as: .m4a)
            if FileManager.default.fileExists(atPath: outputURL.path) {
                return outputURL
            }
        } catch {
        }
        return videoURL
    }

    static func deleteVideo(fileName: String) {
        let url = videoDirectory().appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: url)
    }
}
