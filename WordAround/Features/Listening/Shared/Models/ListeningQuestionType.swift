import Foundation

enum ListeningQuestionType: String, CaseIterable, Identifiable, Codable {
    case mainIdea = "Main idea"
    case details = "Details"
    case vocabulary = "Vocabulary"
    case trueFalse = "True / False"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .mainIdea:   return L10n.string("listenMainIdea")
        case .details:    return L10n.string("listenDetails")
        case .vocabulary: return L10n.string("spkVocabulary")
        case .trueFalse:  return L10n.string("listenTrueFalseShort")
        }
    }
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

    var title: String {
        switch self {
        case .default: return L10n.string("listenVoiceDefault")
        case .female:  return L10n.string("listenVoiceFemale")
        case .male:    return L10n.string("listenVoiceMale")
        }
    }
}

