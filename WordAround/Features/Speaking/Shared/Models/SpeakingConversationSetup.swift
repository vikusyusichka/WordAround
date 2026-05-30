import Foundation

struct SpeakingConversationSetup: Identifiable, Equatable {
    let id: UUID
    let language: GrammarLanguage
    let level: EssayDifficulty

    let scenario: ConversationScenario?
    let length: ConversationLength

    init(
        id: UUID = UUID(),
        language: GrammarLanguage,
        level: EssayDifficulty,
        scenario: ConversationScenario?,
        length: ConversationLength
    ) {
        self.id = id
        self.language = language
        self.level = level
        self.scenario = scenario
        self.length = length
    }

    var speechLocaleIdentifier: String {
        switch language {
        case .english:    return "en-US"
        case .spanish:    return "es-ES"
        case .french:     return "fr-FR"
        case .german:     return "de-DE"
        case .italian:    return "it-IT"
        case .portuguese: return "pt-PT"
        case .dutch:      return "nl-NL"
        case .catalan:    return "ca-ES"
        case .galician:   return "en-US"
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
