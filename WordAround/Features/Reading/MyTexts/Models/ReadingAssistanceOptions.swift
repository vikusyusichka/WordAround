import Foundation

struct ReadingAssistanceOptions: Equatable, Hashable, Codable {
    var highlightUnknownWords: Bool
    var translationOnTap: Bool
    var vocabularyHints: Bool
    var readingTimer: Bool
    var translationTargetLanguageCode: String

    static let `default` = ReadingAssistanceOptions(
        highlightUnknownWords: true,
        translationOnTap: true,
        vocabularyHints: true,
        readingTimer: true,
        translationTargetLanguageCode: ""
    )

    func asToggleDictionary() -> [String: Bool] {
        [
            "highlightUnknownWords": highlightUnknownWords,
            "translationOnTap": translationOnTap,
            "vocabularyHints": vocabularyHints,
            "readingTimer": readingTimer
        ]
    }

    static func from(toggles: [String: Bool]) -> ReadingAssistanceOptions {
        ReadingAssistanceOptions(
            highlightUnknownWords: toggles["highlightUnknownWords", default: true],
            translationOnTap: toggles["translationOnTap", default: true],
            vocabularyHints: toggles["vocabularyHints", default: true],
            readingTimer: toggles["readingTimer", default: true],
            translationTargetLanguageCode: ""
        )
    }

    func resolvedTranslationTarget(sourceLanguage: GrammarLanguage) -> GrammarLanguage {
        if !translationTargetLanguageCode.isEmpty,
           let stored = GrammarLanguage(rawValue: translationTargetLanguageCode),
           stored != sourceLanguage {
            return stored
        }
        return ReadingTranslationService.defaultTargetLanguage(for: sourceLanguage)
    }

    enum CodingKeys: String, CodingKey {
        case highlightUnknownWords
        case translationOnTap
        case vocabularyHints
        case readingTimer
        case translationTargetLanguageCode
    }

    init(
        highlightUnknownWords: Bool,
        translationOnTap: Bool,
        vocabularyHints: Bool,
        readingTimer: Bool,
        translationTargetLanguageCode: String = ""
    ) {
        self.highlightUnknownWords = highlightUnknownWords
        self.translationOnTap = translationOnTap
        self.vocabularyHints = vocabularyHints
        self.readingTimer = readingTimer
        self.translationTargetLanguageCode = translationTargetLanguageCode
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        highlightUnknownWords = try container.decodeIfPresent(Bool.self, forKey: .highlightUnknownWords) ?? true
        translationOnTap = try container.decodeIfPresent(Bool.self, forKey: .translationOnTap) ?? true
        vocabularyHints = try container.decodeIfPresent(Bool.self, forKey: .vocabularyHints) ?? true
        readingTimer = try container.decodeIfPresent(Bool.self, forKey: .readingTimer) ?? true
        translationTargetLanguageCode = try container.decodeIfPresent(String.self, forKey: .translationTargetLanguageCode) ?? ""
    }
}
