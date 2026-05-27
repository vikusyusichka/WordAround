import Foundation

enum GrammarNoteFilter: String, CaseIterable, Identifiable {
    case all
    case pinned
    case favorites
    case mistakes
    case quizzes

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:       return "All"
        case .pinned:    return "Pinned"
        case .favorites: return "Favorites"
        case .mistakes:  return "Mistakes"
        case .quizzes:   return "Quizzes"
        }
    }

    var emptyStateTitle: String {
        switch self {
        case .all:       return "No grammar notes yet"
        case .pinned:    return "No pinned notes yet"
        case .favorites: return "No favorite notes yet"
        case .mistakes:  return "No saved mistakes yet"
        case .quizzes:   return "No quiz notes yet"
        }
    }

    var emptyStateSubtitle: String {
        switch self {
        case .all:
            return "Create your first grammar note for this topic."
        case .pinned:
            return "Pin notes from the list to find them quickly."
        case .favorites:
            return "Favorite notes to keep them handy."
        case .mistakes:
            return "Save grammar mistakes to review them here."
        case .quizzes:
            return "Add a quiz to a note to see it here."
        }
    }
}
