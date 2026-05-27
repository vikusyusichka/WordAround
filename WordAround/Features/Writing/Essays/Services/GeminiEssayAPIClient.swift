import Foundation

/// User-facing errors produced by the Essay AI client.
///
/// Note: this file is named `GeminiEssayAPIClient` for historical reasons —
/// the iOS app NO LONGER calls Gemini directly. All traffic now flows
/// through the Cloudflare Worker proxy and the Gemini key lives ONLY as
/// a Wrangler secret. The class name is kept stable to minimize diff
/// surface across the rest of the codebase.
enum GeminiEssayAIClientError: LocalizedError {
    case workerNotConfigured
    case invalidResponse
    case serverError(Int, String)
    case emptyResponse
    case malformedJSON(String)

    var errorDescription: String? {
        switch self {
        case .workerNotConfigured:
            return "AI proxy is not configured. Set GrammarQuizAIConfiguration.endpointURL."
        case .invalidResponse:
            return "AI returned an unexpected response."
        case .serverError(let code, let message):
            if message.isEmpty {
                return "AI request failed with status code \(code)."
            }
            return "AI request failed with status code \(code): \(message)"
        case .emptyResponse:
            return "AI returned an empty response."
        case .malformedJSON(let rawText):
            return "AI returned data that could not be decoded: \(rawText)"
        }
    }
}

/// `EssayAIClient` implementation that POSTs prompts to the Cloudflare
/// Worker proxy. Reuses the same Worker URL as the Grammar Notes quiz
/// client so the iOS app only has ONE Gemini-facing endpoint to manage.
///
/// Wire contract (matches the Worker exactly):
///   Request  → `{ "prompt": "<full prompt>", "responseMimeType": "application/json" }`
///   Response → `{ "text": "<model output>" }`
///
/// All parsing flows through `AIResponseTextCleaner` so Markdown fences,
/// double-encoded JSON strings, and stray prose around the JSON do not
/// break the feature.
final class GeminiEssayAIClient: EssayAIClient {

    private let session: URLSession
    private let endpointURL: URL?
    private let timeoutInterval: TimeInterval

    init(
        session: URLSession = .shared,
        endpointURL: URL? = GrammarQuizAIConfiguration.endpointURL,
        timeoutInterval: TimeInterval = 30
    ) {
        self.session = session
        self.endpointURL = endpointURL
        self.timeoutInterval = timeoutInterval
    }

    // MARK: - Wire DTOs

    private struct WorkerRequest: Encodable {
        let prompt: String
        let responseMimeType: String?
    }

    private struct WorkerResponse: Decodable {
        let text: String?
        let error: String?
    }

    // MARK: - Public API

    func generateSuggestedTask(
        language: GrammarLanguage,
        avoidTitles: [String]
    ) async throws -> GeneratedEssayTask {
        let prompt = """
        Generate one essay practice task for a language learner.

        Target writing language: \(language.title)
        Mode: suggested topic
        Previously used titles to avoid: \(avoidTitles.joined(separator: ", "))

        Requirements:
        - Create a fresh, non-repetitive essay topic.
        - Automatically detect the most suitable CEFR level based on topic complexity.
        - Return exactly one essay task.
        - Return exactly 3 short practical writing tips.
        - Each tip must be 2-5 words.
        - The task must be suitable for language learners.
        - Do not include private or sensitive topics.
        - Avoid medical, legal, extremist, violent, sexual, or traumatic topics.
        - Return JSON only.
        - Do not wrap JSON in markdown.

        JSON schema:
        {
          "title": "string",
          "task": "string",
          "detectedLevel": "A1|A2|B1|B2|C1|Native",
          "estimatedTimeMinutes": 12,
          "wordLimitMin": 90,
          "wordLimitMax": 150,
          "quickTips": ["string", "string", "string"]
        }
        """

        return try await requestJSON(prompt: prompt, responseType: GeneratedEssayTask.self)
    }

    func generateTaskFromCustomTopic(
        topic: String,
        language: GrammarLanguage
    ) async throws -> GeneratedEssayTask {
        let prompt = """
        Generate an essay practice task based on the user's custom topic.

        Target writing language: \(language.title)
        User topic: "\(topic)"

        Requirements:
        - Rewrite the topic naturally.
        - Create a clear essay task.
        - Automatically detect the most suitable CEFR level.
        - Return exactly 3 short practical writing tips.
        - Each tip must be 2-5 words.
        - The task must be suitable for language learners.
        - Avoid private or sensitive topics.
        - Avoid medical, legal, extremist, violent, sexual, or traumatic topics.
        - Return JSON only.
        - Do not wrap JSON in markdown.

        JSON schema:
        {
          "title": "string",
          "task": "string",
          "detectedLevel": "A1|A2|B1|B2|C1|Native",
          "estimatedTimeMinutes": 12,
          "wordLimitMin": 90,
          "wordLimitMax": 150,
          "quickTips": ["string", "string", "string"]
        }
        """

        return try await requestJSON(prompt: prompt, responseType: GeneratedEssayTask.self)
    }

