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

    private static let missingSentinel = "__L10N_MISSING__"

    // MARK: - Current language

    private nonisolated(unsafe) static var _currentLanguage: AppLanguage = .default
    private static let currentLanguageLock = NSLock()

    nonisolated static var currentLanguage: AppLanguage {
        get {
            currentLanguageLock.lock()
            defer { currentLanguageLock.unlock() }
            return _currentLanguage
        }
        set {
            currentLanguageLock.lock()
            _currentLanguage = newValue
            currentLanguageLock.unlock()
        }
    }

    // MARK: - Bundle resolution

    private nonisolated(unsafe) static var bundleCache: [String: Bundle] = [:]
    private static let bundleCacheLock = NSLock()

    private static func bundle(for code: String) -> Bundle? {
        bundleCacheLock.lock()
        defer { bundleCacheLock.unlock() }

        if let cached = bundleCache[code] {
            return cached
        }
        guard
            let path = Bundle.main.path(forResource: code, ofType: "lproj"),
            let bundle = Bundle(path: path)
        else {
            return nil
        }
        bundleCache[code] = bundle
        return bundle
    }

    // MARK: - Lookup

    nonisolated static func string(_ key: Key) -> String {
        string(key.rawValue, language: currentLanguage)
    }

    nonisolated static func localized(_ key: Key) -> String { string(key) }

    nonisolated static func string(_ rawKey: String) -> String {
        string(rawKey, language: currentLanguage)
    }

    static func string(_ key: Key, language: AppLanguage) -> String {
        string(key.rawValue, language: language)
    }

    static func string(_ rawKey: String, language: AppLanguage) -> String {
        if let value = lookup(rawKey, in: language.rawValue) { return value }
        if language != .english, let value = lookup(rawKey, in: AppLanguage.english.rawValue) {
            return value
        }
        return rawKey
    }

    private static func lookup(_ key: String, in languageCode: String) -> String? {
        guard let bundle = bundle(for: languageCode) else { return nil }
        let value = bundle.localizedString(forKey: key, value: missingSentinel, table: nil)
        return value == missingSentinel ? nil : value
    }

    // MARK: - Plural helpers

    nonisolated static func cardsCount(_ count: Int) -> String {
        let key: String
        let mod10 = count % 10
        let mod100 = count % 100
        if mod10 == 1 && mod100 != 11 {
            key = "cardsCountOneFmt"
        } else if (2...4).contains(mod10) && !(12...14).contains(mod100) {
            key = "cardsCountFewFmt"
        } else {
            key = "cardsCountManyFmt"
        }
        return String(format: string(key), count)
    }
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
