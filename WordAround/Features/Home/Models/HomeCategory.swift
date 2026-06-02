import Foundation

enum HomeCategory: String, CaseIterable, Identifiable {
    case speaking
    case listening
    case reading
    case writing
    case notes

    var id: String { rawValue }

    var title: String {
        switch self {
        case .speaking: return "SPEAKING"
        case .listening: return "LISTENING"
        case .reading: return "READING"
        case .writing: return "WRITING"
        case .notes: return "NOTES"
        }
    }

    var icon: String {
        switch self {
        case .speaking: return "bubble.left.and.bubble.right"
        case .listening: return "headphones"
        case .reading: return "book"
        case .writing: return "pencil.and.scribble"
        case .notes: return "note.text"
        }
    }
}
