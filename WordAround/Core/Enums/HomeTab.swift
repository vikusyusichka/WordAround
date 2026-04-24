import Foundation

enum HomeTab: String, CaseIterable, Identifiable {
    case home
    case folders
    case create
    case flashcards
    case profile

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .home: return "house"
        case .folders: return "folder"
        case .create: return "plus"
        case .flashcards: return "square.stack.3d.up"
        case .profile: return "person"
        }
    }
}
