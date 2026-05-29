import Foundation

// MARK: - Errors

enum DescribePictureImageError: LocalizedError {
    case notConfigured
    case network(String)
    case serverError(Int)
    case rateLimited
    case invalidResponse
    case noImage

    var errorDescription: String? {
        switch self {
        case .notConfigured:    return "Image service is not configured."
        case .network(let m):   return "Network error: \(m)"
        case .serverError(let c): return "Image service error (\(c))."
        case .rateLimited:      return "Too many requests. Please try again shortly."
        case .invalidResponse:  return "The image service returned an unexpected response."
        case .noImage:          return "No image was available. Please try again."
        }
    }
}

// MARK: - Protocol

/// Provides random pictures for Describe Picture. Protocol-based so the
/// view model can be driven by a mock in previews/tests, and the live
/// source can be swapped later without touching call sites.
protocol DescribePictureImageProviding {
    func fetchRandomImage() async throws -> DescribePictureImage
}

// MARK: - Configuration

enum DescribePictureImageConfiguration {

    static let workerPath = "/api/describe-picture/random-image"

    /// Builds the Worker endpoint URL from the shared Gemini-proxy base URL.
    /// The Unsplash key lives only in the Worker — the app never sees it.
    static var endpointURL: URL? {
        guard
            let base = GrammarQuizAIConfiguration.endpointURL,
            var components = URLComponents(url: base, resolvingAgainstBaseURL: false)
        else { return nil }

        components.path = workerPath
        return components.url
    }

    static func makeProvider() -> DescribePictureImageProviding {
        if let url = endpointURL {
            return DescribePictureImageService(endpointURL: url)
        }
        return MockDescribePictureImageService()
    }
}

// MARK: - Live Service

/// Calls the Worker endpoint, decodes the simplified JSON, and surfaces
/// meaningful errors. Never talks to Unsplash directly.
final class DescribePictureImageService: DescribePictureImageProviding {

    private let endpointURL: URL
    private let session: URLSession
    private let timeoutInterval: TimeInterval

    init(
        endpointURL: URL,
        session: URLSession = .shared,
        timeoutInterval: TimeInterval = 20
    ) {
        self.endpointURL = endpointURL
        self.session = session
        self.timeoutInterval = timeoutInterval
    }

    private struct WorkerResponse: Decodable {
        let id: String?
        let imageURL: String?
        let authorName: String?
        let authorURL: String?
        let error: String?
    }

    func fetchRandomImage() async throws -> DescribePictureImage {
        #if DEBUG
        print("[DescribePictureImage] → POST \(endpointURL.path) image request started")
        #endif

        var request = URLRequest(url: endpointURL, timeoutInterval: timeoutInterval)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            #if DEBUG
            print("[DescribePictureImage] network error: \(error.localizedDescription)")
            #endif
            throw DescribePictureImageError.network(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw DescribePictureImageError.invalidResponse
        }

        #if DEBUG
        print("[DescribePictureImage] worker response HTTP \(http.statusCode)")
        #endif

        if http.statusCode == 429 {
            throw DescribePictureImageError.rateLimited
        }

        let envelope: WorkerResponse
        do {
            envelope = try JSONDecoder().decode(WorkerResponse.self, from: data)
            #if DEBUG
            print("[DescribePictureImage] decode success")
            #endif
        } catch {
            #if DEBUG
            print("[DescribePictureImage] decode failure: \(error)")
            #endif
            throw DescribePictureImageError.invalidResponse
        }

        guard (200...299).contains(http.statusCode) else {
            throw DescribePictureImageError.serverError(http.statusCode)
        }

        guard
            let id = envelope.id, !id.isEmpty,
            let imageURL = envelope.imageURL, !imageURL.isEmpty
        else {
            throw DescribePictureImageError.noImage
        }

        return DescribePictureImage(
            id: id,
            imageURL: imageURL,
            authorName: (envelope.authorName?.isEmpty == false) ? envelope.authorName! : "Unknown",
            authorURL: envelope.authorURL ?? "https://unsplash.com"
        )
    }
}

// MARK: - Mock

/// Offline provider for previews/tests and when the Worker URL is unset.
final class MockDescribePictureImageService: DescribePictureImageProviding {
    private let samples: [DescribePictureImage]
    private var index = 0

    init(samples: [DescribePictureImage]? = nil) {
        self.samples = samples ?? [
            DescribePictureImage(
                id: "mock-1",
                imageURL: "https://images.unsplash.com/photo-1506744038136-46273834b3fb",
                authorName: "Sample Photographer",
                authorURL: "https://unsplash.com"
            ),
            DescribePictureImage(
                id: "mock-2",
                imageURL: "https://images.unsplash.com/photo-1469474968028-56623f02e42e",
                authorName: "Sample Photographer",
                authorURL: "https://unsplash.com"
            )
        ]
    }

    func fetchRandomImage() async throws -> DescribePictureImage {
        try? await Task.sleep(nanoseconds: 250_000_000)
        defer { index = (index + 1) % samples.count }
        return samples[index]
    }
}
