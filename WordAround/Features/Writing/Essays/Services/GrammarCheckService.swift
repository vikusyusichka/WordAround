import Foundation

protocol GrammarChecking {
    func check(text: String, language: String) async throws -> [GrammarIssue]
}

enum GrammarCheckServiceError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(Int)
    case decodingFailed
    case emptyText
    case textTooLong(Int)
    case unsupportedLanguage

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Grammar checker URL is invalid."
        case .invalidResponse:
            return "Grammar checker returned an invalid response."
        case .serverError(let code):
            return "Grammar checker failed with status code \(code)."
        case .decodingFailed:
            return "Could not read grammar feedback."
        case .emptyText:
            return "Write something before checking grammar."
        case .textTooLong(let limit):
            return "Try to keep your essay under \(limit) characters."
        case .unsupportedLanguage:
            return "Grammar checking is currently unavailable for this language."
        }
    }
}

final class GrammarCheckService: GrammarChecking {
    private let endpoint = "https://api.languagetool.org/v2/check"
    private let session: URLSession
    private let maxCharacterLimit: Int
    private let timeoutInterval: TimeInterval

    init(
        session: URLSession = .shared,
        maxCharacterLimit: Int = 6_000,
        timeoutInterval: TimeInterval = 20
    ) {
        self.session = session
        self.maxCharacterLimit = maxCharacterLimit
        self.timeoutInterval = timeoutInterval
    }

    func check(text: String, language: String = "en-US") async throws -> [GrammarIssue] {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedText.isEmpty else {
            throw GrammarCheckServiceError.emptyText
        }

        guard trimmedText.count <= maxCharacterLimit else {
            throw GrammarCheckServiceError.textTooLong(maxCharacterLimit)
        }

        guard let url = URL(string: endpoint) else {
            throw GrammarCheckServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = timeoutInterval
        request.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = makeRequestBody(text: trimmedText, language: language)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GrammarCheckServiceError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw GrammarCheckServiceError.serverError(httpResponse.statusCode)
        }

        do {
            let decoded = try JSONDecoder().decode(LanguageToolResponse.self, from: data)

            return decoded.matches.compactMap { match in
                guard let incorrectFragment = trimmedText.safeSubstring(offset: match.offset, length: match.length) else {
                    return nil
                }

                return GrammarIssue(
                    message: match.message,
                    incorrectText: incorrectFragment,
                    suggestedCorrection: match.replacements.first?.value,
                    offset: match.offset,
                    length: match.length,
                    category: GrammarIssueCategory(languageToolCategory: match.rule.category.id)
                )
            }
        } catch {
            throw GrammarCheckServiceError.decodingFailed
        }
    }

    private func makeRequestBody(text: String, language: String) -> Data? {
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "text", value: text),
            URLQueryItem(name: "language", value: language)
        ]

        return components.percentEncodedQuery?.data(using: .utf8)
    }
}

private struct LanguageToolResponse: Decodable {
    let matches: [LanguageToolMatch]
}

private struct LanguageToolMatch: Decodable {
    let message: String
    let offset: Int
    let length: Int
    let replacements: [LanguageToolReplacement]
    let rule: LanguageToolRule
}

private struct LanguageToolReplacement: Decodable {
    let value: String
}

private struct LanguageToolRule: Decodable {
    let category: LanguageToolCategory
}

private struct LanguageToolCategory: Decodable {
    let id: String
}

private extension GrammarIssueCategory {
    init(languageToolCategory: String) {
        let normalized = languageToolCategory.lowercased()

        if normalized.contains("typography") ||
            normalized.contains("style") ||
            normalized.contains("misc") {
            self = .style
        } else if normalized.contains("vocabulary") ||
                    normalized.contains("confused_words") ||
                    normalized.contains("wordiness") {
            self = .vocabulary
        } else {
            self = .grammar
        }
    }
}

private extension String {
    func safeSubstring(offset: Int, length: Int) -> String? {
        guard offset >= 0, length >= 0 else { return nil }

        let utf16View = self.utf16

        guard
            let from = utf16View.index(utf16View.startIndex, offsetBy: offset, limitedBy: utf16View.endIndex),
            let to = utf16View.index(from, offsetBy: length, limitedBy: utf16View.endIndex),
            let startIndex = String.Index(from, within: self),
            let endIndex = String.Index(to, within: self)
        else {
            return nil
        }

        return String(self[startIndex..<endIndex])
    }
}
