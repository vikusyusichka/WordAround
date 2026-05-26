import Foundation
import SwiftUI
import UIKit

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

enum SetColor: String, CaseIterable, Identifiable {
    case red
    case blue
    case yellow
    case green
    case purple
    case cyan

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .red:
            return AppColors.createSetRed
        case .blue:
            return AppColors.createSetBlue
        case .yellow:
            return AppColors.createSetYellow
        case .green:
            return AppColors.createSetGreen
        case .purple:
            return AppColors.createSetPurple
        case .cyan:
            return AppColors.createSetCyan
        }
    }

    var hex: String {
        switch self {
        case .red:
            return "#FF5759"
        case .blue:
            return "#4169F5"
        case .yellow:
            return "#F5B942"
        case .green:
            return "#3CCF91"
        case .purple:
            return "#9B6BFF"
        case .cyan:
            return "#35C8E8"
        }
    }
}

struct CreateFlashcardDraft: Identifiable {
    let id = UUID()

    var word: String = ""
    var translation: String = ""
    var example: String = ""

    var selectedImage: UIImage? = nil
    var imageURL: String? = nil
}

struct CreateFlashcardSetDraft {
    var title: String = ""
    var description: String = ""
    var privacy: FlashcardSetPrivacy = .privateSet
    var cards: [CreateFlashcardDraft] = [CreateFlashcardDraft()]
    var folderID: String? = nil
    var folderName: String? = nil
    var selectedColor: SetColor = .red
    var selectedIcon: String = "rectangle.stack.fill"
}


