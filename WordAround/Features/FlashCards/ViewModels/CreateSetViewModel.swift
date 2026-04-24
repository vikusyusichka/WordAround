import SwiftUI
import Combine

final class CreateSetViewModel: ObservableObject {
    @Published var draft = CreateFlashcardSetDraft()

    let availableColors: [Color] = [
        AppColors.createSetRed,
        AppColors.createSetBlue,
        AppColors.createSetYellow,
        AppColors.createSetGreen,
        AppColors.createSetPurple,
        AppColors.createSetCyan
    ]

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

    func selectColor(_ color: Color) {
        draft.selectedColor = color
    }

    func selectIcon(_ icon: String) {
        draft.selectedIcon = icon
    }

    func createSet() {
        print("Create set:", draft)
    }
}
