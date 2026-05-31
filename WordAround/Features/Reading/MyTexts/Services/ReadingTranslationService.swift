import Foundation

struct ReadingTranslationService {
    private let assistanceService: EssayAssistanceService

    init(assistanceService: EssayAssistanceService = EssayAssistanceService()) {
        self.assistanceService = assistanceService
    }

    func translate(
        word: String,
        from sourceLanguage: GrammarLanguage,
        to targetLanguage: GrammarLanguage
    ) async throws -> String {
        try await assistanceService.translate(
            text: word,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage
        )
    }

    static func defaultTargetLanguage(for textLanguage: GrammarLanguage) -> GrammarLanguage {
        if let deviceLanguage = preferredDeviceLanguage(), deviceLanguage != textLanguage {
            return deviceLanguage
        }
        if textLanguage != .english { return .english }
        return .ukrainian
    }

    private static func preferredDeviceLanguage() -> GrammarLanguage? {
        for identifier in Locale.preferredLanguages {
            let code = Locale(identifier: identifier).language.languageCode?.identifier.lowercased()
            guard let code else { continue }

            if let match = GrammarLanguage.allCases.first(where: { $0.rawValue == code }) {
                return match
            }
            if let match = GrammarLanguage.allCases.first(where: { $0.shortTitle.lowercased() == code }) {
                return match
            }
        }
        return nil
    }
}
