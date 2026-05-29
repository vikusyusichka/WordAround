import Foundation

/// Calls the Worker endpoint `POST /api/shadowing/phrases`, decodes the
/// strict JSON phrase set, and maps it to `[ShadowingPhrase]`.
///
/// The Gemini key lives only in the Worker — this client only knows the
/// Worker URL. Never talks to an AI provider directly.
final class CloudflareShadowingPhraseClient {

    private let endpointURL: URL
    private let session: URLSession
    private let timeoutInterval: TimeInterval

    init(endpointURL: URL, session: URLSession = .shared, timeoutInterval: TimeInterval = 25) {
        self.endpointURL = endpointURL
        self.session = session
        self.timeoutInterval = timeoutInterval
    }

    private struct WorkerRequest: Encodable {
        let language: String
        let languageCode: String
        let level: String
        let category: String
        let count: Int
        let avoidPhrases: [String]
        let seed: String
    }

    private struct WorkerResponse: Decodable {
        struct Phrase: Decodable {
            let id: String?
            let text: String?
            let translation: String?
            let languageCode: String?
            let level: String?
            let category: String?
            let tip: String?
        }
        let phrases: [Phrase]?
        let error: String?
    }

    func generatePhrases(
        language: GrammarLanguage,
        level: EssayDifficulty,
        category: ShadowingCategory,
        count: Int,
        avoidPhrases: [String]
    ) async throws -> [ShadowingPhrase] {
        let code = language.shortTitle.lowercased()
        let seed = "\(UUID().uuidString.prefix(8))-\(Int(Date().timeIntervalSince1970))"

        #if DEBUG
        print("[ShadowingPhraseAI] → POST \(endpointURL.path) lang=\(language.title) code=\(code) level=\(level.rawValue) category=\(category.title) count=\(count) seed=\(seed)")
        #endif

        var request = URLRequest(url: endpointURL, timeoutInterval: timeoutInterval)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let body = WorkerRequest(
            language: language.title,
            languageCode: code,
            level: level.rawValue,
            category: category.title,
            count: count,
            avoidPhrases: Array(avoidPhrases.suffix(30)),
            seed: seed
        )

        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            throw ShadowingPhraseError.invalidResponse
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw ShadowingPhraseError.network(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw ShadowingPhraseError.invalidResponse
        }

        #if DEBUG
        print("[ShadowingPhraseAI] ← HTTP \(http.statusCode)")
        #endif

        let envelope: WorkerResponse
        do {
            envelope = try JSONDecoder().decode(WorkerResponse.self, from: data)
        } catch {
            throw ShadowingPhraseError.invalidResponse
        }

        guard (200...299).contains(http.statusCode) else {
            throw ShadowingPhraseError.serverError(http.statusCode, envelope.error ?? "")
        }

        let mapped: [ShadowingPhrase] = (envelope.phrases ?? []).compactMap { dto in
            guard let text = dto.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else {
                return nil
            }
            let translation = dto.translation?.trimmingCharacters(in: .whitespacesAndNewlines)
            let tip = dto.tip?.trimmingCharacters(in: .whitespacesAndNewlines)
            return ShadowingPhrase(
                text: text,
                translation: (translation?.isEmpty == false) ? translation : nil,
                languageCode: (dto.languageCode?.isEmpty == false) ? dto.languageCode! : code,
                level: level,
                category: category,
                tip: (tip?.isEmpty == false) ? tip : nil
            )
        }

        #if DEBUG
        print("[ShadowingPhraseAI] decoded phrases=\(mapped.count)")
        #endif

        return mapped
    }
}

// MARK: - Recent Phrase Store

/// Remembers recently generated/used phrase texts per language+level+category
/// so fresh sessions can ask the AI to avoid repeats (and the local fallback
/// can rotate). Mirrors `SpeakingRecentTopicTitlesStore`.
struct ShadowingRecentPhraseStore {

    static let shared = ShadowingRecentPhraseStore()
    static let maxPerBucket = 20

    private let defaults: UserDefaults
    private let keyPrefix = "shadowing.recentPhrases."

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func recentPhrases(
        language: GrammarLanguage,
        level: EssayDifficulty,
        category: ShadowingCategory
    ) -> [String] {
        defaults.stringArray(forKey: bucketKey(language, level, category)) ?? []
    }

    func remember(
        texts: [String],
        language: GrammarLanguage,
        level: EssayDifficulty,
        category: ShadowingCategory
    ) {
        let key = bucketKey(language, level, category)
        var stored = defaults.stringArray(forKey: key) ?? []
        for text in texts {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            stored.removeAll { $0.caseInsensitiveCompare(trimmed) == .orderedSame }
            stored.append(trimmed)
        }
        if stored.count > Self.maxPerBucket {
            stored.removeFirst(stored.count - Self.maxPerBucket)
        }
        defaults.set(stored, forKey: key)
    }

    private func bucketKey(
        _ language: GrammarLanguage,
        _ level: EssayDifficulty,
        _ category: ShadowingCategory
    ) -> String {
        "\(keyPrefix)\(language.rawValue).\(level.rawValue).\(category.rawValue)"
    }
}
