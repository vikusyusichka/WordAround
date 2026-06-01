import Foundation

/// Translates a subtitle / transcript line. Kept behind a protocol so the
/// concrete backend (the app's existing assistance service today, a dedicated
/// API later) can be swapped without touching view models or views.
protocol ListeningTranslationServicing {
    func translate(text: String, from source: GrammarLanguage, to target: GrammarLanguage) async throws -> String
}

extension ListeningTranslationServicing {
    /// Best translation target for the user's device, never the source language.
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
}

/// Real translation backed by the app's existing `EssayAssistanceService`
/// (the same backend Reading uses for word translation).
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

/// Mock translator for previews and tests — echoes the text with a target tag,
/// no network calls or permissions required.
struct MockListeningTranslationService: ListeningTranslationServicing {
    var delayNanoseconds: UInt64 = 400_000_000

    func translate(text: String, from source: GrammarLanguage, to target: GrammarLanguage) async throws -> String {
        try? await Task.sleep(nanoseconds: delayNanoseconds)
        return "[\(target.shortTitle)] \(text)"
    }
}
