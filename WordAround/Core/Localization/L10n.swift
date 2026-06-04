import Foundation
import SwiftUI

enum L10n {
    enum Key: String {
        case profileTitle
        case profileAddName
        case profileEditButton
        case profileStatPracticeTime
        case profileStatMemberSince
        case profileStatMinutes
        case profileMinutesShort
        case profileSectionAccount
        case profileSectionSupport
        case profileSectionDanger
        case profileRowLanguage
        case profileRowAppearance
        case profileRowNotifications
        case profileRowPrivacy
        case profileRowTerms
        case profileRowSignOut
        case profileRowDeleteAccount

        case editProfileTitle
        case editProfileNameLabel
        case editProfileNamePlaceholder
        case editProfileAvatarColorLabel
        case editProfileChangePhoto
        case editProfileChooseAnother

        case commonCancel
        case commonSave
        case commonDone
        case commonRetry
        case commonOK
        case commonDelete

        case languageTitle
        case languageSubtitle
        case languageRestartNote

        case appearanceTitle
        case appearanceSubtitle
        case appearanceSystem
        case appearanceLight
        case appearanceDark
        case appearanceSystemHint
        case appearanceLightHint
        case appearanceDarkHint

        case notificationsTitle
        case notificationsSubtitle
        case notificationsDailyReminder
        case notificationsDailyReminderHint
        case notificationsReminderTime
        case notificationsWeeklySummary
        case notificationsWeeklySummaryHint
        case notificationsStreakAlerts
        case notificationsStreakAlertsHint
        case notificationsPermissionDenied
        case notificationsOpenSettings
        case notificationsDailyBodyText
        case notificationsDailyTitleText
        case notificationsWeeklyTitleText
        case notificationsWeeklyBodyText
        case notificationsStreakTitleText
        case notificationsStreakBodyText

        case signOutTitle
        case signOutMessage
        case signOutConfirm

        case deleteAccountTitle
        case deleteAccountFirstMessage
        case deleteAccountSecondMessage
        case deleteAccountConfirmField
        case deleteAccountConfirmFieldPlaceholder
        case deleteAccountConfirmButton
        case deleteAccountContinue
        case deleteAccountReauthNeeded
        case deleteAccountReauthSignInAgain
        case deleteAccountSuccess
    }

    @MainActor
    static func string(_ key: Key) -> String {
        let language = UserPreferencesStore.shared.language
        return string(key, language: language)
    }

    static func string(_ key: Key, language: AppLanguage) -> String {
        let table = Self.table(for: language)
        if let value = table[key] { return value }
        if language != .english, let fallback = Self.table(for: .english)[key] {
            return fallback
        }
        return key.rawValue
    }

    static func table(for language: AppLanguage) -> [Key: String] {
        switch language {
        case .english:    return english
        case .ukrainian:  return ukrainian
        case .spanish:    return spanish
        case .chinese:    return chinese
        case .hindi:      return hindi
        case .french:     return french
        case .arabic:     return arabic
        case .bengali:    return bengali
        case .portuguese: return portuguese
        case .russian:    return russian
        case .urdu:       return urdu
        case .indonesian: return indonesian
        case .german:     return german
        case .japanese:   return japanese
        case .turkish:    return turkish
        case .vietnamese: return vietnamese
        case .korean:     return korean
        case .italian:    return italian
        case .persian:    return persian
        case .polish:     return polish
        case .dutch:      return dutch
        case .romanian:   return romanian
        case .thai:       return thai
        case .greek:      return greek
        case .czech:      return czech
        case .hungarian:  return hungarian
        case .swedish:    return swedish
        case .hebrew:     return hebrew
        case .norwegian:  return norwegian
        case .danish:     return danish
        case .finnish:    return finnish
        case .bulgarian:  return bulgarian
        }
    }
}

extension L10n {
    @MainActor
    static func localized(_ key: Key) -> String { string(key) }
}

// MARK: - Language

enum AppLanguage: String, CaseIterable, Identifiable, Codable {
    case english    = "en"
    case chinese    = "zh"
    case hindi      = "hi"
    case spanish    = "es"
    case french     = "fr"
    case arabic     = "ar"
    case bengali    = "bn"
    case portuguese = "pt"
    case russian    = "ru"
    case urdu       = "ur"
    case indonesian = "id"
    case german     = "de"
    case japanese   = "ja"
    case turkish    = "tr"
    case vietnamese = "vi"
    case korean     = "ko"
    case italian    = "it"
    case persian    = "fa"
    case polish     = "pl"
    case ukrainian  = "uk"
    case dutch      = "nl"
    case romanian   = "ro"
    case thai       = "th"
    case greek      = "el"
    case czech      = "cs"
    case hungarian  = "hu"
    case swedish    = "sv"
    case hebrew     = "he"
    case norwegian  = "no"
    case danish     = "da"
    case finnish    = "fi"
    case bulgarian  = "bg"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english:    return "English"
        case .chinese:    return "中文"
        case .hindi:      return "हिन्दी"
        case .spanish:    return "Español"
        case .french:     return "Français"
        case .arabic:     return "العربية"
        case .bengali:    return "বাংলা"
        case .portuguese: return "Português"
        case .russian:    return "Русский"
        case .urdu:       return "اردو"
        case .indonesian: return "Bahasa Indonesia"
        case .german:     return "Deutsch"
        case .japanese:   return "日本語"
        case .turkish:    return "Türkçe"
        case .vietnamese: return "Tiếng Việt"
        case .korean:     return "한국어"
        case .italian:    return "Italiano"
        case .persian:    return "فارسی"
        case .polish:     return "Polski"
        case .ukrainian:  return "Українська"
        case .dutch:      return "Nederlands"
        case .romanian:   return "Română"
        case .thai:       return "ไทย"
        case .greek:      return "Ελληνικά"
        case .czech:      return "Čeština"
        case .hungarian:  return "Magyar"
        case .swedish:    return "Svenska"
        case .hebrew:     return "עברית"
        case .norwegian:  return "Norsk"
        case .danish:     return "Dansk"
        case .finnish:    return "Suomi"
        case .bulgarian:  return "Български"
        }
    }

    var nativeFlag: String {
        switch self {
        case .english:    return "🇬🇧"
        case .chinese:    return "🇨🇳"
        case .hindi:      return "🇮🇳"
        case .spanish:    return "🇪🇸"
        case .french:     return "🇫🇷"
        case .arabic:     return "🇸🇦"
        case .bengali:    return "🇧🇩"
        case .portuguese: return "🇧🇷"
        case .russian:    return "🇷🇺"
        case .urdu:       return "🇵🇰"
        case .indonesian: return "🇮🇩"
        case .german:     return "🇩🇪"
        case .japanese:   return "🇯🇵"
        case .turkish:    return "🇹🇷"
        case .vietnamese: return "🇻🇳"
        case .korean:     return "🇰🇷"
        case .italian:    return "🇮🇹"
        case .persian:    return "🇮🇷"
        case .polish:     return "🇵🇱"
        case .ukrainian:  return "🇺🇦"
        case .dutch:      return "🇳🇱"
        case .romanian:   return "🇷🇴"
        case .thai:       return "🇹🇭"
        case .greek:      return "🇬🇷"
        case .czech:      return "🇨🇿"
        case .hungarian:  return "🇭🇺"
        case .swedish:    return "🇸🇪"
        case .hebrew:     return "🇮🇱"
        case .norwegian:  return "🇳🇴"
        case .danish:     return "🇩🇰"
        case .finnish:    return "🇫🇮"
        case .bulgarian:  return "🇧🇬"
        }
    }

    static let `default`: AppLanguage = .english
}
