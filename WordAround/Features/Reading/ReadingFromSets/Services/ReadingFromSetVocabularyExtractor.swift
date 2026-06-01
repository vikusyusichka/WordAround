import Foundation

enum ReadingFromSetVocabularyExtractor {
    static let minimumWords = 5

    enum ExtractionError: LocalizedError {
        case tooFewWords(found: Int)

        var errorDescription: String? {
            switch self {
            case .tooFewWords:
                return "This set needs at least \(minimumWords) words to create a reading."
            }
        }
    }

    static func extract(from set: FlashcardSet) throws -> ReadingFromSetVocabulary {
        let vocabulary = makeVocabulary(from: set)
        guard vocabulary.count >= minimumWords else {
            throw ExtractionError.tooFewWords(found: vocabulary.count)
        }
        return vocabulary
    }

    static func makeVocabulary(from set: FlashcardSet) -> ReadingFromSetVocabulary {
        var seen = Set<String>()
        var words: [ReadingFromSetWord] = []

        for card in set.cards {
            let term = card.word.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !term.isEmpty else { continue }

            let key = term.lowercased()
            guard !seen.contains(key) else { continue }
            seen.insert(key)

            let translation = card.translation.trimmingCharacters(in: .whitespacesAndNewlines)
            let example = card.example.trimmingCharacters(in: .whitespacesAndNewlines)

            words.append(
                ReadingFromSetWord(
                    term: term,
                    translation: translation.isEmpty ? nil : translation,
                    example: example.isEmpty ? nil : example
                )
            )
        }

        return ReadingFromSetVocabulary(setId: set.id, setTitle: set.title, words: words)
    }
}
