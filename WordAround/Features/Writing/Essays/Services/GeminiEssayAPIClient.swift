import Foundation

enum GeminiEssayAIClientError: LocalizedError {
    case missingAPIKey
    case invalidURL
    case invalidResponse
    case serverError(Int, String)
    case emptyResponse
    case malformedJSON(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Gemini API key is missing. Add GEMINI_API_KEY to Info.plist, xcconfig, or the app environment."
        case .invalidURL:
            return "Could not build the Gemini request URL."
        case .invalidResponse:
            return "Gemini returned an unexpected response."
        case .serverError(let code, let message):
            if message.isEmpty {
                return "Gemini request failed with status code \(code)."
            }
            return "Gemini request failed with status code \(code): \(message)"
        case .emptyResponse:
            return "Gemini returned an empty response."
        case .malformedJSON(let rawText):
            return "Gemini returned data that could not be decoded as JSON: \(rawText)"
        }
    }
}

final class GeminiEssayAIClient: EssayAIClient {
    private let session: URLSession
    private let apiKey: String?
    private let model: String
    private let timeoutInterval: TimeInterval

    init(
        session: URLSession = .shared,
        apiKey: String? = GeminiEssayAIClient.loadAPIKey(),
        model: String = "gemini-3.1-flash-lite",
        timeoutInterval: TimeInterval = 30
    ) {
        self.session = session
        self.apiKey = apiKey
        self.model = model
        self.timeoutInterval = timeoutInterval
    }

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

        return try await request(prompt: prompt, responseType: GeneratedEssayTask.self)
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

        return try await request(prompt: prompt, responseType: GeneratedEssayTask.self)
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

        return try await request(prompt: prompt, responseType: EssayGeneratedHint.self)
    }

    private func request<T: Decodable>(
        prompt: String,
        responseType: T.Type
    ) async throws -> T {
        guard let apiKey, !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw GeminiEssayAIClientError.missingAPIKey
        }

        var components = URLComponents(
            string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent"
        )
        components?.queryItems = [
            URLQueryItem(name: "key", value: apiKey.trimmingCharacters(in: .whitespacesAndNewlines))
        ]

        guard let url = components?.url else {
            throw GeminiEssayAIClientError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = timeoutInterval
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            GeminiRequest(
                contents: [
                    GeminiContent(
                        role: "user",
                        parts: [GeminiPart(text: prompt)]
                    )
                ],
                generationConfig: GeminiGenerationConfig(
                    responseMimeType: "application/json",
                    temperature: 0.8
                )
            )
        )

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiEssayAIClientError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw GeminiEssayAIClientError.serverError(
                httpResponse.statusCode,
                Self.extractServerMessage(from: data)
            )
        }

        let decoded = try JSONDecoder().decode(GeminiResponse.self, from: data)
        let text = decoded.candidates
            .flatMap { $0.content.parts }
            .compactMap { $0.text }
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !text.isEmpty else {
            throw GeminiEssayAIClientError.emptyResponse
        }

        let jsonString = Self.extractJSONString(from: text)

        guard let jsonData = jsonString.data(using: .utf8) else {
            throw GeminiEssayAIClientError.malformedJSON(Self.safePreview(text))
        }

        do {
            return try JSONDecoder().decode(T.self, from: jsonData)
        } catch {
            throw GeminiEssayAIClientError.malformedJSON(Self.safePreview(jsonString))
        }
    }

    private static func loadAPIKey() -> String? {
        if let key = Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String {
            let cleaned = key.trimmingCharacters(in: .whitespacesAndNewlines)
            if !cleaned.isEmpty {
                return cleaned
            }
        }

        let environmentKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"]?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let environmentKey, !environmentKey.isEmpty {
            return environmentKey
        }

        return nil
    }

    private static func extractJSONString(from text: String) -> String {
        var cleaned = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```JSON", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let start = cleaned.firstIndex(of: "{"),
           let end = cleaned.lastIndex(of: "}"),
           start <= end {
            cleaned = String(cleaned[start...end])
        }

        return cleaned
    }

    private static func extractServerMessage(from data: Data) -> String {
        guard !data.isEmpty else { return "" }

        if let apiError = try? JSONDecoder().decode(GeminiAPIErrorResponse.self, from: data) {
            return apiError.error.message
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

private struct GeminiRequest: Encodable {
    let contents: [GeminiContent]
    let generationConfig: GeminiGenerationConfig
}

private struct GeminiGenerationConfig: Encodable {
    let responseMimeType: String
    let temperature: Double

    enum CodingKeys: String, CodingKey {
        case responseMimeType = "response_mime_type"
        case temperature
    }
}

private struct GeminiContent: Codable {
    let role: String?
    let parts: [GeminiPart]

    init(role: String? = nil, parts: [GeminiPart]) {
        self.role = role
        self.parts = parts
    }
}

private struct GeminiPart: Codable {
    let text: String?

    init(text: String?) {
        self.text = text
    }
}

private struct GeminiResponse: Decodable {
    let candidates: [GeminiCandidate]
}

private struct GeminiCandidate: Decodable {
    let content: GeminiContent
}

private struct GeminiAPIErrorResponse: Decodable {
    let error: GeminiAPIError
}

private struct GeminiAPIError: Decodable {
    let message: String
}
