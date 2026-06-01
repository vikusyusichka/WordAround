import Foundation

enum ListeningQuestionType: String, CaseIterable, Identifiable {
    case mainIdea = "Main idea"
    case details = "Details"
    case vocabulary = "Vocabulary"
    case trueFalse = "True / False"

    var id: String { rawValue }
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

enum ListeningVideoLength: String, CaseIterable, Identifiable {
    case short = "Short"
    case medium = "Medium"
    case long = "Long"

    var id: String { rawValue }

    var helperText: String {
        switch self {
        case .short: return "Short: 1–5 min"
        case .medium: return "Medium: 5–12 min"
        case .long: return "Long: 12–20 min"
        }
    }
}
