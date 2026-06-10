import Foundation

final class CloudflarePronunciationContentClient {

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
        let difficulty: String
        let focus: String
        let count: Int
        let avoidItems: [String]
        let seed: String
    }

    private struct WorkerResponse: Decodable {
        struct Item: Decodable {
            let id: String?
            let type: String?
            let text: String?
            let translation: String?
            let languageCode: String?
            let level: String?
            let difficulty: String?
            let focusSound: String?
            let tip: String?
            let example: String?
        }
        let items: [Item]?
        let error: String?
    }

    func generateItems(
        language: GrammarLanguage,
        level: EssayDifficulty,
        difficulty: PronunciationDifficulty,
        focus: PronunciationFocus,
        count: Int,
        avoidItems: [String]
    ) async throws -> [PronunciationItem] {
        let code = language.shortTitle.lowercased()
        let seed = "\(UUID().uuidString.prefix(8))-\(Int(Date().timeIntervalSince1970))"

        #if DEBUG
        print("[PronunciationAI] → POST \(endpointURL.path) lang=\(language.title) code=\(code) level=\(level.rawValue) difficulty=\(difficulty.rawValue) focus=\(focus.promptValue) count=\(count) seed=\(seed)")
        #endif

        var request = URLRequest(url: endpointURL, timeoutInterval: timeoutInterval)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let body = WorkerRequest(
            language: language.title,
            languageCode: code,
            level: level.rawValue,
            difficulty: difficulty.rawValue,
            focus: focus.promptValue,
            count: count,
            avoidItems: Array(avoidItems.suffix(40)),
            seed: seed
        )

        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            throw PronunciationContentError.invalidResponse
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw PronunciationContentError.network(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw PronunciationContentError.invalidResponse
        }

        #if DEBUG
        print("[PronunciationAI] ← HTTP \(http.statusCode)")
        #endif

        let envelope: WorkerResponse
        do {
            envelope = try JSONDecoder().decode(WorkerResponse.self, from: data)
        } catch {
            throw PronunciationContentError.invalidResponse
        }

        guard (200...299).contains(http.statusCode) else {
            throw PronunciationContentError.serverError(http.statusCode, envelope.error ?? "")
        }

        let mapped: [PronunciationItem] = (envelope.items ?? []).compactMap { dto in
            guard let text = dto.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else {
                return nil
            }
            let type = PronunciationItemType(rawValue: dto.type ?? "word") ?? .word
            return PronunciationItem(
                type: type,
                text: text,
                translation: clean(dto.translation),
                languageCode: (dto.languageCode?.isEmpty == false) ? dto.languageCode! : code,
                level: level,
                difficulty: difficulty,
                focusSound: clean(dto.focusSound),
                tip: clean(dto.tip),
                example: clean(dto.example)
            )
        }

        #if DEBUG
        print("[PronunciationAI] decoded items=\(mapped.count)")
        #endif

        return mapped
    }

    private func clean(_ value: String?) -> String? {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines)
        return (trimmed?.isEmpty == false) ? trimmed : nil
    }
}

struct PronunciationRecentItemStore {

    static let shared = PronunciationRecentItemStore()
    static let maxPerBucket = 30

    private let defaults: UserDefaults
    private let keyPrefix = "pronunciation.recentItems."

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func recentItems(
        language: GrammarLanguage,
        level: EssayDifficulty,
        difficulty: PronunciationDifficulty
    ) -> [String] {
        defaults.stringArray(forKey: bucketKey(language, level, difficulty)) ?? []
    }

    func remember(
        texts: [String],
        language: GrammarLanguage,
        level: EssayDifficulty,
        difficulty: PronunciationDifficulty
    ) {
        let key = bucketKey(language, level, difficulty)
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
        _ difficulty: PronunciationDifficulty
    ) -> String {
        "\(keyPrefix)\(language.rawValue).\(level.rawValue).\(difficulty.rawValue)"
    }
}
