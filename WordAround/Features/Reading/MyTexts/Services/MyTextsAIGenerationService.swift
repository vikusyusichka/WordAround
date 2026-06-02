import Foundation

struct MyTextsAIGenerationRequest: Equatable {

    enum Style: String, CaseIterable, Identifiable, Codable {
        case informative, casual, academic, narrative

        var id: String { rawValue }
        var title: String {
            switch self {
            case .informative: return "Informative"
            case .casual:      return "Casual"
            case .academic:    return "Academic"
            case .narrative:   return "Narrative"
            }
        }
        static var titles: [String] { allCases.map(\.title) }
        static func from(title: String) -> Style {
            allCases.first { $0.title == title } ?? .informative
        }
    }

    let topic: String
    let language: GrammarLanguage
    let level: EssayDifficulty
    let length: ReadingLength
    let style: Style
    let focus: ReadingFocus

    var wordCountRange: ClosedRange<Int> {
        switch length {
        case .short:  return 120...220
        case .medium: return 250...400
        case .long:   return 500...800
        }
    }

    var targetWordCount: Int {
        let range = wordCountRange
        return (range.lowerBound + range.upperBound) / 2
    }
}

enum MyTextsAIGenerationError: LocalizedError {
    case notConfigured
    case network(String)
    case serverError(Int, String)
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Text generation isn't available right now."
        case .network:
            return "Couldn't reach the server. Check your connection and try again."
        case .serverError:
            return "The server couldn't create the text. Please try again."
        case .emptyResponse:
            return "The text came back empty. Please try again."
        }
    }
}

struct MyTextsAIGenerationResult: Equatable {
    let title: String
    let body: String
    let topic: String
}

protocol MyTextsAIClienting: Sendable {
    func complete(prompt: String, task: String, maxTokens: Int) async throws -> String
}

struct CloudflareMyTextsAIClient: MyTextsAIClienting {
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

    private struct WorkerRequest: Encodable { let prompt: String; let task: String }
    private struct WorkerResponse: Decodable { let text: String?; let error: String? }

    func complete(prompt: String, task: String, maxTokens: Int) async throws -> String {
        guard let endpointURL else { throw MyTextsAIGenerationError.notConfigured }

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
            throw MyTextsAIGenerationError.network(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw MyTextsAIGenerationError.serverError(-1, "")
        }
        let envelope = try? JSONDecoder().decode(WorkerResponse.self, from: data)

        guard (200...299).contains(http.statusCode) else {
            throw MyTextsAIGenerationError.serverError(http.statusCode, envelope?.error ?? "")
        }
        let text = envelope?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !text.isEmpty else { throw MyTextsAIGenerationError.emptyResponse }
        return text
    }
}

protocol MyTextsAIGenerating: Sendable {
    func generate(_ request: MyTextsAIGenerationRequest) async throws -> MyTextsAIGenerationResult
}

struct MyTextsAIGenerationService: MyTextsAIGenerating {
    private let client: MyTextsAIClienting

    init(client: MyTextsAIClienting = CloudflareMyTextsAIClient()) {
        self.client = client
    }

    func generate(_ request: MyTextsAIGenerationRequest) async throws -> MyTextsAIGenerationResult {
        let prompt = MyTextsAIPromptBuilder.prompt(for: request)
        let maxTokens = max(600, request.targetWordCount * 3)
        let raw = try await client.complete(prompt: prompt, task: "my_texts_generation", maxTokens: maxTokens)
        let cleaned = ReadingTextNormalizationService.normalize(raw)
        guard !cleaned.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw MyTextsAIGenerationError.emptyResponse
        }
        let trimmedTopic = request.topic.trimmingCharacters(in: .whitespacesAndNewlines)
        let title = trimmedTopic.isEmpty ? "Generated reading" : trimmedTopic.capitalizingFirstLetter()
        return MyTextsAIGenerationResult(title: title, body: cleaned, topic: trimmedTopic)
    }
}

enum MyTextsAIPromptBuilder {
    static func prompt(for request: MyTextsAIGenerationRequest) -> String {
        let topic: String = {
            let trimmed = request.topic.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { return "an interesting everyday topic" }
            return trimmed
        }()
        let range = request.wordCountRange
        var lines: [String] = []
        lines.append("Write a self-contained reading passage in \(request.language.title) about: \(topic).")
        lines.append("Tone / style: \(styleInstruction(for: request.style)).")
        lines.append("CEFR level \(request.level.rawValue): \(levelInstruction(for: request.level)).")
        lines.append("Target length: about \(request.targetWordCount) words (between \(range.lowerBound) and \(range.upperBound)).")
        lines.append(focusInstruction(for: request.focus))
        lines.append("")
        lines.append("Formatting rules — follow exactly:")
        lines.append("- Return only the passage.")
        lines.append("- No markdown, no bold, no italics, no headings, no bullet points.")
        lines.append("- Do not write a title.")
        lines.append("- Do not include intros, outros, or notes to the reader.")
        return lines.joined(separator: "\n")
    }

    private static func styleInstruction(for style: MyTextsAIGenerationRequest.Style) -> String {
        switch style {
        case .informative: return "clear, factual, educational — like a magazine explainer"
        case .casual:      return "friendly and conversational — like a personal blog post"
        case .academic:    return "more formal and precise — like a textbook excerpt"
        case .narrative:   return "vivid storytelling with concrete scenes and characters"
        }
    }

    private static func levelInstruction(for level: EssayDifficulty) -> String {
        switch level {
        case .a1, .a2:
            return "short simple sentences, very common everyday vocabulary"
        case .b1:
            return "medium sentences with common connectors and broader vocabulary"
        case .b2:
            return "natural sentence variety; introduce some abstract ideas"
        case .c1:
            return "complex sentence structures and advanced vocabulary; precise word choice"
        case .native:
            return "advanced, idiomatic vocabulary; nuanced phrasing"
        }
    }

    private static func focusInstruction(for focus: ReadingFocus) -> String {
        switch focus {
        case .mainIdea:
            return "Structure the passage around one clear main idea so the reader can summarise it."
        case .detailedComprehension:
            return "Include several concrete details so the reader can answer specific questions."
        case .vocabulary:
            return "Include several useful topic-specific words the reader can learn from context."
        case .grammarAwareness:
            return "Include sentences that showcase common grammar patterns naturally."
        case .speedFluency:
            return "Use steady rhythm and even sentence length so the reader can build pace."
        }
    }
}

struct MockMyTextsAIGenerationService: MyTextsAIGenerating {
    var simulatedDelayNanos: UInt64 = 0
    var error: Error? = nil

    func generate(_ request: MyTextsAIGenerationRequest) async throws -> MyTextsAIGenerationResult {
        if simulatedDelayNanos > 0 { try? await Task.sleep(nanoseconds: simulatedDelayNanos) }
        if let error { throw error }
        let topic = request.topic.isEmpty ? "an interesting subject" : request.topic
        let body = "This sample reading explores \(topic). Reading at level \(request.level.rawValue), in a \(request.style.title.lowercased()) tone, with steady pace and concrete details so that the reader can practise both speed and comprehension.\n\n"
            + "The passage discusses the topic from a few angles — practical, historical, and personal — and ends with a short reflection so the reader can identify the main idea."
        return MyTextsAIGenerationResult(title: topic.capitalizingFirstLetter(), body: body, topic: topic)
    }
}

private extension String {
    func capitalizingFirstLetter() -> String {
        guard let first = first else { return self }
        return first.uppercased() + dropFirst()
    }
}
