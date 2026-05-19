import Foundation

enum EssayTopicMode: String, CaseIterable, Identifiable, Equatable {
    case suggested = "Suggested"
    case custom = "My topic"

    var id: String { rawValue }
}
