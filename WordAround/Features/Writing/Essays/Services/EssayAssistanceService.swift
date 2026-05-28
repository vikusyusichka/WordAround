import Foundation

enum EssayAssistanceServiceError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(Int)
    case emptyResult
    case sameLanguage

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Something went wrong with the request."
        case .invalidResponse:
            return "The service returned an unexpected response."
        case .serverError:
            return "The service is temporarily unavailable."
        case .emptyResult:
            return "No result found."
        case .sameLanguage:
            return "Choose a different input language."
        }
    }
}

final class EssayAssistanceService {

    private let session: URLSession
    private let timeoutInterval: TimeInterval

    init(session: URLSession = .shared, timeoutInterval: TimeInterval = 20) {
        self.session = session
        self.timeoutInterval = timeoutInterval
    }

    // MARK: - Translation

    func translate(
        text: String,
        sourceLanguage: GrammarLanguage,
        targetLanguage: GrammarLanguage
    ) async throws -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            throw EssayAssistanceServiceError.emptyResult
        }

        guard sourceLanguage != targetLanguage else {
            throw EssayAssistanceServiceError.sameLanguage
        }

        let result = try await requestTranslation(
            text: trimmed,
            sourceCode: sourceLanguage.apiCode,
            targetCode: targetLanguage.apiCode
        )

        // MyMemory sometimes returns the original word unchanged or a brand name
        // for single-word lookups. Validate before returning.
        guard let validated = validateTranslationResult(result, originalText: trimmed) else {
            throw EssayAssistanceServiceError.emptyResult
        }

        return validated
    }

    // MARK: - Synonyms

    func synonyms(
        for word: String,
        sourceLanguage: GrammarLanguage,
        targetLanguage: GrammarLanguage
    ) async throws -> [EssayAssistanceItem] {
        let trimmed = word.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            throw EssayAssistanceServiceError.emptyResult
        }

        // Strategy — avoids the MyMemory single-word failure:
        //
        // 1. If source is English: find synonyms directly via Datamuse rel_syn.
        // 2. If source is non-English:
        //    a. Try Datamuse "means-like" (`ml`) on the original word.
        //       Datamuse understands many common non-English words natively.
        //    b. If that returns nothing, translate to English with quality validation,
        //       then find synonyms for the English word.
        // 3. If target is not English, translate the resulting synonym list in parallel.

        let englishSynonyms: [String]

        if sourceLanguage == .english {
            englishSynonyms = try await requestSynonyms(for: trimmed)
        } else {
            // Try means-like first — completely avoids MyMemory for the input word
            let meansLike = (try? await requestMeansLike(for: trimmed)) ?? []

            if !meansLike.isEmpty {
                englishSynonyms = meansLike
            } else {
                // Fallback: translate to English, then find synonyms
                let englishWord = try await translateWordReliably(trimmed, from: sourceLanguage)
                englishSynonyms = try await requestSynonyms(for: englishWord)
            }
        }

        let finalResults: [String]
        if targetLanguage == .english {
            finalResults = englishSynonyms
        } else {
            // Translate synonyms to target language in parallel (not sequential)
            finalResults = await translateSynonymsInParallel(
                Array(englishSynonyms.prefix(8)),
                targetCode: targetLanguage.apiCode
            )
        }

        let unique = deduplicated(finalResults)
        guard !unique.isEmpty else {
            throw EssayAssistanceServiceError.emptyResult
        }

        return unique.map { EssayAssistanceItem(word: trimmed, result: $0, detail: nil) }
    }

    // MARK: - Private: Datamuse

    /// Standard English synonym lookup via `rel_syn`.
    private func requestSynonyms(for word: String) async throws -> [String] {
        let results = try await datamuseRequest(queryItems: [
            URLQueryItem(name: "rel_syn", value: word),
            URLQueryItem(name: "max", value: "12")
        ])
        guard !results.isEmpty else { throw EssayAssistanceServiceError.emptyResult }
        return results
    }

    /// "Means like" — Datamuse understands many non-English words via this param
    /// and returns conceptually-similar English words.
    /// Much more reliable for non-English single words than MyMemory.
    private func requestMeansLike(for word: String) async throws -> [String] {
        return try await datamuseRequest(queryItems: [
            URLQueryItem(name: "ml", value: word),
            URLQueryItem(name: "max", value: "12")
        ])
    }

    private func datamuseRequest(queryItems: [URLQueryItem]) async throws -> [String] {
        var components = URLComponents(string: "https://api.datamuse.com/words")
        components?.queryItems = queryItems

        guard let url = components?.url else {
            throw EssayAssistanceServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = timeoutInterval

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw EssayAssistanceServiceError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            throw EssayAssistanceServiceError.serverError(http.statusCode)
        }

        return try JSONDecoder()
            .decode([DatamuseWord].self, from: data)
            .map(\.word)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    // MARK: - Private: MyMemory translation

    /// Translates a single word to English with quality validation.
    /// Throws `.emptyResult` if MyMemory returns garbage (brand name, unchanged word, etc.)
    private func translateWordReliably(
        _ word: String,
        from sourceLanguage: GrammarLanguage
    ) async throws -> String {
        let raw = try await requestTranslation(
            text: word,
            sourceCode: sourceLanguage.apiCode,
            targetCode: GrammarLanguage.english.apiCode
        )
        guard let validated = validateTranslationResult(raw, originalText: word) else {
            throw EssayAssistanceServiceError.emptyResult
        }
        return validated
    }

    private func requestTranslation(
        text: String,
        sourceCode: String,
        targetCode: String
    ) async throws -> String {
        guard sourceCode != targetCode else {
            throw EssayAssistanceServiceError.sameLanguage
        }

        var components = URLComponents(string: "https://api.mymemory.translated.net/get")
        components?.queryItems = [
            URLQueryItem(name: "q", value: text),
            URLQueryItem(name: "langpair", value: "\(sourceCode)|\(targetCode)")
        ]

        guard let url = components?.url else {
            throw EssayAssistanceServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = timeoutInterval

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw EssayAssistanceServiceError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            throw EssayAssistanceServiceError.serverError(http.statusCode)
        }

        let decoded = try JSONDecoder().decode(MyMemoryResponse.self, from: data)

        // responseStatus 200 = OK; 403/429/etc = quota exceeded or error
        guard decoded.responseStatus == 200 else {
            throw EssayAssistanceServiceError.serverError(decoded.responseStatus)
        }

        let translated = decoded.responseData.translatedText
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !translated.isEmpty else {
            throw EssayAssistanceServiceError.emptyResult
        }

        return translated
    }

    // MARK: - Private: Parallel translation

    /// Translates a list of English synonyms to the target language concurrently.
    /// Individual failures are silently dropped so partial results still display.
    private func translateSynonymsInParallel(
        _ synonyms: [String],
        targetCode: String
    ) async -> [String] {
        await withTaskGroup(of: String?.self) { group in
            for synonym in synonyms {
                group.addTask { [weak self] in
                    guard let self else { return nil }
                    return try? await self.requestTranslation(
                        text: synonym,
                        sourceCode: GrammarLanguage.english.apiCode,
                        targetCode: targetCode
                    )
                }
            }
            var results: [String] = []
            for await result in group {
                if let result { results.append(result) }
            }
            return results
        }
    }

    // MARK: - Private: Validation

    /// Guards against MyMemory's known failure modes for single-word lookups:
    ///
    /// • Returns the original word unchanged (no real translation found).
    ///   Example: "suave" ES→EN → "suave"
    ///
    /// • Returns a brand/product name instead of a translation.
    ///   Example: "suave" ES→EN → "Body Wash"  (Suave is a US haircare brand)
    ///
    /// Heuristics:
    ///   1. Reject if result == input (case-insensitive).
    ///   2. For single-word input: reject if result is 3+ words
    ///      (brand expansions are almost always multi-word).
    ///   3. Reject results containing digits.
    private func validateTranslationResult(
        _ result: String,
        originalText: String
    ) -> String? {
        let trimmed = result.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        // Rule 1: unchanged
        if trimmed.caseInsensitiveCompare(originalText) == .orderedSame { return nil }

        // Rule 2: too many words for a single-word input
        let inputWords = originalText.split { $0.isWhitespace }.filter { !$0.isEmpty }.count
        let resultWords = trimmed.split { $0.isWhitespace }.filter { !$0.isEmpty }.count
        if inputWords == 1 && resultWords > 2 { return nil }

        // Rule 3: contains digits
        if trimmed.contains(where: { $0.isNumber }) { return nil }

        return trimmed
    }

    // MARK: - Private: Utilities

    private func deduplicated(_ words: [String]) -> [String] {
        var seen = Set<String>()
        return words
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && seen.insert($0.lowercased()).inserted }
            .sorted()
    }
}

// MARK: - Private response models

private struct MyMemoryResponse: Decodable {
    let responseData: MyMemoryResponseData
    let responseStatus: Int
}

private struct MyMemoryResponseData: Decodable {
    let translatedText: String
}

private struct DatamuseWord: Decodable {
    let word: String
}

// MARK: - GrammarLanguage API code

private extension GrammarLanguage {
    /// ISO 639-1 code used by MyMemory + Datamuse. Derived from
    /// `shortTitle` (which is the ISO code, uppercased) so adding a new
    /// language case auto-propagates without touching this file.
    var apiCode: String {
        shortTitle.lowercased()
    }
}
