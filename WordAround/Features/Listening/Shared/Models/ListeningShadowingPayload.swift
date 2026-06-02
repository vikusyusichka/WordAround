import Foundation

struct ListeningShadowingPayload: Equatable, Hashable {
    let title: String
    let language: GrammarLanguage
    let level: EssayDifficulty
    var phrases: [String]
    var selectedWords: [ListeningTranslationResult]

    var isEmpty: Bool { phrases.isEmpty && selectedWords.isEmpty }

    var speakingSetup: SpeakingConversationSetup {
        SpeakingConversationSetup(language: language, level: level, scenario: nil, length: .short)
    }

    func makeShadowingPhrases() -> [ShadowingPhrase] {
        let languageCode = language.shortTitle.lowercased()
        let category = ShadowingCategory.fromVideo

        if !selectedWords.isEmpty {
            return selectedWords.map { word in
                ShadowingPhrase(
                    text: word.originalText,
                    translation: word.translatedText,
                    languageCode: languageCode,
                    level: level,
                    category: category,
                    tip: word.contextSentence
                )
            }
        }

        let cuePhrases = phrases
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return cuePhrases.map { text in
            ShadowingPhrase(
                text: text,
                translation: nil,
                languageCode: languageCode,
                level: level,
                category: category
            )
        }
    }
}
