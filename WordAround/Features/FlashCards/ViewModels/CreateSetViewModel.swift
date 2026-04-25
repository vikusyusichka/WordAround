import SwiftUI
import Combine
import FirebaseAuth
import PhotosUI
import UIKit

@MainActor
final class CreateSetViewModel: ObservableObject {
    @Published var draft = CreateFlashcardSetDraft()
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var didCreateSet = false
    @Published var theme: CreateSetTheme = .red

    private let setService = FlashcardSetService()
    private let imageStorageService = LocalImageStorageService()

    let availableColors: [SetColor] = SetColor.allCases

    let previewIcons: [String] = [
        "rectangle.stack.fill",
        "book.closed.fill",
        "graduationcap.fill",
        "brain.head.profile",
        "globe.europe.africa.fill",
        "star.fill",
        "heart.fill",
        "bolt.fill",
        "pencil.and.outline",
        "text.book.closed.fill"
    ]

    func addCard() {
        draft.cards.append(CreateFlashcardDraft())
    }

    func selectColor(_ color: SetColor) {
        withAnimation(.easeInOut(duration: 0.25)) {
            draft.selectedColor = color
            theme = CreateSetTheme.theme(for: color)
        }
    }

    func selectIcon(_ icon: String) {
        draft.selectedIcon = icon
    }

    func setImage(for cardID: UUID, from item: PhotosPickerItem) async {
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data),
                  let index = draft.cards.firstIndex(where: { $0.id == cardID }) else {
                errorMessage = "Could not load selected image."
                return
            }

            draft.cards[index].selectedImage = image
            draft.cards[index].imageURL = nil
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createSet() async {
        guard !isSaving else { return }

        guard let user = Auth.auth().currentUser else {
            errorMessage = "User is not signed in."
            return
        }

        let title = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let description = draft.description.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !title.isEmpty else {
            errorMessage = "Set title is required."
            return
        }

        guard title.count <= 150 else {
            errorMessage = "Set title must be under 150 characters."
            return
        }

        guard description.count <= 200 else {
            errorMessage = "Description must be under 200 characters."
            return
        }

        let validCards = draft.cards.filter {
            !$0.word.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !$0.translation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        guard !validCards.isEmpty else {
            errorMessage = "Add at least one card with a word and translation."
            return
        }

        guard !validCards.isEmpty else {
            errorMessage = "Add at least one word before creating a set."
            return
        }

        guard validCards.allSatisfy({ $0.example.trimmingCharacters(in: .whitespacesAndNewlines).count <= 150 }) else {
            errorMessage = "Card examples must be under 150 characters."
            return
        }

        if draft.selectedIcon.isEmpty || draft.selectedIcon == "rectangle.stack.fill" {
            draft.selectedIcon = suggestedIcon(for: title)
        }

        isSaving = true
        errorMessage = nil

        do {
            let setID = UUID().uuidString
            var savedCards: [Flashcard] = []

            for card in validCards {
                let word = card.word.trimmingCharacters(in: .whitespacesAndNewlines)
                let translation = card.translation.trimmingCharacters(in: .whitespacesAndNewlines)
                let example = card.example.trimmingCharacters(in: .whitespacesAndNewlines)

                var localImageFileName: String? = nil

                if let selectedImage = card.selectedImage {
                    let fileName = "\(user.uid)_\(setID)_\(card.id.uuidString).jpg"

                    localImageFileName = try imageStorageService.saveImage(
                        selectedImage,
                        fileName: fileName
                    )
                }

                savedCards.append(
                    Flashcard(
                        id: card.id.uuidString,
                        word: word,
                        translation: translation,
                        example: example,
                        imageURL: localImageFileName
                    )
                )
            }

            let set = FlashcardSet(
                id: setID,
                ownerUID: user.uid,
                ownerEmail: user.email ?? "",
                title: title,
                description: description,
                privacy: draft.privacy.rawValue,
                folderName: draft.folderName,
                colorHex: draft.selectedColor.hex,
                icon: .systemName(draft.selectedIcon),
                cards: savedCards,
                createdAt: Date(),
                updatedAt: Date()
            )

            try await setService.createSet(set)

            isSaving = false
            didCreateSet = true
        } catch {
            isSaving = false
            errorMessage = error.localizedDescription
        }
    }

    private func suggestedIcon(for title: String) -> String {
        let text = title.lowercased()

        if text.contains("spanish") || text.contains("español") || text.contains("language") {
            return "globe.europe.africa.fill"
        }

        if text.contains("english") || text.contains("англій") {
            return "character.bubble.fill"
        }

        if text.contains("book") || text.contains("reading") || text.contains("study") {
            return "book.fill"
        }

        if text.contains("music") || text.contains("audio") || text.contains("listening") {
            return "headphones"
        }

        if text.contains("food") {
            return "fork.knife"
        }

        if text.contains("travel") {
            return "airplane"
        }

        if text.contains("health") {
            return "heart.fill"
        }

        if text.contains("work") {
            return "briefcase.fill"
        }

        return "star.fill"
    }
}
