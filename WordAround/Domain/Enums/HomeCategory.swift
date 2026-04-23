import Foundation

enum HomeCategory: String, CaseIterable, Identifiable {
    case speaking
    case listening
    case reading
    case writing

    var id: String { rawValue }

    var title: String {
        switch self {
        case .speaking: return "SPEAKING"
        case .listening: return "LISTENING"
        case .reading: return "READING"
        case .writing: return "WRITING"
        }
    }

    var icon: String {
        switch self {
        case .speaking: return "bubble.left.and.bubble.right"
        case .listening: return "headphones"
        case .reading: return "book"
        case .writing: return "pencil.and.scribble"
        }
    }
}
