import Foundation

enum SpeakingTopicAIConfiguration {

    static let workerPath = "/api/speaking/topic"

    static var endpointURL: URL? {
        guard
            let base = GrammarQuizAIConfiguration.endpointURL,
            var components = URLComponents(url: base, resolvingAgainstBaseURL: false)
        else { return nil }

        components.path = workerPath
        return components.url
    }

    static var isRemoteConfigured: Bool {
        endpointURL != nil
    }

    static func makeClient() -> SpeakingTopicAIClient {
        if let url = endpointURL {
            return CloudflareSpeakingTopicAIClient(endpointURL: url)
        }
        return LocalFallbackSpeakingTopicAIClient()
    }
}
