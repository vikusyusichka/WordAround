import Foundation


enum AzureSpeechTokenError: LocalizedError {
    case notConfigured
    case network(String)
    case serverError(Int, String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .notConfigured:        return "Azure speech token endpoint is not configured."
        case .network(let m):       return "Network error: \(m)"
        case .serverError(let c, let m): return m.isEmpty ? "Token service error (\(c))." : "Token service error (\(c)): \(m)"
        case .invalidResponse:      return "The token service returned an unexpected response."
        }
    }
}


/// Azure subscription key never lives in the app — the Worker holds it as a secret.
protocol AzureSpeechTokenProviding {
    func fetchToken() async throws -> AzureSpeechToken
}

struct AzureSpeechToken: Equatable {
    let token: String
    let region: String
    let fetchedAt: Date

    /// Azure tokens last ~10 minutes; treat as stale a bit early.
    var isFresh: Bool { Date().timeIntervalSince(fetchedAt) < 8 * 60 }
}


enum AzureSpeechTokenConfiguration {
    static let workerPath = "/api/speech/azure-token"

    static var endpointURL: URL? {
        guard
            let base = GrammarQuizAIConfiguration.endpointURL,
            var components = URLComponents(url: base, resolvingAgainstBaseURL: false)
        else { return nil }
        components.path = workerPath
        return components.url
    }
}


final class AzureSpeechTokenService: AzureSpeechTokenProviding {

    private let endpointURL: URL?
    private let session: URLSession
    private let timeoutInterval: TimeInterval

    private var cached: AzureSpeechToken?

    init(
        endpointURL: URL? = AzureSpeechTokenConfiguration.endpointURL,
        session: URLSession = .shared,
        timeoutInterval: TimeInterval = 15
    ) {
        self.endpointURL = endpointURL
        self.session = session
        self.timeoutInterval = timeoutInterval
    }

    private struct WorkerResponse: Decodable {
        let token: String?
        let region: String?
        let error: String?
    }

    func fetchToken() async throws -> AzureSpeechToken {
        if let cached, cached.isFresh {
            #if DEBUG
            print("[AzureToken] reusing cached token (region=\(cached.region))")
            #endif
            return cached
        }

        guard let endpointURL else { throw AzureSpeechTokenError.notConfigured }

        #if DEBUG
        print("[AzureToken] → POST \(endpointURL.path) requesting Azure token")
        #endif

        var request = URLRequest(url: endpointURL, timeoutInterval: timeoutInterval)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw AzureSpeechTokenError.network(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw AzureSpeechTokenError.invalidResponse
        }

        let envelope: WorkerResponse
        do {
            envelope = try JSONDecoder().decode(WorkerResponse.self, from: data)
        } catch {
            throw AzureSpeechTokenError.invalidResponse
        }

        guard (200...299).contains(http.statusCode) else {
            throw AzureSpeechTokenError.serverError(http.statusCode, envelope.error ?? "")
        }

        guard
            let token = envelope.token, !token.isEmpty,
            let region = envelope.region, !region.isEmpty
        else {
            throw AzureSpeechTokenError.invalidResponse
        }

        let result = AzureSpeechToken(token: token, region: region, fetchedAt: Date())
        cached = result
        #if DEBUG
        print("[AzureToken] received token (region=\(region), len=\(token.count))")
        #endif
        return result
    }
}
