import SwiftUI
import Combine

enum AppearanceTheme: String, CaseIterable, Identifiable, Codable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}

struct ReminderTime: Codable, Equatable {
    var hour: Int
    var minute: Int

    static let defaultMorning = ReminderTime(hour: 9, minute: 0)

    var dateComponents: DateComponents {
        var c = DateComponents()
        c.hour = hour
        c.minute = minute
        return c
    }

    var asDate: Date {
        let calendar = Calendar.current
        return calendar.date(from: dateComponents) ?? Date()
    }

    init(hour: Int, minute: Int) {
        self.hour = hour
        self.minute = minute
    }

    init(date: Date) {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
        self.hour = comps.hour ?? 9
        self.minute = comps.minute ?? 0
    }
}

@MainActor
final class UserPreferencesStore: ObservableObject {
    static let shared = UserPreferencesStore()

    // MARK: - Keys

    private enum Keys {
        static let theme = "preferences.appearanceTheme"
        static let language = "preferences.language"
        static let avatarColor = "preferences.avatarColor"
        static let dailyReminderEnabled = "preferences.notifications.dailyReminderEnabled"
        static let dailyReminderHour = "preferences.notifications.dailyReminderHour"
        static let dailyReminderMinute = "preferences.notifications.dailyReminderMinute"
        static let weeklySummaryEnabled = "preferences.notifications.weeklySummaryEnabled"
        static let streakAlertsEnabled = "preferences.notifications.streakAlertsEnabled"
    }

    // MARK: - Published

    @Published var theme: AppearanceTheme {
        didSet { defaults.set(theme.rawValue, forKey: Keys.theme) }
    }

    @Published var language: AppLanguage {
        didSet {
            defaults.set(language.rawValue, forKey: Keys.language)
            L10n.currentLanguage = language
        }
    }

    @Published var avatarColor: ProfileAvatarColor {
        didSet { defaults.set(avatarColor.rawValue, forKey: Keys.avatarColor) }
    }

    @Published var dailyReminderEnabled: Bool {
        didSet { defaults.set(dailyReminderEnabled, forKey: Keys.dailyReminderEnabled) }
    }

    @Published var dailyReminderTime: ReminderTime {
        didSet {
            defaults.set(dailyReminderTime.hour, forKey: Keys.dailyReminderHour)
            defaults.set(dailyReminderTime.minute, forKey: Keys.dailyReminderMinute)
        }
    }

    @Published var weeklySummaryEnabled: Bool {
        didSet { defaults.set(weeklySummaryEnabled, forKey: Keys.weeklySummaryEnabled) }
    }

    @Published var streakAlertsEnabled: Bool {
        didSet { defaults.set(streakAlertsEnabled, forKey: Keys.streakAlertsEnabled) }
    }

    // MARK: - Init

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        self.theme = AppearanceTheme(rawValue: defaults.string(forKey: Keys.theme) ?? "")
            ?? .system

        self.language = AppLanguage(rawValue: defaults.string(forKey: Keys.language) ?? "")
            ?? .default

        self.avatarColor = ProfileAvatarColor(rawValue: defaults.string(forKey: Keys.avatarColor) ?? "")
            ?? .default

        self.dailyReminderEnabled = defaults.object(forKey: Keys.dailyReminderEnabled) as? Bool ?? false

        let hour = defaults.object(forKey: Keys.dailyReminderHour) as? Int ?? ReminderTime.defaultMorning.hour
        let minute = defaults.object(forKey: Keys.dailyReminderMinute) as? Int ?? ReminderTime.defaultMorning.minute
        self.dailyReminderTime = ReminderTime(hour: hour, minute: minute)

        self.weeklySummaryEnabled = defaults.object(forKey: Keys.weeklySummaryEnabled) as? Bool ?? false
        self.streakAlertsEnabled = defaults.object(forKey: Keys.streakAlertsEnabled) as? Bool ?? false

        L10n.currentLanguage = self.language
    }

    // MARK: - Reset

    func resetToDefaults() {
        theme = .system
        language = .default
        avatarColor = .default
        dailyReminderEnabled = false
        dailyReminderTime = .defaultMorning
        weeklySummaryEnabled = false
        streakAlertsEnabled = false
    }
}
