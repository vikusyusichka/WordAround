import Foundation

enum GrammarNoteFilter: String, CaseIterable, Identifiable {
    case all
    case types
    case favorites
    case tags

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:       return "All"
        case .types:     return "Types"
        case .favorites: return "Favourites"
        case .tags:      return "Tags"
        }
    }

    var emptyStateTitle: String {
        switch self {
        case .all:       return "No notes yet"
        case .types:     return "No notes for this type"
        case .favorites: return "No favourite notes yet"
        case .tags:      return "No notes with this tag"
        }
    }

    var emptyStateSubtitle: String {
        switch self {
        case .all:
            return "Create your first note for this topic."
        case .types:
            return "Pick another type or create a note of this type."
        case .favorites:
            return "Long-press a note and choose Add to Favourites."
        case .tags:
            return "Tag notes when you create or edit them to filter by tag."
        }
    }
}
