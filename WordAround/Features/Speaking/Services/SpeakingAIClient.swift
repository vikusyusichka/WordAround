import Foundation

enum SpeakingAIClientError: LocalizedError {
    case workerNotConfigured
    case invalidResponse
    case serverError(Int, String)
    case emptyResponse
    case network(String)

    var errorDescription: String? {
        switch self {
        case .workerNotConfigured:
            return "AI proxy is not configured."
        case .invalidResponse:
            return "AI returned an unexpected response."
        case .serverError(let code, let message):
            if message.isEmpty {
                return "AI request failed (\(code))."
            }
            return "AI request failed (\(code)): \(message)"
        case .emptyResponse:
            return "AI returned an empty response."
        case .network(let message):
            return "Network error: \(message)"
        }
    }
}

protocol SpeakingAIClient {
    func generateReply(prompt: String) async throws -> String
}
