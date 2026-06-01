import Foundation

enum GrammarLanguage: String, CaseIterable, Identifiable, Equatable, Codable {
    // Western European
    case english
    case spanish
    case french
    case german
    case italian
    case portuguese
    case dutch
    case catalan
    case galician
    case esperanto

    // Slavic
    case polish
    case ukrainian
    case russian
    case czech
    case slovak
    case croatian
    case serbian
    case slovenian
    case bulgarian

    // Other European
    case romanian
    case hungarian
    case greek
    case turkish

    // Nordic
    case swedish
    case danish
    case norwegian
    case finnish

    // Baltic
    case lithuanian
    case latvian
    case estonian

    var id: String { rawValue }

    var title: String {
        switch self {
        case .english:    return "English"
        case .spanish:    return "Spanish"
        case .french:     return "French"
        case .german:     return "German"
        case .italian:    return "Italian"
        case .portuguese: return "Portuguese"
        case .dutch:      return "Dutch"
        case .catalan:    return "Catalan"
        case .galician:   return "Galician"
        case .esperanto:  return "Esperanto"
        case .polish:     return "Polish"
        case .ukrainian:  return "Ukrainian"
        case .russian:    return "Russian"
        case .czech:      return "Czech"
        case .slovak:     return "Slovak"
        case .croatian:   return "Croatian"
        case .serbian:    return "Serbian"
        case .slovenian:  return "Slovenian"
        case .bulgarian:  return "Bulgarian"
        case .romanian:   return "Romanian"
        case .hungarian:  return "Hungarian"
        case .greek:      return "Greek"
        case .turkish:    return "Turkish"
        case .swedish:    return "Swedish"
        case .danish:     return "Danish"
        case .norwegian:  return "Norwegian"
        case .finnish:    return "Finnish"
        case .lithuanian: return "Lithuanian"
        case .latvian:    return "Latvian"
        case .estonian:   return "Estonian"
        }
    }

    var shortTitle: String {
        switch self {
        case .english:    return "EN"
        case .spanish:    return "ES"
        case .french:     return "FR"
        case .german:     return "DE"
        case .italian:    return "IT"
        case .portuguese: return "PT"
        case .dutch:      return "NL"
        case .catalan:    return "CA"
        case .galician:   return "GL"
        case .esperanto:  return "EO"
        case .polish:     return "PL"
        case .ukrainian:  return "UK"
        case .russian:    return "RU"
        case .czech:      return "CS"
        case .slovak:     return "SK"
        case .croatian:   return "HR"
        case .serbian:    return "SR"
        case .slovenian:  return "SL"
        case .bulgarian:  return "BG"
        case .romanian:   return "RO"
        case .hungarian:  return "HU"
        case .greek:      return "EL"
        case .turkish:    return "TR"
        case .swedish:    return "SV"
        case .danish:     return "DA"
        case .norwegian:  return "NO"
        case .finnish:    return "FI"
        case .lithuanian: return "LT"
        case .latvian:    return "LV"
        case .estonian:   return "ET"
        }
    }

    /// LanguageTool API language code. For languages LanguageTool does not
    /// support, falls back to the ISO 639-1 code so the value is still a
    /// meaningful identifier (used by AI prompts and logging); the actual
    /// grammar-check call is gated upstream by `supportsGrammarCheck`.
    var languageToolCode: String {
        switch self {
        // Supported directly by LanguageTool
        case .english:    return "en-US"
        case .spanish:    return "es"
        case .french:     return "fr"
        case .german:     return "de-DE"
        case .italian:    return "it"
        case .portuguese: return "pt-PT"
        case .dutch:      return "nl"
        case .catalan:    return "ca-ES"
        case .galician:   return "gl-ES"
        case .esperanto:  return "eo"
        case .polish:     return "pl-PL"
        case .ukrainian:  return "uk-UA"
        case .russian:    return "ru-RU"
        case .slovak:     return "sk-SK"
        case .romanian:   return "ro-RO"
        case .greek:      return "el-GR"
        case .swedish:    return "sv"
        case .danish:     return "da-DK"
        case .norwegian:  return "nb"
        // Not supported by LanguageTool — kept as ISO 639-1 so AI prompts
        // and translation services can still use a stable code.
        case .czech:      return "cs"
        case .croatian:   return "hr"
        case .serbian:    return "sr"
        case .slovenian:  return "sl"
        case .bulgarian:  return "bg"
        case .hungarian:  return "hu"
        case .turkish:    return "tr"
        case .finnish:    return "fi"
        case .lithuanian: return "lt"
        case .latvian:    return "lv"
        case .estonian:   return "et"
        }
    }

    /// `true` when LanguageTool can reliably grammar-check this language.
    /// When `false`, the UI shows "Grammar checking is currently unavailable
    /// for this language." instead of issuing a doomed request. AI
    /// generation, translation, and synonyms continue to work because they
    /// use different providers.
    var supportsGrammarCheck: Bool {
        switch self {
        case .czech, .croatian, .serbian, .slovenian, .bulgarian,
             .hungarian, .turkish, .finnish,
             .lithuanian, .latvian, .estonian:
            return false
        default:
            return true
        }
    }
}
