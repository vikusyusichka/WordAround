import Foundation
import FirebaseAuth

struct CreateSetSavingUseCase {
    private let validator: CreateSetValidator
    private let iconSuggester: CreateSetIconSuggester
    private let builder: CreateSetBuilder
    private let setService: FlashcardSetService

    init(
        validator: CreateSetValidator = CreateSetValidator(),
        iconSuggester: CreateSetIconSuggester = CreateSetIconSuggester(),
        builder: CreateSetBuilder = CreateSetBuilder(),
        setService: FlashcardSetService = FlashcardSetService()
    ) {
        self.validator = validator
        self.iconSuggester = iconSuggester
        self.builder = builder
        self.setService = setService
    }

    func createSet(from draft: CreateFlashcardSetDraft) async throws {
        guard let user = Auth.auth().currentUser else {
            throw CreateSetValidationErrorWrapper(message: "User is not signed in.")
        }

        let validCards = try validator.validate(draft)
        let resolvedIcon = resolvedIcon(for: draft)

        let set = try builder.makeSet(
            from: draft,
            validCards: validCards,
            user: user,
            resolvedIcon: resolvedIcon
        )

        try await setService.createSet(set)
    }

    func resolvedIcon(for draft: CreateFlashcardSetDraft) -> String {
        guard draft.selectedIcon.isEmpty || draft.selectedIcon == "rectangle.stack.fill" else {
            return draft.selectedIcon
        }

        return iconSuggester.suggestedIcon(for: draft.title)
    }
}

struct CreateSetValidationErrorWrapper: LocalizedError {
    let message: String

    var errorDescription: String? {
        message
    }
}
