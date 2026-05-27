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
            return "AI quiz generation is not configured yet."
        case .invalidResponse:
            return "The AI server returned an unexpected response."
        case .http(let code):
            return "AI server error (\(code)). Please try again."
        case .network(let message):
            return message
        }
    }
}

// MARK: - HTTP client

/// Default implementation that POSTs JSON to a configured backend endpoint.
/// Construct it with `GrammarQuizAIConfiguration.makeClient()` so the
/// endpoint URL is read from a single configuration point.
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

    func generateQuizQuestions(
        request: GrammarQuizAIRequest
    ) async throws -> GrammarQuizAIResponseDTO {
        var urlRequest = URLRequest(url: endpointURL, timeoutInterval: timeout)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            throw GrammarQuizAIClientError.network(error.localizedDescription)
        }

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

        do {
            return try JSONDecoder().decode(GrammarQuizAIResponseDTO.self, from: data)
        } catch {
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
