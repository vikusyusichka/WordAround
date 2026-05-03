import Foundation
import FirebaseAuth

struct CreateSetBuilder {
    private let imageStorageService: LocalImageStorageService

    init(imageStorageService: LocalImageStorageService = LocalImageStorageService()) {
        self.imageStorageService = imageStorageService
    }

    func makeSet(
        from draft: CreateFlashcardSetDraft,
        validCards: [CreateFlashcardDraft],
        user: User,
        resolvedIcon: String
    ) throws -> FlashcardSet {
        let setID = UUID().uuidString
        let cards = try makeCards(from: validCards, userID: user.uid, setID: setID)

        return FlashcardSet(
            id: setID,
            ownerUID: user.uid,
            ownerEmail: user.email ?? "",
            title: draft.title.trimmed,
            description: draft.description.trimmed,
            privacy: draft.privacy.rawValue,
            folderID: draft.folderID,
            folderName: draft.folderName,
            colorHex: draft.selectedColor.hex,
            icon: .systemName(resolvedIcon),
            cards: cards,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    private func makeCards(
        from drafts: [CreateFlashcardDraft],
        userID: String,
        setID: String
    ) throws -> [Flashcard] {
        try drafts.map { card in
            var localImageFileName: String?

            if let selectedImage = card.selectedImage {
                let fileName = "\(userID)_\(setID)_\(card.id.uuidString).jpg"
                localImageFileName = try imageStorageService.saveImage(selectedImage, fileName: fileName)
            }

            return Flashcard(
                id: card.id.uuidString,
                word: card.word.trimmed,
                translation: card.translation.trimmed,
                example: card.example.trimmed,
                imageURL: localImageFileName
            )
        }
    }
}

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
