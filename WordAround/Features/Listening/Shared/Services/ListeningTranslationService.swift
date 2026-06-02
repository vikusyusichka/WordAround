import Foundation

struct ListeningTranslationResult: Identifiable, Equatable, Hashable, Codable {
    var id: String = UUID().uuidString
    let originalText: String
    let translatedText: String
    let sourceLanguage: GrammarLanguage
    let targetLanguage: GrammarLanguage
    var contextSentence: String?
}

protocol ListeningTranslationServicing {
    func translate(text: String, from source: GrammarLanguage, to target: GrammarLanguage) async throws -> String
}

extension ListeningTranslationServicing {
    func defaultTargetLanguage(for source: GrammarLanguage) -> GrammarLanguage {
        for identifier in Locale.preferredLanguages {
            let code = Locale(identifier: identifier).language.languageCode?.identifier.lowercased()
            if let code,
               let match = GrammarLanguage.allCases.first(where: { $0.rawValue == code }),
               match != source {
                return match
            }
        }
        return source == .english ? .ukrainian : .english
    }

    func translateWord(
        word: String,
        context: String?,
        from source: GrammarLanguage,
        to target: GrammarLanguage
    ) async throws -> ListeningTranslationResult {
        let cleaned = word.trimmingCharacters(in: .whitespacesAndNewlines)
        let translated = try await translate(text: cleaned, from: source, to: target)
        return ListeningTranslationResult(
            originalText: cleaned,
            translatedText: translated,
            sourceLanguage: source,
            targetLanguage: target,
            contextSentence: context
        )
    }
}

struct AIListeningTranslationService: ListeningTranslationServicing {
    private let assistance: EssayAssistanceService

    init(assistance: EssayAssistanceService = EssayAssistanceService()) {
        self.assistance = assistance
    }

    func translate(text: String, from source: GrammarLanguage, to target: GrammarLanguage) async throws -> String {
        try await assistance.translate(
            text: text,
            sourceLanguage: source,
            targetLanguage: target
        )
    }
}

struct MockListeningTranslationService: ListeningTranslationServicing {
    var delayNanoseconds: UInt64 = 400_000_000

    func translate(text: String, from source: GrammarLanguage, to target: GrammarLanguage) async throws -> String {
        try? await Task.sleep(nanoseconds: delayNanoseconds)
        return "[\(target.shortTitle)] \(text)"
    }
}
