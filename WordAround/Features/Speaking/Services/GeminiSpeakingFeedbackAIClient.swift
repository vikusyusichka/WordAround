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
            throw SpeakingFeedbackAIClientError.notConfigured
        }

        let prompt = Self.buildPrompt(request)

        #if DEBUG
        print("[FeedbackAI] → Worker generateFeedback userMessages=\(request.messages.filter { $0.role == .user }.count)")
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
            throw SpeakingFeedbackAIClientError.invalidResponse
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch {
            throw SpeakingFeedbackAIClientError.network(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw SpeakingFeedbackAIClientError.invalidResponse
        }

        guard (200...299).contains(http.statusCode) else {

            let envelope = try? JSONDecoder().decode(WorkerResponse.self, from: data)
            let message = envelope?.error ?? ""
            throw SpeakingFeedbackAIClientError.serverError(http.statusCode, message)
        }

        let envelope: WorkerResponse
        do {
            envelope = try JSONDecoder().decode(WorkerResponse.self, from: data)
        } catch {
            throw SpeakingFeedbackAIClientError.invalidResponse
        }

        guard
            let rawText = envelope.text?.trimmingCharacters(in: .whitespacesAndNewlines),
            !rawText.isEmpty
        else {
            throw SpeakingFeedbackAIClientError.invalidResponse
        }

        let cleaned = AIResponseTextCleaner.normalizedJSON(from: rawText)
        guard let jsonData = cleaned.data(using: .utf8) else {
            throw SpeakingFeedbackAIClientError.invalidResponse
        }

        do {
            let dto = try JSONDecoder().decode(SpeakingFeedbackAIResponseDTO.self, from: jsonData)
            try Self.validate(dto)
            return dto
        } catch let validationError as SpeakingFeedbackAIClientError {
            throw validationError
        } catch {
            #if DEBUG
            print("[FeedbackAI] decode error: \(error)")
            #endif
            throw SpeakingFeedbackAIClientError.invalidResponse
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

        return [
            "You are a speaking-practice evaluator inside a language learning app.",
            "",
            "Selected language: \(request.language.title)",
            "Learner level: \(request.level.rawValue)",
            "Scenario/Topic: \(request.scenarioOrTopicTitle)",
            "Scenario context: \(request.scenarioOrTopicContext)",
            "",
            "Full conversation (for context only — do NOT grade the Tutor lines):",
            allTurnsBlock,
            "",
            "Learner messages to evaluate (analyze ONLY these):",
            userTurnsBlock,
            "",
            "Task:",
            "1. Read the learner messages and judge them against level \(request.level.rawValue).",
            "2. Produce one short summary in English.",
            "3. Produce four score blocks: grammar, pronunciation, vocabulary, fluency.",
            "4. Produce zero or more concrete corrections drawn ONLY from the learner messages above.",
            "",
            "Rules — read carefully:",
            "- Analyze ONLY the learner messages. Never grade the tutor.",
            "- Corrections MUST quote the learner's actual wording in `originalText`. Never invent sentences the learner did not say.",
            "- If a learner message contains no clear mistake, do NOT add a correction for it.",
            "- If there are no mistakes at all, return an empty `corrections` array.",
            "- Pronunciation cannot be truly measured from text — set `rating` to something like 'Estimated' or 'Needs audio' and mention this in `explanation`.",
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
            "  \"corrections\": [",
            "    {\"originalText\":\"<exact learner words>\",\"correctedText\":\"<better version>\",\"explanation\":\"<short>\",\"category\":\"grammar|vocabulary|style\"}",
            "  ]",
            "}",
        ].joined(separator: "\n")
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
