import Foundation

final class GeminiSpeakingAIClient: SpeakingAIClient {

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

    private struct WorkerRequest: Encodable {
        let prompt: String
        let task: String
    }

    private struct WorkerResponse: Decodable {
        let text: String?
        let error: String?
    }

    func generateReply(prompt: String) async throws -> String {
        guard let endpointURL else {
            #if DEBUG
            print("[SpeakingAI] endpointURL is nil — worker not configured")
            #endif
            throw SpeakingAIClientError.workerNotConfigured
        }

        var urlRequest = URLRequest(url: endpointURL, timeoutInterval: timeoutInterval)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            urlRequest.httpBody = try JSONEncoder().encode(
                WorkerRequest(prompt: prompt, task: "speaking_conversation")
            )
        } catch {
            throw SpeakingAIClientError.invalidResponse
        }

        #if DEBUG
        print("[SpeakingAI] → POST \(endpointURL.absoluteString) (\(prompt.count) chars)")
        #endif

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch {
            throw SpeakingAIClientError.network(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw SpeakingAIClientError.invalidResponse
        }

        #if DEBUG
        print("[SpeakingAI] ← HTTP \(http.statusCode)")
        #endif

        guard (200...299).contains(http.statusCode) else {
            throw SpeakingAIClientError.serverError(http.statusCode, Self.errorMessage(from: data))
        }

        let envelope: WorkerResponse
        do {
            envelope = try JSONDecoder().decode(WorkerResponse.self, from: data)
        } catch {
            throw SpeakingAIClientError.invalidResponse
        }

        if let workerError = envelope.error, !workerError.isEmpty {
            throw SpeakingAIClientError.serverError(http.statusCode, workerError)
        }

        let raw = envelope.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !raw.isEmpty else {
            throw SpeakingAIClientError.emptyResponse
        }

        return Self.cleanReply(raw)
    }

    private static func cleanReply(_ text: String) -> String {
        var result = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if result.hasPrefix("```") {

            if let firstNewline = result.firstIndex(of: "\n") {
                result = String(result[result.index(after: firstNewline)...])
            }
            if result.hasSuffix("```") {
                result = String(result.dropLast(3))
            }
            result = result.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if result.hasPrefix("\"") && result.hasSuffix("\"") && result.count > 1 {
            result = String(result.dropFirst().dropLast())
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func errorMessage(from data: Data) -> String {
        guard !data.isEmpty else { return "" }

        struct ErrorEnvelope: Decodable { let error: String? }
        if let env = try? JSONDecoder().decode(ErrorEnvelope.self, from: data),
           let message = env.error, !message.isEmpty {
            return message
        }
        return String(data: data, encoding: .utf8) ?? ""
    }
}
