import Foundation

enum GrammarLanguage: String, CaseIterable, Identifiable, Equatable {
    case english
    case spanish
    case french
    case german

    var id: String { rawValue }

    var title: String {
        switch self {
        case .english:
            return "English"
        case .spanish:
            return "Spanish"
        case .french:
            return "French"
        case .german:
            return "German"
        }
    }

    var shortTitle: String {
        switch self {
        case .english:
            return "EN"
        case .spanish:
            return "ES"
        case .french:
            return "FR"
        case .german:
            return "DE"
        }
    }

    var languageToolCode: String {
        switch self {
        case .english:
            return "en-US"
        case .spanish:
            return "es"
        case .french:
            return "fr"
        case .german:
            return "de-DE"
        }
    }
}
