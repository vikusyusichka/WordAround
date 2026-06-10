import Foundation

enum GrammarNoteFilter: String, CaseIterable, Identifiable {
    case all
    case types
    case favorites
    case tags

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:       return L10n.string("notesFilterAll")
        case .types:     return L10n.string("notesFilterTypes")
        case .favorites: return L10n.string("notesFilterFavorites")
        case .tags:      return L10n.string("editorTagsTitle")
        }
    }

    var emptyStateTitle: String {
        switch self {
        case .all:       return L10n.string("notesNoNotesYet")
        case .types:     return L10n.string("notesEmptyTypes")
        case .favorites: return L10n.string("notesEmptyFavorites")
        case .tags:      return L10n.string("notesEmptyTags")
        }
    }

    var emptyStateSubtitle: String {
        switch self {
        case .all:
            return L10n.string("notesNoNotesHint")
        case .types:
            return L10n.string("notesEmptyTypesHint")
        case .favorites:
            return L10n.string("notesEmptyFavoritesHint")
        case .tags:
            return L10n.string("notesEmptyTagsHint")
        }
    }
}
