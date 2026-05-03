import Foundation

enum CreateSetValidationError: LocalizedError {
    case emptyTitle
    case titleTooLong
    case descriptionTooLong
    case noValidCards
    case exampleTooLong

    var errorDescription: String? {
        switch self {
        case .emptyTitle:
            return "Set title is required."
        case .titleTooLong:
            return "Set title must be under 150 characters."
        case .descriptionTooLong:
            return "Description must be under 200 characters."
        case .noValidCards:
            return "Add at least one card with a word and translation."
        case .exampleTooLong:
            return "Card examples must be under 150 characters."
        }
    }
}

struct CreateSetValidator {
    func validate(_ draft: CreateFlashcardSetDraft) throws -> [CreateFlashcardDraft] {
        let title = draft.title.trimmed
        let description = draft.description.trimmed

        guard !title.isEmpty else {
            throw CreateSetValidationError.emptyTitle
        }

        guard title.count <= 150 else {
            throw CreateSetValidationError.titleTooLong
        }

        guard description.count <= 200 else {
            throw CreateSetValidationError.descriptionTooLong
        }

        let validCards = draft.cards.filter { card in
            !card.word.trimmed.isEmpty && !card.translation.trimmed.isEmpty
        }

        guard !validCards.isEmpty else {
            throw CreateSetValidationError.noValidCards
        }

        guard validCards.allSatisfy({ $0.example.trimmed.count <= 150 }) else {
            throw CreateSetValidationError.exampleTooLong
        }

        return validCards
    }
}

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
