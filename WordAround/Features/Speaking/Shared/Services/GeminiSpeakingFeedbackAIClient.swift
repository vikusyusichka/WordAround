import Foundation

final class GeminiSpeakingFeedbackAIClient: SpeakingFeedbackAIClient {

    private let session: URLSession
    private let endpointURL: URL?
    private let timeoutInterval: TimeInterval

    init(
        session: URLSession = .shared,
        endpointURL: URL? = GrammarQuizAIConfiguration.endpointURL,
        timeoutInterval: TimeInterval = 35
    ) {
        self.session = session
        self.endpointURL = endpointURL
        self.timeoutInterval = timeoutInterval
    }

    private struct WorkerRequest: Encodable {
        let prompt: String
        let responseMimeType: String?
    }

    private struct WorkerResponse: Decodable {
        let text: String?
        let error: String?
    }

    func generateFeedback(
        _ request: SpeakingFeedbackRequest
    ) async throws -> SpeakingFeedbackAIResponseDTO {
        guard let endpointURL else {
            #if DEBUG
            print("[FeedbackAI] notConfigured — endpointURL is nil")
            #endif
            throw SpeakingFeedbackAIClientError.notConfigured
        }

        let prompt = Self.buildPrompt(request)
        let userMessageCount = request.messages.filter { $0.role == .user }.count

        #if DEBUG
        let host = endpointURL.host ?? "<no-host>"
        let path = endpointURL.path.isEmpty ? "/" : endpointURL.path
        print("[FeedbackAI] → request started host=\(host) path='\(path)' userMessages=\(userMessageCount) promptChars=\(prompt.count)")
        #endif

        var urlRequest = URLRequest(url: endpointURL, timeoutInterval: timeoutInterval)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            urlRequest.httpBody = try JSONEncoder().encode(
                WorkerRequest(prompt: prompt, responseMimeType: "application/json")
            )
        } catch {
            #if DEBUG
            print("[FeedbackAI] encode error: \(error.localizedDescription)")
            #endif
            throw SpeakingFeedbackAIClientError.invalidResponse
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch {
            #if DEBUG
            print("[FeedbackAI] network error: \(error.localizedDescription)")
            #endif
            throw SpeakingFeedbackAIClientError.network(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            #if DEBUG
            print("[FeedbackAI] invalidResponse — response is not HTTPURLResponse")
            #endif
            throw SpeakingFeedbackAIClientError.invalidResponse
        }

        #if DEBUG
        print("[FeedbackAI] ← request finished status=\(http.statusCode) bytes=\(data.count)")
        #endif

        guard (200...299).contains(http.statusCode) else {
            let envelope = try? JSONDecoder().decode(WorkerResponse.self, from: data)
            let message = envelope?.error ?? ""
            #if DEBUG
            print("[FeedbackAI] non-2xx status=\(http.statusCode) workerError='\(message)'")
            #endif
            throw SpeakingFeedbackAIClientError.serverError(http.statusCode, message)
        }

        let envelope: WorkerResponse
        do {
            envelope = try JSONDecoder().decode(WorkerResponse.self, from: data)
        } catch {
            #if DEBUG
            let raw = String(data: data, encoding: .utf8) ?? "<non-utf8 \(data.count) bytes>"
            print("[FeedbackAI] envelope decode error: \(error.localizedDescription) rawPrefix='\(raw.prefix(240))'")
            #endif
            throw SpeakingFeedbackAIClientError.invalidResponse
        }

        guard
            let rawText = envelope.text?.trimmingCharacters(in: .whitespacesAndNewlines),
            !rawText.isEmpty
        else {
            #if DEBUG
            print("[FeedbackAI] empty text in worker envelope error='\(envelope.error ?? "")'")
            #endif
            throw SpeakingFeedbackAIClientError.invalidResponse
        }

        #if DEBUG
        print("[FeedbackAI] raw response chars=\(rawText.count) prefix='\(rawText.prefix(220))'")
        #endif

        let cleaned = AIResponseTextCleaner.normalizedJSON(from: rawText)
        guard let jsonData = cleaned.data(using: .utf8) else {
            #if DEBUG
            print("[FeedbackAI] invalidResponse — cleaned text not UTF-8")
            #endif
            throw SpeakingFeedbackAIClientError.invalidResponse
        }

        do {
            let dto = try JSONDecoder().decode(SpeakingFeedbackAIResponseDTO.self, from: jsonData)
            try Self.validate(dto)
            #if DEBUG
            print("[FeedbackAI] decoded OK overall=\(dto.overallScore) grammar=\(dto.grammar.score) pron=\(dto.pronunciation.score) vocab=\(dto.vocabulary.score) fluency=\(dto.fluency.score) corrections=\(dto.corrections.count)")
            #endif
            return dto
        } catch let validationError as SpeakingFeedbackAIClientError {
            #if DEBUG
            print("[FeedbackAI] validation failed: \(validationError.errorDescription ?? "")")
            #endif
            throw validationError
        } catch let decodingError as DecodingError {
            #if DEBUG
            print("[FeedbackAI] JSON decode error: \(Self.describe(decodingError)) cleanedPrefix='\(cleaned.prefix(240))'")
            #endif
            throw SpeakingFeedbackAIClientError.invalidResponse
        } catch {
            #if DEBUG
            print("[FeedbackAI] decode error: \(error.localizedDescription)")
            #endif
            throw SpeakingFeedbackAIClientError.invalidResponse
        }
    }

    /// Compact human-readable description of a DecodingError. The default
    /// `localizedDescription` is generic ("The data couldn't be read…") and
    /// hides the actual coding-path; this surfaces the keyPath and
    /// underlying cause so we can spot e.g. an Int field arriving as a
    /// Double, or a missing key, in the console.
    private static func describe(_ error: DecodingError) -> String {
        switch error {
        case .keyNotFound(let key, let ctx):
            return "keyNotFound '\(key.stringValue)' at \(ctx.codingPath.map(\.stringValue).joined(separator: "."))"
        case .typeMismatch(let type, let ctx):
            return "typeMismatch expected \(type) at \(ctx.codingPath.map(\.stringValue).joined(separator: "."))"
        case .valueNotFound(let type, let ctx):
            return "valueNotFound \(type) at \(ctx.codingPath.map(\.stringValue).joined(separator: "."))"
        case .dataCorrupted(let ctx):
            return "dataCorrupted at \(ctx.codingPath.map(\.stringValue).joined(separator: ".")) — \(ctx.debugDescription)"
        @unknown default:
            return "\(error)"
        }
    }

    private static func buildPrompt(_ request: SpeakingFeedbackRequest) -> String {
        let userTurns = request.messages
            .filter { $0.role == .user }
            .enumerated()
            .map { idx, msg in "U\(idx + 1): \(msg.text)" }
            .joined(separator: "\n")

        let allTurns = request.messages
            .map { msg in
                let speaker = msg.role == .ai ? "Tutor" : "Learner"
                return "\(speaker): \(msg.text)"
            }
            .joined(separator: "\n")

        let userTurnsBlock = userTurns.isEmpty
            ? "(no user messages)"
            : userTurns

        let allTurnsBlock = allTurns.isEmpty
            ? "(no conversation)"
            : allTurns

        let debate = request.includeDebateMetrics

        let intro = debate
            ? "You are a debate-coach evaluator inside a language learning app. The learner debated an AI opponent."
            : "You are a speaking-practice evaluator inside a language learning app."

        let metricCountLine = debate
            ? "3. Produce seven score blocks: grammar, pronunciation, vocabulary, fluency, argumentQuality, persuasiveness, structure."
            : "3. Produce four score blocks: grammar, pronunciation, vocabulary, fluency."

        let debateRule = debate
            ? "- argumentQuality, persuasiveness and structure judge HOW the learner argued (logic, convincing reasons, clear organisation) — base them ONLY on the learner messages."
            : nil

        let debateSchemaLines = debate
            ? [
                "  \"argumentQuality\": {\"rating\":\"<rating>\",\"score\":<int>,\"explanation\":\"<short>\"},",
                "  \"persuasiveness\":  {\"rating\":\"<rating>\",\"score\":<int>,\"explanation\":\"<short>\"},",
                "  \"structure\":       {\"rating\":\"<rating>\",\"score\":<int>,\"explanation\":\"<short>\"},",
            ]
            : []

        var lines: [String] = [
            intro,
            "",
            "Selected language: \(request.language.title)",
            "Learner level: \(request.level.rawValue)",
            "Scenario/Topic: \(request.scenarioOrTopicTitle)",
            "Scenario context: \(request.scenarioOrTopicContext)",
            "",
            "Full conversation (for context only — do NOT grade the opponent lines):",
            allTurnsBlock,
            "",
            "Learner messages to evaluate (analyze ONLY these):",
            userTurnsBlock,
            "",
            "Task:",
            "1. Read the learner messages and judge them against level \(request.level.rawValue).",
            "2. Produce one short summary in English.",
            metricCountLine,
            "4. Produce zero or more concrete corrections drawn ONLY from the learner messages above.",
            "",
            "Rules — read carefully:",
            "- Analyze ONLY the learner messages. Never grade the opponent.",
            "- Corrections MUST quote the learner's actual wording in `originalText`. Never invent sentences the learner did not say.",
            "- If a learner message contains no clear mistake, do NOT add a correction for it.",
            "- If there are no mistakes at all, return an empty `corrections` array.",
            "- Pronunciation cannot be truly measured from text — set `rating` to something like 'Estimated' or 'Needs audio' and mention this in `explanation`.",
        ]

        if let debateRule { lines.append(debateRule) }

        lines.append(contentsOf: [
            "- If the transcript is very short (≤1 user message or very few words), reduce all scores and mention that more practice is needed in `summary`.",
            "- Keep `summary` and every `explanation` short (1-2 sentences).",
            "- All numeric scores MUST be integers in 0...100.",
            "- All ratings MUST be one of: 'Great', 'Good', 'Fair', 'Needs practice', or 'Estimated' (use exactly these spellings).",
            "- Output STRICT JSON only — no prose, no markdown, no commentary, no code fences.",
            "",
            "Return ONLY a JSON object matching this exact schema:",
            "{",
            "  \"overallScore\": <int 0-100>,",
            "  \"summary\": \"<short English summary>\",",
            "  \"grammar\":       {\"rating\":\"<rating>\",\"score\":<int>,\"explanation\":\"<short>\"},",
            "  \"pronunciation\": {\"rating\":\"<rating>\",\"score\":<int>,\"explanation\":\"<short>\"},",
            "  \"vocabulary\":    {\"rating\":\"<rating>\",\"score\":<int>,\"explanation\":\"<short>\"},",
            "  \"fluency\":       {\"rating\":\"<rating>\",\"score\":<int>,\"explanation\":\"<short>\"},",
        ])

        lines.append(contentsOf: debateSchemaLines)

        lines.append(contentsOf: [
            "  \"corrections\": [",
            "    {\"originalText\":\"<exact learner words>\",\"correctedText\":\"<better version>\",\"explanation\":\"<short>\",\"category\":\"grammar|vocabulary|style\"}",
            "  ]",
            "}",
        ])

        return lines.joined(separator: "\n")
    }

    private static func validate(_ dto: SpeakingFeedbackAIResponseDTO) throws {
        func clampedScoreOK(_ s: Int) -> Bool { (0...100).contains(s) }

        guard clampedScoreOK(dto.overallScore) else {
            throw SpeakingFeedbackAIClientError.validationFailed("overallScore out of range")
        }
        for block in [dto.grammar, dto.pronunciation, dto.vocabulary, dto.fluency] {
            guard clampedScoreOK(block.score) else {
                throw SpeakingFeedbackAIClientError.validationFailed("metric score out of range")
            }
            if block.rating.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                throw SpeakingFeedbackAIClientError.validationFailed("metric rating empty")
            }
        }
        if dto.summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw SpeakingFeedbackAIClientError.validationFailed("summary empty")
        }
    }
}
