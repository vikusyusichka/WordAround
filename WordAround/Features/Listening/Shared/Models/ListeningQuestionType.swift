import Foundation

enum ListeningQuestionType: String, CaseIterable, Identifiable, Codable {
    case mainIdea = "Main idea"
    case details = "Details"
    case vocabulary = "Vocabulary"
    case trueFalse = "True / False"

    var id: String { rawValue }
}

enum ListeningPlaybackState: Equatable {
    case idle
    case playing
    case paused
    case finished

    var isActive: Bool { self == .playing }
}

enum ListeningVoiceSpeed: String, CaseIterable, Identifiable {
    case slow = "0.75x"
    case normal = "1.0x"
    case fast = "1.25x"

    var id: String { rawValue }
}

enum ListeningVoiceType: String, CaseIterable, Identifiable {
    case `default` = "Default"
    case female = "Female"
    case male = "Male"

    var id: String { rawValue }
}

