import Foundation

// MARK: - Protocol

/// Abstraction over the backend that turns a `GrammarQuizAIRequest`
/// into an AI-generated `GrammarQuizAIResponseDTO`.
/// The iOS app never holds an OpenAI / Anthropic API key directly —
/// requests go to a backend (e.g. Firebase Cloud Function) which owns
/// the key and the prompt.
protocol GrammarQuizAIClient {
    func generateQuizQuestions(
        request: GrammarQuizAIRequest
    ) async throws -> GrammarQuizAIResponseDTO
}

// MARK: - Errors

enum GrammarQuizAIClientError: LocalizedError, Equatable {
    case notConfigured
    case invalidResponse
    case http(Int)
    case network(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "AI quiz generation needs Apple Intelligence or a configured backend. Enable Apple Intelligence in Settings, or use Smart Local."
        case .invalidResponse:
            return "The AI returned an unexpected response. Try again or use Smart Local."
        case .http(let code):
            return "AI server error (\(code)). Please try again."
        case .network(let message):
            return message
        }
    }
}

// MARK: - HTTP client

/// POSTs `{ "prompt": "..." }` to a configured Cloudflare Worker which
/// owns the Gemini API key and forwards the prompt server-side, then
/// returns `{ "text": "..." }`. The iOS app NEVER sees the key — it
/// only knows the Worker URL.
///
/// Wire-level contract:
///   Request  → `{ "prompt": "<full prompt>" }`
///   Response → `{ "text": "<model output as JSON string>" }`
///
/// We parse `text` as the canonical `GrammarQuizAIResponseDTO` shape so
/// the downstream validator stays unchanged. The Worker is responsible
/// for asking Gemini to return JSON that matches that schema.
final class GrammarQuizAIHTTPClient: GrammarQuizAIClient {

    private let endpointURL: URL
    private let session: URLSession
    private let timeout: TimeInterval

    init(
        endpointURL: URL,
        session: URLSession = .shared,
        timeout: TimeInterval = 30
    ) {
        self.endpointURL = endpointURL
        self.session = session
        self.timeout = timeout
    }

    // Wire DTOs — kept private. The Worker contract is intentionally
    // minimal (prompt in, text out) so the iOS app never depends on
    // Gemini's evolving response shape.
    //
    // `responseMimeType` is forwarded to Gemini's `generationConfig` —
    // we always ask for application/json since quiz answers MUST decode
    // into `GrammarQuizAIResponseDTO`.
    private struct WorkerRequest: Encodable {
        let prompt: String
        let responseMimeType: String?
    }

    private struct WorkerResponse: Decodable {
        let text: String?
        let error: String?
    }

    func generateQuizQuestions(
        request: GrammarQuizAIRequest
    ) async throws -> GrammarQuizAIResponseDTO {
        // 1. Convert the structured request into a single prompt string
        //    the Worker can forward verbatim to Gemini.
        let prompt = GrammarQuizAIPromptBuilder.buildPrompt(from: request)

        var urlRequest = URLRequest(url: endpointURL, timeoutInterval: timeout)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            urlRequest.httpBody = try JSONEncoder().encode(
                WorkerRequest(prompt: prompt, responseMimeType: "application/json")
            )
        } catch {
            throw GrammarQuizAIClientError.network(error.localizedDescription)
        }

        // 2. Network round-trip — any URLSession failure flows back as
        //    `.network(...)` so the UI can offer "Use Smart Local".
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch {
            throw GrammarQuizAIClientError.network(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw GrammarQuizAIClientError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            throw GrammarQuizAIClientError.http(http.statusCode)
        }

        // 3. Worker envelope → unwrap `text`, then parse the embedded
        //    JSON. The Worker may also surface a top-level `error`.
        let envelope: WorkerResponse
        do {
            envelope = try JSONDecoder().decode(WorkerResponse.self, from: data)
        } catch {
            throw GrammarQuizAIClientError.invalidResponse
        }
        if let workerError = envelope.error, !workerError.isEmpty {
            throw GrammarQuizAIClientError.network(workerError)
        }
        guard let text = envelope.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else {
            throw GrammarQuizAIClientError.invalidResponse
        }

        // 4. Strip Markdown fences, unwrap double-encoded strings, and
        //    extract the first balanced `{…}` from any stray prose. The
        //    shared `AIResponseTextCleaner` is used by both the Quiz AI
        //    and Essay AI paths so behavior stays consistent.
        let jsonString = AIResponseTextCleaner.normalizedJSON(from: text)
        guard let jsonData = jsonString.data(using: .utf8) else {
            #if DEBUG
            print("[QuizAI] cleaned text not UTF-8 decodable:", jsonString)
            #endif
            throw GrammarQuizAIClientError.invalidResponse
        }
        do {
            return try JSONDecoder().decode(GrammarQuizAIResponseDTO.self, from: jsonData)
        } catch {
            #if DEBUG
            print("[QuizAI] raw text:", text)
            print("[QuizAI] cleaned text:", jsonString)
            print("[QuizAI] decode error:", error)
            #endif
            throw GrammarQuizAIClientError.invalidResponse
        }
    }
}

// MARK: - Unconfigured client

/// Used when no backend endpoint is set. Throws a clear, user-facing
/// `notConfigured` error so the UI can surface "AI quiz generation
/// is not configured yet."
struct UnconfiguredGrammarQuizAIClient: GrammarQuizAIClient {
    func generateQuizQuestions(
        request: GrammarQuizAIRequest
    ) async throws -> GrammarQuizAIResponseDTO {
        throw GrammarQuizAIClientError.notConfigured
    }
}
