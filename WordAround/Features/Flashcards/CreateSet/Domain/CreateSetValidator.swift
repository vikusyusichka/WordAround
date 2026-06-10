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
            return L10n.string("createSetTitleRequired")
        case .titleTooLong:
            return L10n.string("createSetTitleTooLong")
        case .descriptionTooLong:
            return L10n.string("createSetDescTooLong")
        case .noValidCards:
            return L10n.string("createSetAddAtLeastOne")
        case .exampleTooLong:
            return L10n.string("createSetExampleTooLong")
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

extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
