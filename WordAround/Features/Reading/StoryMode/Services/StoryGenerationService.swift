import Foundation

enum StoryGenerationError: LocalizedError {
    case notConfigured
    case network(String)
    case serverError(Int, String)
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Story generation isn't available right now."
        case .network:
            return "Couldn't reach the server. Check your connection and try again."
        case .serverError:
            return "The server couldn't create the story. Please try again."
        case .emptyResponse:
            return "The story came back empty. Please try again."
        }
    }
}

// MARK: - AI client

protocol StoryAIClienting: Sendable {
    func complete(prompt: String, task: String, maxTokens: Int) async throws -> String
}

struct CloudflareStoryAIClient: StoryAIClienting {
    private let session: URLSession
    private let endpointURL: URL?
    private let timeoutInterval: TimeInterval

    init(
        session: URLSession = .shared,
        endpointURL: URL? = GrammarQuizAIConfiguration.endpointURL,
        timeoutInterval: TimeInterval = 45
    ) {
        self.session = session
        self.endpointURL = endpointURL
        self.timeoutInterval = timeoutInterval
    }

    private struct WorkerRequest: Encodable {
        let prompt: String
        let task: String
    }

    private struct WorkerResponse: Decodable {
        let text: String?
        let error: String?
    }

    func complete(prompt: String, task: String, maxTokens: Int) async throws -> String {
        guard let endpointURL else { throw StoryGenerationError.notConfigured }

        var request = URLRequest(url: endpointURL, timeoutInterval: timeoutInterval)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try JSONEncoder().encode(WorkerRequest(prompt: prompt, task: task))

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw StoryGenerationError.network(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw StoryGenerationError.serverError(-1, "")
        }

        let envelope = try? JSONDecoder().decode(WorkerResponse.self, from: data)

        guard (200...299).contains(http.statusCode) else {
            throw StoryGenerationError.serverError(http.statusCode, envelope?.error ?? "")
        }

        let text = envelope?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !text.isEmpty else { throw StoryGenerationError.emptyResponse }
        return text
    }
}

// MARK: - Service

protocol StoryGenerating: Sendable {
    func generateFirstChapter(for session: StorySession) async throws -> StoryChapter
    func generateNextChapter(for session: StorySession, selectedChoice: StoryChoice) async throws -> StoryChapter
}

struct StoryGenerationService: StoryGenerating {
    private let client: StoryAIClienting

    init(client: StoryAIClienting = CloudflareStoryAIClient()) {
        self.client = client
    }

    func generateFirstChapter(for session: StorySession) async throws -> StoryChapter {
        let prompt = StoryPromptBuilder.firstChapterPrompt(configuration: session.configuration)
        let text = try await generateText(prompt: prompt)
        let choices = try await makeChoices(chapterText: text, configuration: session.configuration)
        return StoryChapter(chapterIndex: 1, text: text, choices: choices)
    }

    func generateNextChapter(for session: StorySession, selectedChoice: StoryChoice) async throws -> StoryChapter {
        let prompt = StoryPromptBuilder.nextChapterPrompt(session: session, selectedChoice: selectedChoice)
        let text = try await generateText(prompt: prompt)
        let choices = try await makeChoices(chapterText: text, configuration: session.configuration)
        return StoryChapter(chapterIndex: session.chapters.count + 1, text: text, choices: choices)
    }

    // MARK: - Text

    private func generateText(prompt: String) async throws -> String {
        let raw = try await client.complete(prompt: prompt, task: "story_generation", maxTokens: 1100)
        let cleaned = ReadingTextNormalizationService.normalize(raw)
        guard !cleaned.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw StoryGenerationError.emptyResponse
        }
        return cleaned
    }

    // MARK: - Choices

    private func makeChoices(chapterText: String, configuration: StoryModeConfiguration) async throws -> [StoryChoice] {
        guard configuration.storyLength != .shortStory else { return [] }

        let count = 3
        let prompt = StoryPromptBuilder.choicesPrompt(chapterText: chapterText, configuration: configuration, count: count)
        let raw = (try? await client.complete(prompt: prompt, task: "story_choices", maxTokens: 200)) ?? ""
        let parsed = Self.parseChoices(raw, max: count)
        return parsed.count >= 2 ? parsed : Self.fallbackChoices
    }

    static func parseChoices(_ raw: String, max: Int) -> [StoryChoice] {
        let cleaned = AIResponseTextCleaner.normalizedText(from: raw)
        let lines = cleaned
            .components(separatedBy: .newlines)
            .map { stripLeadingMarkers($0) }
            .filter { $0.count >= 2 && $0.count <= 90 }

        var seen = Set<String>()
        var result: [StoryChoice] = []
        for line in lines {
            let key = line.lowercased()
            guard !seen.contains(key) else { continue }
            seen.insert(key)
            result.append(StoryChoice(label: line, iconName: "arrow.turn.up.right"))
            if result.count >= max { break }
        }
        return result
    }

    private static func stripLeadingMarkers(_ line: String) -> String {
        var s = line.trimmingCharacters(in: .whitespaces)
        if let regex = try? NSRegularExpression(pattern: "^\\s*(\\d+[.)]|[-*•])\\s+") {
            let range = NSRange(s.startIndex..., in: s)
            s = regex.stringByReplacingMatches(in: s, range: range, withTemplate: "")
        }
        s = s.trimmingCharacters(in: CharacterSet(charactersIn: "\"'“”"))
        return s.trimmingCharacters(in: .whitespaces)
    }

    private static let fallbackChoices: [StoryChoice] = [
        StoryChoice(label: "Move forward carefully", iconName: "arrow.turn.up.right"),
        StoryChoice(label: "Take a bold risk", iconName: "arrow.turn.up.right"),
        StoryChoice(label: "Look for another way", iconName: "arrow.turn.up.right")
    ]
}

// MARK: - Mock (previews / tests)

struct MockStoryGenerationService: StoryGenerating {
    var simulatedDelayNanos: UInt64 = 0
    var error: Error? = nil

    func generateFirstChapter(for session: StorySession) async throws -> StoryChapter {
        try await produce(index: 1, session: session, lead: "The story begins.")
    }

    func generateNextChapter(for session: StorySession, selectedChoice: StoryChoice) async throws -> StoryChapter {
        try await produce(index: session.chapters.count + 1, session: session,
                          lead: "After choosing to \(selectedChoice.label.lowercased()), the story continues.")
    }

    private func produce(index: Int, session: StorySession, lead: String) async throws -> StoryChapter {
        if simulatedDelayNanos > 0 { try? await Task.sleep(nanoseconds: simulatedDelayNanos) }
        if let error { throw error }
        let body = "\(lead) This is a sample \(session.configuration.difficultyTitle) "
            + "\(session.configuration.storyType.title.lowercased()) chapter in "
            + "\(session.configuration.language.title). The character looks around and considers what to do next.\n\n"
            + "Each path leads somewhere new, and the reader must decide where the story goes."
        let choices = session.configuration.storyLength == .shortStory ? [] : [
            StoryChoice(label: "Explore the unknown path", iconName: "arrow.turn.up.right"),
            StoryChoice(label: "Return to safety", iconName: "arrow.turn.up.right"),
            StoryChoice(label: "Wait and watch", iconName: "arrow.turn.up.right")
        ]
        return StoryChapter(chapterIndex: index, text: body, choices: choices)
    }
}