    func generateHint(
        language: GrammarLanguage,
        level: EssayDifficulty,
        topicTitle: String,
        task: String,
        essayText: String,
        previousHints: [String]
    ) async throws -> EssayGeneratedHint {
        let prompt = """
        Generate one helpful writing hint for a language learner.

        Target writing language: \(language.title)
        CEFR level: \(level.rawValue)
        Essay title: \(topicTitle)
        Essay task: \(task)
        Current essay text: "\(essayText)"
        Previous hints: \(previousHints.joined(separator: " | "))

        Rules:
        - Return exactly one hint.
        - Do not write the essay for the user.
        - Do not generate full paragraphs.
        - Do not repeat previous hints.
        - Keep the hint short.
        - Maximum 12 words.
        - Match learner level.
        - Return JSON only.
        - Do not wrap JSON in markdown.

        JSON schema:
        {
          "text": "string",
          "category": "content|grammar|vocabulary|structure"
        }
        """

        return try await requestJSON(prompt: prompt, responseType: EssayGeneratedHint.self)
    }

    // MARK: - Transport

    /// Sends the prompt to the Worker, asks for JSON-shaped output, and
    /// decodes the embedded `text` into `T`. Uses `AIResponseTextCleaner`
    /// to survive Markdown fences, double-encoded strings, and prose
    /// around the JSON.
    private func requestJSON<T: Decodable>(
        prompt: String,
        responseType: T.Type
    ) async throws -> T {
        guard let endpointURL else {
            throw GeminiEssayAIClientError.workerNotConfigured
        }

        var urlRequest = URLRequest(url: endpointURL, timeoutInterval: timeoutInterval)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            urlRequest.httpBody = try JSONEncoder().encode(
                WorkerRequest(prompt: prompt, responseMimeType: "application/json")
            )
        } catch {
            throw GeminiEssayAIClientError.invalidResponse
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch {
            throw GeminiEssayAIClientError.serverError(0, error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiEssayAIClientError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw GeminiEssayAIClientError.serverError(
                httpResponse.statusCode,
                Self.workerErrorMessage(from: data)
            )
        }

        let envelope: WorkerResponse
        do {
            envelope = try JSONDecoder().decode(WorkerResponse.self, from: data)
        } catch {
            #if DEBUG
            print("[EssayAI] envelope decode failed:", error)
            #endif
            throw GeminiEssayAIClientError.invalidResponse
        }

        if let workerError = envelope.error, !workerError.isEmpty {
            throw GeminiEssayAIClientError.serverError(httpResponse.statusCode, workerError)
        }

        guard let rawText = envelope.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !rawText.isEmpty else {
            throw GeminiEssayAIClientError.emptyResponse
        }

        let jsonString = AIResponseTextCleaner.normalizedJSON(from: rawText)
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw GeminiEssayAIClientError.malformedJSON(Self.safePreview(rawText))
        }

        do {
            return try JSONDecoder().decode(T.self, from: jsonData)
        } catch {
            #if DEBUG
            print("[EssayAI] raw text:", rawText)
            print("[EssayAI] cleaned text:", jsonString)
            print("[EssayAI] decode error:", error)
            #endif
            throw GeminiEssayAIClientError.malformedJSON(Self.safePreview(jsonString))
        }
    }

    // MARK: - Helpers

    /// Picks the friendliest error message we can from a non-2xx Worker
    /// response: the Worker's `{ "error": "..." }` field if present,
    /// otherwise the raw body as text.
    private static func workerErrorMessage(from data: Data) -> String {
        guard !data.isEmpty else { return "" }

        struct ErrorEnvelope: Decodable { let error: String? }
        if let env = try? JSONDecoder().decode(ErrorEnvelope.self, from: data),
           let message = env.error, !message.isEmpty {
            return message
        }

        return String(data: data, encoding: .utf8) ?? ""
    }

    private static func safePreview(_ text: String) -> String {
        let compact = text
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return String(compact.prefix(220))
    }
}
