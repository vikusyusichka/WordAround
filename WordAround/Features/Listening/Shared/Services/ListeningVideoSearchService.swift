import Foundation

/// Builds level-aware search keywords. Shared by every search backend so query
/// logic lives in one place.
enum ListeningVideoQueryBuilder {
    static func keywords(language: GrammarLanguage, level: EssayDifficulty, topic: String) -> String {
        let levelTerms: String
        switch level {
        case .a1, .a2:
            levelTerms = "easy beginner slow simple conversation"
        case .b1, .b2:
            levelTerms = "intermediate conversation story explanation"
        case .c1, .native:
            levelTerms = "interview podcast documentary news"
        }
        let cleanedTopic = topic.trimmingCharacters(in: .whitespacesAndNewlines)
        return "\(language.title) \(cleanedTopic) \(levelTerms) for learners"
            .replacingOccurrences(of: "  ", with: " ")
    }

    /// (minSeconds, maxSeconds) duration window for the requested length.
    static func durationWindow(for length: ListeningVideoLength) -> (min: Int, max: Int) {
        switch length {
        case .short:  return (60, 5 * 60)
        case .medium: return (5 * 60, 12 * 60)
        case .long:   return (12 * 60, 20 * 60)
        }
    }
}

/// Mock search backend for previews/tests and as a graceful fallback when no
/// real API key is configured. Generates plausible, level-appropriate results
/// so the entire UI flow works without a network.
struct MockListeningVideoSearchService: ListeningVideoSearching {

    /// Stable public YouTube IDs so mock search results open real videos.
    private static let demoVideoIDs = [
        "aqz-KE-bpKQ",
        "LXb3EKWsInQ",
        "eRsGyueVVak"
    ]

    func search(
        language: GrammarLanguage,
        level: EssayDifficulty,
        topic: String,
        length: ListeningVideoLength
    ) async throws -> [ListeningVideoItem] {
        // Empty topic is fine — use a sensible default.
        let cleaned = topic.trimmingCharacters(in: .whitespacesAndNewlines)
        let effectiveTopic = cleaned.isEmpty ? "conversation" : cleaned

        // Simulate a short network delay so loading states are visible.
        try? await Task.sleep(nanoseconds: 600_000_000)

        let window = ListeningVideoQueryBuilder.durationWindow(for: length)
        let sampleDurations = [window.min + 30, (window.min + window.max) / 2, window.max - 20]
        let channels = ["\(language.title) Everyday", "Learn \(language.title)", "\(effectiveTopic.capitalized) Talks"]
        let titles = [
            "\(effectiveTopic.capitalized) — Real \(language.title) Conversations",
            "A Story About \(effectiveTopic.capitalized) (\(level.title))",
            "\(effectiveTopic.capitalized): Everyday \(language.title)"
        ]

        let transcript = ListeningPlaceholderData.sampleText
        return (0..<3).map { i in
            let withCaptions = i != 2  // last result has no captions → watch-only
            let videoID = Self.demoVideoIDs[i % Self.demoVideoIDs.count]
            let durationSec = sampleDurations[i % sampleDurations.count]
            return ListeningVideoItem(
                id: videoID,
                title: titles[i % titles.count],
                channel: channels[i % channels.count],
                durationText: Self.durationText(durationSec),
                difficultyTitle: level.title,
                hasCaptions: withCaptions,
                durationSeconds: durationSec,
                thumbnailURL: "https://img.youtube.com/vi/\(videoID)/hqdefault.jpg",
                playableURL: "https://www.youtube.com/watch?v=\(videoID)",
                sourceURL: "https://www.youtube.com/watch?v=\(videoID)",
                transcriptText: withCaptions ? transcript : nil
            )
        }
    }

    private static func durationText(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

/// YouTube Data API v3 search backend. Requires an API key in Info.plist under
/// `YouTubeAPIKey`. When the key is missing or the request fails, callers fall
/// back to `MockListeningVideoSearchService` so the flow still works.
///
/// Note: the search endpoint reports `caption` availability; the actual caption
/// *text* is not exposed by the public Data API, so videos are returned with
/// `hasCaptions` set but without `transcriptText` (watch-only) unless a
/// transcript source is wired in later.
struct YouTubeListeningVideoSearchService: ListeningVideoSearching {

    private let apiKey: String?
    private let session: URLSession

    init(apiKey: String? = Bundle.main.object(forInfoDictionaryKey: "YouTubeAPIKey") as? String,
         session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    func search(
        language: GrammarLanguage,
        level: EssayDifficulty,
        topic: String,
        length: ListeningVideoLength
    ) async throws -> [ListeningVideoItem] {
        let cleaned = topic.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let apiKey, !apiKey.isEmpty else {
            throw ListeningVideoSearchError.requestFailed("Missing YouTube API key")
        }

        let effectiveTopic = cleaned.isEmpty ? "conversation" : cleaned
        let query = ListeningVideoQueryBuilder.keywords(language: language, level: level, topic: effectiveTopic)
        let ytDuration: String
        switch length {
        case .short:  ytDuration = "short"   // < 4 min
        case .medium: ytDuration = "medium"  // 4–20 min
        case .long:   ytDuration = "long"    // > 20 min
        }

        var components = URLComponents(string: "https://www.googleapis.com/youtube/v3/search")!
        components.queryItems = [
            URLQueryItem(name: "part", value: "snippet"),
            URLQueryItem(name: "type", value: "video"),
            URLQueryItem(name: "maxResults", value: "10"),
            URLQueryItem(name: "videoCaption", value: "closedCaption"),
            URLQueryItem(name: "videoDuration", value: ytDuration),
            URLQueryItem(name: "relevanceLanguage", value: language.shortTitle.lowercased()),
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "key", value: apiKey)
        ]
        guard let url = components.url else {
            throw ListeningVideoSearchError.requestFailed("Invalid request")
        }

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(from: url)
        } catch {
            throw ListeningVideoSearchError.requestFailed(error.localizedDescription)
        }
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ListeningVideoSearchError.requestFailed("Server error")
        }

        let decoded: YouTubeSearchResponse
        do {
            decoded = try JSONDecoder().decode(YouTubeSearchResponse.self, from: data)
        } catch {
            throw ListeningVideoSearchError.requestFailed("Bad response")
        }

        let items = decoded.items.compactMap { item -> ListeningVideoItem? in
            guard let videoId = item.id.videoId else { return nil }
            let watchURL = "https://www.youtube.com/watch?v=\(videoId)"
            return ListeningVideoItem(
                id: videoId,
                title: item.snippet.title,
                channel: item.snippet.channelTitle,
                durationText: "",  // duration requires a separate videos.list call
                difficultyTitle: level.title,
                hasCaptions: true, // filtered upstream by videoCaption=closedCaption
                thumbnailURL: item.snippet.thumbnails?.medium?.url
                    ?? "https://img.youtube.com/vi/\(videoId)/hqdefault.jpg",
                playableURL: watchURL,
                sourceURL: watchURL,
                transcriptText: nil
            )
        }
        guard !items.isEmpty else { throw ListeningVideoSearchError.noResults }
        return items
    }
}

// MARK: - YouTube response models

private struct YouTubeSearchResponse: Decodable {
    let items: [Item]

    struct Item: Decodable {
        let id: ID
        let snippet: Snippet
    }
    struct ID: Decodable {
        let videoId: String?
    }
    struct Snippet: Decodable {
        let title: String
        let channelTitle: String
        let thumbnails: Thumbnails?
    }
    struct Thumbnails: Decodable {
        let medium: Thumbnail?
    }
    struct Thumbnail: Decodable {
        let url: String
    }
}
