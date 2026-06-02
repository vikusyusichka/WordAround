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

        guard let validated = validateTranslationResult(result, originalText: trimmed) else {
            throw EssayAssistanceServiceError.emptyResult
        }

        return validated
    }

    func synonyms(
        for word: String,
        sourceLanguage: GrammarLanguage,
        targetLanguage: GrammarLanguage
    ) async throws -> [EssayAssistanceItem] {
        let trimmed = word.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            throw EssayAssistanceServiceError.emptyResult
        }

        let englishSynonyms: [String]

        if sourceLanguage == .english {
            englishSynonyms = try await requestSynonyms(for: trimmed)
        } else {
            let meansLike = (try? await requestMeansLike(for: trimmed)) ?? []

            if !meansLike.isEmpty {
                englishSynonyms = meansLike
            } else {
                let englishWord = try await translateWordReliably(trimmed, from: sourceLanguage)
                englishSynonyms = try await requestSynonyms(for: englishWord)
            }
        }

        let finalResults: [String]
        if targetLanguage == .english {
            finalResults = englishSynonyms
        } else {
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

    private func requestSynonyms(for word: String) async throws -> [String] {
        let results = try await datamuseRequest(queryItems: [
            URLQueryItem(name: "rel_syn", value: word),
            URLQueryItem(name: "max", value: "12")
        ])
        guard !results.isEmpty else { throw EssayAssistanceServiceError.emptyResult }
        return results
    }

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

    private func validateTranslationResult(
        _ result: String,
        originalText: String
    ) -> String? {
        let trimmed = result.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if trimmed.caseInsensitiveCompare(originalText) == .orderedSame { return nil }

        let inputWords = originalText.split { $0.isWhitespace }.filter { !$0.isEmpty }.count
        let resultWords = trimmed.split { $0.isWhitespace }.filter { !$0.isEmpty }.count
        if inputWords == 1 && resultWords > 2 { return nil }

        if trimmed.contains(where: { $0.isNumber }) { return nil }

        return trimmed
    }

    private func deduplicated(_ words: [String]) -> [String] {
        var seen = Set<String>()
        return words
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && seen.insert($0.lowercased()).inserted }
            .sorted()
    }
}

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

private extension GrammarLanguage {
    var apiCode: String {
        shortTitle.lowercased()
    }
}
