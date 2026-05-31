import Foundation

enum ReadingFromSetGenerationError: LocalizedError {
    case notConfigured
    case network(String)
    case serverError(Int, String)
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Reading generation isn't available right now."
        case .network:
            return "Couldn't reach the server. Check your connection and try again."
        case .serverError:
            return "The server couldn't create the reading. Please try again."
        case .emptyResponse:
            return "The reading came back empty. Please try again."
        }
    }
}

protocol ReadingFromSetAIClienting: Sendable {
    func complete(prompt: String, task: String, maxTokens: Int) async throws -> String
}

struct CloudflareReadingFromSetAIClient: ReadingFromSetAIClienting {
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
        guard let endpointURL else { throw ReadingFromSetGenerationError.notConfigured }

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
            throw ReadingFromSetGenerationError.network(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw ReadingFromSetGenerationError.serverError(-1, "")
        }

        let envelope = try? JSONDecoder().decode(WorkerResponse.self, from: data)

        guard (200...299).contains(http.statusCode) else {
            throw ReadingFromSetGenerationError.serverError(http.statusCode, envelope?.error ?? "")
        }

        let text = envelope?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !text.isEmpty else { throw ReadingFromSetGenerationError.emptyResponse }
        return text
    }
}

struct ReadingFromSetGenerationService: ReadingFromSetGenerating {
    private let client: ReadingFromSetAIClienting

    init(client: ReadingFromSetAIClienting = CloudflareReadingFromSetAIClient()) {
        self.client = client
    }

    func generateReading(from request: ReadingFromSetGenerationRequest) async throws -> ReadingGeneratedReadingText {
        let prompt = ReadingFromSetPromptBuilder.build(from: request)
        let maxTokens = max(600, request.effectiveTargetWordCount * 3)
        let raw = try await client.complete(prompt: prompt, task: "reading_from_set", maxTokens: maxTokens)
        // Strip any markdown artifacts / placeholders so the saved text is clean.
        let cleaned = ReadingTextNormalizationService.normalize(raw)
        guard !cleaned.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ReadingFromSetGenerationError.emptyResponse
        }
        return ReadingGeneratedReadingText(title: nil, body: cleaned)
    }
}

struct MockReadingFromSetGenerationService: ReadingFromSetGenerating {
    var simulatedDelayNanos: UInt64 = 0
    var error: Error? = nil

    func generateReading(from request: ReadingFromSetGenerationRequest) async throws -> ReadingGeneratedReadingText {
        if simulatedDelayNanos > 0 { try? await Task.sleep(nanoseconds: simulatedDelayNanos) }
        if let error { throw error }
        let body = "This is a sample \(request.difficulty.rawValue) reading built from \"\(request.setTitle)\". "
            + "It naturally uses words like \(request.terms.prefix(5).joined(separator: ", ")) "
            + "so you can practise reading them in context."
        return ReadingGeneratedReadingText(title: request.setTitle, body: body)
    }
}
