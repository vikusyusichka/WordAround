import Foundation

struct ListeningVideoItem: Identifiable, Equatable, Hashable {
    let id: String
    let title: String
    /// Channel or source name shown below the title.
    let channel: String
    let durationText: String
    let difficultyTitle: String
    let hasCaptions: Bool
    /// Duration in seconds, used for filtering by length.
    var durationSeconds: Int = 0
    /// Remote thumbnail image URL string. Shown in the video card; falls back
    /// to the play-icon placeholder when nil or when loading fails.
    var thumbnailURL: String? = nil
    /// Direct playable URL (e.g. YouTube watch URL). Used by the session screen.
    var playableURL: String? = nil
    /// Source URL stored for bookmarking / display (same as playableURL for YouTube).
    var sourceURL: String? = nil
    /// Captions/transcript text when available — used to build questions.
    var transcriptText: String? = nil

    /// Convenience alias matching the requirement field name.
    var sourceName: String { channel }

    /// A video supports comprehension questions only when a transcript exists.
    var supportsQuestions: Bool {
        hasCaptions && !(transcriptText?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
    }

    /// A directly playable media URL suitable for a future native `AVPlayer`.
    /// YouTube watch pages are NOT natively playable, so they return `nil` and
    /// the UI falls back to "Open in YouTube".
    var nativePlayerURL: URL? {
        guard let playableURL, let url = URL(string: playableURL) else { return nil }
        let host = url.host?.lowercased() ?? ""
        if host.contains("youtube.com") || host.contains("youtu.be") { return nil }
        let ext = url.pathExtension.lowercased()
        return ["mp4", "m4v", "mov", "m3u8"].contains(ext) ? url : nil
    }

    /// `true` when the only way to watch is an external app/browser (e.g. YouTube).
    var requiresExternalPlayback: Bool { nativePlayerURL == nil }

    var watchURL: URL? {
        // Prefer explicit playable URL.
        if let playableURL, let url = URL(string: playableURL) { return url }
        if let sourceURL, let videoID = Self.extractYouTubeVideoID(from: sourceURL) {
            return URL(string: "https://www.youtube.com/watch?v=\(videoID)")
        }
        if Self.isValidYouTubeVideoID(id) {
            return URL(string: "https://www.youtube.com/watch?v=\(id)")
        }
        return nil
    }

    static func isValidYouTubeVideoID(_ value: String) -> Bool {
        guard value.count == 11 else { return false }
        let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-")
        return value.unicodeScalars.allSatisfy { allowed.contains($0) }
    }

    static func extractYouTubeVideoID(from urlString: String) -> String? {
        guard let url = URL(string: urlString) else { return nil }
        if let queryID = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first(where: { $0.name == "v" })?
            .value,
           isValidYouTubeVideoID(queryID) {
            return queryID
        }
        let pathID = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return isValidYouTubeVideoID(pathID) ? pathID : nil
    }
}
