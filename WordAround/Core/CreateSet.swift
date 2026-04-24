import Foundation
import SwiftUI

enum FlashcardSetPrivacy: String, CaseIterable, Identifiable {
    case privateSet = "Private"
    case publicSet = "Public"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .privateSet:
            return "lock.fill"
        case .publicSet:
            return "globe"
        }
    }
}

struct CreateFlashcardDraft: Identifiable {
    let id = UUID()

    var word: String = ""
    var translation: String = ""
    var example: String = ""
    var imageName: String? = nil
}

struct CreateFlashcardSetDraft {
    var title: String = ""
    var description: String = ""
    var privacy: FlashcardSetPrivacy = .privateSet
    var cards: [CreateFlashcardDraft] = [CreateFlashcardDraft()]
    var folderName: String? = nil
    var selectedColor: Color = Color(red: 1.00, green: 0.34, blue: 0.35)
    var selectedIcon: String = "rectangle.stack.fill"
}
