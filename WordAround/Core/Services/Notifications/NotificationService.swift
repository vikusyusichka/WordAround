import Foundation
import UserNotifications
import UIKit

@MainActor
final class NotificationService {
    static let shared = NotificationService()

    private enum Identifier {
        static let dailyReminder = "wordaround.daily.reminder"
        static let weeklySummary = "wordaround.weekly.summary"
        static let streakAlert   = "wordaround.streak.alert"
    }

    private let center = UNUserNotificationCenter.current()

    // MARK: - Permission

    @discardableResult
    func requestAuthorization() async -> UNAuthorizationStatus {
        do {
            _ = try await center.requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
        }
        return await currentAuthorizationStatus()
    }

    func currentAuthorizationStatus() async -> UNAuthorizationStatus {
        await withCheckedContinuation { continuation in
            center.getNotificationSettings { settings in
                continuation.resume(returning: settings.authorizationStatus)
            }
        }
    }

    // MARK: - Sync from preferences

    func sync(with prefs: UserPreferencesStore) async {
        let status = await currentAuthorizationStatus()
        guard status == .authorized || status == .provisional else {
            await removeAll()
            return
        }

        if prefs.dailyReminderEnabled {
            scheduleDailyReminder(at: prefs.dailyReminderTime)
        } else {
            removeRequest(id: Identifier.dailyReminder)
        }

        if prefs.weeklySummaryEnabled {
            scheduleWeeklySummary()
        } else {
            removeRequest(id: Identifier.weeklySummary)
        }

        if prefs.streakAlertsEnabled {
            scheduleStreakAlert()
        } else {
            removeRequest(id: Identifier.streakAlert)
        }
    }

    // MARK: - Schedules

    private func scheduleDailyReminder(at time: ReminderTime) {
        let content = UNMutableNotificationContent()
        content.title = L10n.localized(.notificationsDailyTitleText)
        content.body = L10n.localized(.notificationsDailyBodyText)
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: time.dateComponents,
            repeats: true
        )

        replace(id: Identifier.dailyReminder, content: content, trigger: trigger)
    }

    private func scheduleWeeklySummary() {
        let content = UNMutableNotificationContent()
        content.title = L10n.localized(.notificationsWeeklyTitleText)
        content.body = L10n.localized(.notificationsWeeklyBodyText)
        content.sound = .default

        var components = DateComponents()
        components.weekday = 1
        components.hour = 19
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: true
        )

        replace(id: Identifier.weeklySummary, content: content, trigger: trigger)
    }

    private func scheduleStreakAlert() {
        let content = UNMutableNotificationContent()
        content.title = L10n.localized(.notificationsStreakTitleText)
        content.body = L10n.localized(.notificationsStreakBodyText)
        content.sound = .default

        var components = DateComponents()
        components.hour = 21
        components.minute = 30

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: true
        )

        replace(id: Identifier.streakAlert, content: content, trigger: trigger)
    }

    // MARK: - Helpers

    private func replace(
        id: String,
        content: UNNotificationContent,
        trigger: UNNotificationTrigger
    ) {
        center.removePendingNotificationRequests(withIdentifiers: [id])
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request) { _ in }
    }

    private func removeRequest(id: String) {
        center.removePendingNotificationRequests(withIdentifiers: [id])
    }

    func removeAll() async {
        center.removeAllPendingNotificationRequests()
    }

    // MARK: - System settings deep-link

    func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
