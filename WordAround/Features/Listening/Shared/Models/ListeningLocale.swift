import Foundation
import AVFoundation

extension GrammarLanguage {
    var listeningLocaleIdentifier: String {
        switch self {
        case .english:    return "en-US"
        case .spanish:    return "es-ES"
        case .french:     return "fr-FR"
        case .german:     return "de-DE"
        case .italian:    return "it-IT"
        case .portuguese: return "pt-PT"
        case .dutch:      return "nl-NL"
        case .catalan:    return "ca-ES"
        case .galician:   return "es-ES"
        case .esperanto:  return "en-US"
        case .polish:     return "pl-PL"
        case .ukrainian:  return "uk-UA"
        case .russian:    return "ru-RU"
        case .czech:      return "cs-CZ"
        case .slovak:     return "sk-SK"
        case .croatian:   return "hr-HR"
        case .serbian:    return "sr-RS"
        case .slovenian:  return "sl-SI"
        case .bulgarian:  return "bg-BG"
        case .romanian:   return "ro-RO"
        case .hungarian:  return "hu-HU"
        case .greek:      return "el-GR"
        case .turkish:    return "tr-TR"
        case .swedish:    return "sv-SE"
        case .danish:     return "da-DK"
        case .norwegian:  return "nb-NO"
        case .finnish:    return "fi-FI"
        case .lithuanian: return "lt-LT"
        case .latvian:    return "lv-LV"
        case .estonian:   return "et-EE"
        }
    }
}

extension ListeningVoiceSpeed {
    var utteranceRate: Float {
        let base = AVSpeechUtteranceDefaultSpeechRate
        switch self {
        case .slow:   return base * 0.85
        case .normal: return base
        case .fast:   return base * 1.2
        }
    }

    var playbackRate: Float {
        switch self {
        case .slow:   return 0.75
        case .normal: return 1.0
        case .fast:   return 1.25
        }
    }
}
