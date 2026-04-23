import Foundation

enum HomeTab: String, CaseIterable, Identifiable {
    case home
    case flashcards
    case create
    case profile

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .home: return "house"
        case .flashcards: return "square.stack.3d.up"
        case .create: return "square.and.pencil"
        case .profile: return "person"
        }
    }
}
