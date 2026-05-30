import Foundation

enum SpeakingConversationState: Equatable {
    case idle
    case listening
    case processing
    case speaking
    case error(String)

    var isBusy: Bool {
        switch self {
        case .processing, .speaking: return true
        default: return false
        }
    }

    var isListening: Bool {
        if case .listening = self { return true }
        return false
    }
}
