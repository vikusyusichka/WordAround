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

        return try await requestTranslation(
            text: trimmed,
            sourceCode: sourceLanguage.apiCode,
            targetCode: targetLanguage.apiCode
        )
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

        let englishInput: String

        if sourceLanguage == .english {
            englishInput = trimmed
        } else {
            englishInput = try await requestTranslation(
                text: trimmed,
                sourceCode: sourceLanguage.apiCode,
                targetCode: GrammarLanguage.english.apiCode
            )
        }

        let englishSynonyms = try await requestEnglishSynonyms(for: englishInput)

        let finalResults: [String]

        if targetLanguage == .english {
            finalResults = englishSynonyms
        } else {
            var translatedResults: [String] = []

            for synonym in englishSynonyms.prefix(8) {
                if let translated = try? await requestTranslation(
                    text: synonym,
                    sourceCode: GrammarLanguage.english.apiCode,
                    targetCode: targetLanguage.apiCode
                ) {
                    translatedResults.append(translated)
                }
            }

            finalResults = translatedResults
        }

        let uniqueResults = Array(
            Set(
                finalResults
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
            )
        )
        .sorted()

        guard !uniqueResults.isEmpty else {
            throw EssayAssistanceServiceError.emptyResult
        }

        return uniqueResults.map {
            EssayAssistanceItem(
                word: trimmed,
                result: $0,
                detail: nil
            )
        }
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

        guard let httpResponse = response as? HTTPURLResponse else {
            throw EssayAssistanceServiceError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw EssayAssistanceServiceError.serverError(httpResponse.statusCode)
        }

        let decoded = try JSONDecoder().decode(MyMemoryResponse.self, from: data)
        let translated = decoded.responseData.translatedText
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !translated.isEmpty else {
            throw EssayAssistanceServiceError.emptyResult
        }

        return translated
    }

    private func requestEnglishSynonyms(for word: String) async throws -> [String] {
        var components = URLComponents(string: "https://api.datamuse.com/words")
        components?.queryItems = [
            URLQueryItem(name: "rel_syn", value: word),
            URLQueryItem(name: "max", value: "12")
        ]

        guard let url = components?.url else {
            throw EssayAssistanceServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = timeoutInterval

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw EssayAssistanceServiceError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw EssayAssistanceServiceError.serverError(httpResponse.statusCode)
        }

        let decoded = try JSONDecoder().decode([DatamuseWord].self, from: data)

        let words = decoded
            .map(\.word)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !words.isEmpty else {
            throw EssayAssistanceServiceError.emptyResult
        }

        return words
    }
}

private struct MyMemoryResponse: Decodable {
    let responseData: MyMemoryResponseData
}

private struct MyMemoryResponseData: Decodable {
    let translatedText: String
}

private struct DatamuseWord: Decodable {
    let word: String
}

private extension GrammarLanguage {
    var apiCode: String {
        switch self {
        case .english:
            return "en"
        case .spanish:
            return "es"
        case .french:
            return "fr"
        case .german:
            return "de"
        }
    }
}
