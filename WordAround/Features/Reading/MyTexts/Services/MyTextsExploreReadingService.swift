import Foundation

struct MyTextsExploreRequest: Equatable {

    enum SourcePreference: String, CaseIterable, Identifiable, Codable {
        case wikipedia
        case publicArticle
        case randomEducational

        var id: String { rawValue }
        var title: String {
            switch self {
            case .wikipedia:         return "Wikipedia"
            case .publicArticle:     return "Public article"
            case .randomEducational: return "Random topic"
            }
        }
        static var titles: [String] { allCases.map(\.title) }
        static func from(title: String) -> SourcePreference {
            allCases.first { $0.title == title } ?? .wikipedia
        }
    }

    let topic: String
    let language: GrammarLanguage
    let preference: SourcePreference
    let length: ReadingLength
}

enum MyTextsExploreError: LocalizedError {
    case emptyTopic
    case notFound
    case network(String)
    case decoding

    var errorDescription: String? {
        switch self {
        case .emptyTopic:
            return "Add a topic or keyword to explore."
        case .notFound:
            return "Couldn't find a matching article. Try a different topic."
        case .network:
            return "Couldn't reach the article source. Check your connection."
        case .decoding:
            return "Article came back in an unexpected format. Try again."
        }
    }
}

struct MyTextsExploreResult: Equatable {
    let title: String
    let body: String
    let sourceURL: URL?
    let topic: String
    let fetchedAt: Date
    let sourceLabel: String
    let isPlaceholder: Bool
}

protocol MyTextsExploreReading: Sendable {
    func fetch(_ request: MyTextsExploreRequest) async throws -> MyTextsExploreResult
}

struct MyTextsExploreReadingService: MyTextsExploreReading {
    private let session: URLSession
    private let now: () -> Date

    init(session: URLSession = .shared, now: @escaping () -> Date = Date.init) {
        self.session = session
        self.now = now
    }

    func fetch(_ request: MyTextsExploreRequest) async throws -> MyTextsExploreResult {
        let trimmed = request.topic.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw MyTextsExploreError.emptyTopic }

        switch request.preference {
        case .wikipedia:
            return try await fetchWikipedia(topic: trimmed, language: request.language)
        case .publicArticle, .randomEducational:
            return placeholder(topic: trimmed, language: request.language)
        }
    }

    private struct WikipediaSummary: Decodable {
        let title: String
        let extract: String
        let content_urls: ContentURLs?
        struct ContentURLs: Decodable {
            let desktop: Desktop?
            struct Desktop: Decodable { let page: String? }
        }
    }

    private func fetchWikipedia(topic: String, language: GrammarLanguage) async throws -> MyTextsExploreResult {
        let host = wikipediaHost(for: language)
        let pathTopic = topic
            .replacingOccurrences(of: " ", with: "_")
            .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? topic
        guard let url = URL(string: "https://\(host)/api/rest_v1/page/summary/\(pathTopic)") else {
            throw MyTextsExploreError.network("Bad URL")
        }

        var request = URLRequest(url: url, timeoutInterval: 25)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("WordAround/1.0 (reading practice app)", forHTTPHeaderField: "User-Agent")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw MyTextsExploreError.network(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else { throw MyTextsExploreError.network("No response") }
        if http.statusCode == 404 { throw MyTextsExploreError.notFound }
        guard (200...299).contains(http.statusCode) else {
            throw MyTextsExploreError.network("HTTP \(http.statusCode)")
        }

        guard let summary = try? JSONDecoder().decode(WikipediaSummary.self, from: data) else {
            throw MyTextsExploreError.decoding
        }

        let body = summary.extract.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty else { throw MyTextsExploreError.notFound }
        let sourceURL: URL? = {
            if let page = summary.content_urls?.desktop?.page { return URL(string: page) }
            return URL(string: "https://\(host)/wiki/\(pathTopic)")
        }()

        return MyTextsExploreResult(
            title: summary.title.isEmpty ? topic : summary.title,
            body: body,
            sourceURL: sourceURL,
            topic: topic,
            fetchedAt: now(),
            sourceLabel: "Wikipedia",
            isPlaceholder: false
        )
    }

    private func wikipediaHost(for language: GrammarLanguage) -> String {
        let code = language.rawValue.lowercased()
        let normalized = code.count == 2 ? code : "en"
        return "\(normalized).wikipedia.org"
    }

    private func placeholder(topic: String, language: GrammarLanguage) -> MyTextsExploreResult {
        let body = "Explore Reading is set up to fetch a public article about \"\(topic)\". A live source isn't wired for this option yet, so this is a starter draft you can edit before saving.\n\n"
            + "Try replacing this with a few paragraphs about the topic — what it is, why it matters, and one concrete example a reader of \(language.title) would find interesting."
        return MyTextsExploreResult(
            title: topic,
            body: body,
            sourceURL: nil,
            topic: topic,
            fetchedAt: now(),
            sourceLabel: "Starter draft",
            isPlaceholder: true
        )
    }
}

struct MockMyTextsExploreReadingService: MyTextsExploreReading {
    var simulatedDelayNanos: UInt64 = 0
    var error: Error? = nil

    func fetch(_ request: MyTextsExploreRequest) async throws -> MyTextsExploreResult {
        if simulatedDelayNanos > 0 { try? await Task.sleep(nanoseconds: simulatedDelayNanos) }
        if let error { throw error }
        let body = "Sample explored article about \(request.topic). This text would normally come from Wikipedia or a public article source. It's editable before saving so the reader can trim or rewrite anything they want before practising."
        return MyTextsExploreResult(
            title: request.topic,
            body: body,
            sourceURL: URL(string: "https://example.com/\(request.topic)"),
            topic: request.topic,
            fetchedAt: Date(),
            sourceLabel: "Mock",
            isPlaceholder: false
        )
    }
}
