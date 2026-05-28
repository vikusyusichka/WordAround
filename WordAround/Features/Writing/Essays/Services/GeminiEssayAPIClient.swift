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
        timeoutInterval: TimeInterval = 45
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
        #if DEBUG
        print("[EssayAI] generateSuggestedTask language=\(language.title) avoidCount=\(avoidTitles.count)")
        #endif

        let avoidLine = avoidTitles.isEmpty
            ? ""
            : "Do not reuse any of these titles: \(avoidTitles.joined(separator: " | "))."

        let prompt = [
            "You generate one short essay-practice topic for a language learner.",
            "Write the topic title and the task entirely in \(language.title).",
            "Auto-detect the most suitable CEFR level (A1, A2, B1, B2, C1, or Native) based on topic complexity.",
            avoidLine,
            "Avoid sensitive, medical, legal, violent, or sexual topics.",
            "",
            Self.essayTaskResponseContract
        ]
        .filter { !$0.isEmpty }
        .joined(separator: "\n")

        return try await requestJSON(prompt: prompt, responseType: GeneratedEssayTask.self)
    }

    func generateTaskFromCustomTopic(
        topic: String,
        language: GrammarLanguage
    ) async throws -> GeneratedEssayTask {
        #if DEBUG
        print("[EssayAI] generateTaskFromCustomTopic language=\(language.title) topic=\(topic.prefix(60))")
        #endif

        let prompt = [
            "You generate one short essay-practice topic for a language learner.",
            "Write the topic title and the task entirely in \(language.title).",
            "Base the topic on the learner's idea: \"\(topic)\".",
            "Auto-detect the most suitable CEFR level (A1, A2, B1, B2, C1, or Native).",
            "Avoid sensitive, medical, legal, violent, or sexual topics.",
            "",
            Self.essayTaskResponseContract
        ]
        .joined(separator: "\n")

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
        #if DEBUG
        print("[EssayAI] generateHint language=\(language.title) level=\(level.rawValue) essayChars=\(essayText.count) previousHints=\(previousHints.count)")
        #endif

        let previousLine = previousHints.isEmpty
            ? ""
            : "Avoid repeating these earlier hints: \(previousHints.joined(separator: " | "))."

        let essayPreview = String(essayText.prefix(600))

        let prompt = [
            "You give one short writing hint to a language learner.",
            "Writing language: \(language.title). Learner CEFR level: \(level.rawValue).",
            "Essay title: \(topicTitle).",
            "Essay task: \(task).",
            "Learner's draft so far: \"\(essayPreview)\".",
            previousLine,
            "The hint must be at most 12 words, must not write the essay for them, must match the learner's level, and must be actionable.",
            "",
            Self.hintResponseContract
        ]
        .filter { !$0.isEmpty }
        .joined(separator: "\n")

        return try await requestJSON(prompt: prompt, responseType: EssayGeneratedHint.self)
    }

    // MARK: - Response contracts

    /// Single-line JSON contract that mirrors the working
    /// `GrammarQuizAIPromptBuilder.responseContract`. Gemini's JSON mode
    /// behaves much more reliably when the schema is one compact line
    /// rather than a pretty-printed multi-line example with placeholder
    /// values (those get echoed back verbatim more often than not).
    private static let essayTaskResponseContract: String = """
    Return ONLY a JSON object that matches:
    {"title":"<short topic title in target language>","task":"<one-paragraph essay prompt in target language>","detectedLevel":"A1|A2|B1|B2|C1|Native","estimatedTimeMinutes":12,"wordLimitMin":90,"wordLimitMax":150,"quickTips":["<2-5 word tip>","<2-5 word tip>","<2-5 word tip>"]}
    Rules: estimatedTimeMinutes, wordLimitMin and wordLimitMax MUST be integers (not strings). quickTips MUST be an array of exactly 3 strings. Do not wrap the JSON in markdown or prose.
    """

    private static let hintResponseContract: String = """
    Return ONLY a JSON object that matches:
    {"text":"<<=12 word hint in target language>","category":"content|grammar|vocabulary|structure"}
    Do not wrap the JSON in markdown or prose.
    """

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
            #if DEBUG
            print("[EssayAI] requestJSON — endpointURL is nil, worker not configured")
            #endif
            throw GeminiEssayAIClientError.workerNotConfigured
        }

        #if DEBUG
        print("[EssayAI] → POST \(endpointURL.absoluteString) type=\(responseType)")
        #endif

        var urlRequest = URLRequest(url: endpointURL, timeoutInterval: timeoutInterval)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let body = try JSONEncoder().encode(
                WorkerRequest(prompt: prompt, responseMimeType: "application/json")
            )
            urlRequest.httpBody = body
            #if DEBUG
            print("[EssayAI] prompt (\(prompt.count) chars):\n\(prompt)")
            if let bodyString = String(data: body, encoding: .utf8) {
                print("[EssayAI] request body (\(body.count) bytes): \(bodyString.prefix(400))…")
            }
            #endif
        } catch {
            #if DEBUG
            print("[EssayAI] failed to encode request body:", error)
            #endif
            throw GeminiEssayAIClientError.invalidResponse
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch {
            #if DEBUG
            print("[EssayAI] network error:", error)
            #endif
            throw GeminiEssayAIClientError.serverError(0, error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiEssayAIClientError.invalidResponse
        }

        #if DEBUG
        print("[EssayAI] ← HTTP \(httpResponse.statusCode)")
        #endif

        guard (200...299).contains(httpResponse.statusCode) else {
            #if DEBUG
            let bodyPreview = String(data: data, encoding: .utf8).map { String($0.prefix(500)) } ?? "<binary \(data.count) bytes>"
            print("[EssayAI] error body:", bodyPreview)
            #endif
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
            #if DEBUG
            print("[EssayAI] worker returned empty text field")
            #endif
            throw GeminiEssayAIClientError.emptyResponse
        }

        #if DEBUG
        print("[EssayAI] rawText (\(rawText.count) chars):\n\(rawText)")
        #endif

        let jsonString = AIResponseTextCleaner.normalizedJSON(from: rawText)
        guard let jsonData = jsonString.data(using: .utf8) else {
            #if DEBUG
            print("[EssayAI] cleaned text not UTF-8 decodable:", jsonString)
            #endif
            throw GeminiEssayAIClientError.malformedJSON(Self.safePreview(rawText))
        }

        do {
            let decoded = try JSONDecoder().decode(T.self, from: jsonData)
            #if DEBUG
            print("✅ [EssayAI] decoded \(T.self) successfully")
            #endif
            return decoded
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
