import SwiftUI
import UserNotifications

struct NotificationsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var prefs = UserPreferencesStore.shared

    @State private var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @State private var isRequestingAuthorization = false

    private let service = NotificationService.shared

    var body: some View {
        ZStack {
            AppColors.appBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    ProfileSubScreenHeader(
                        title: L10n.localized(.notificationsTitle),
                        subtitle: L10n.localized(.notificationsSubtitle),
                        onBack: { dismiss() }
                    )

                    if authorizationStatus == .denied {
                        permissionDeniedBanner
                    }

                    dailyReminderCard
                    toggleCard(
                        icon: "calendar.badge.clock",
                        title: L10n.localized(.notificationsWeeklySummary),
                        hint: L10n.localized(.notificationsWeeklySummaryHint),
                        isOn: $prefs.weeklySummaryEnabled
                    )
                    toggleCard(
                        icon: "flame.fill",
                        title: L10n.localized(.notificationsStreakAlerts),
                        hint: L10n.localized(.notificationsStreakAlertsHint),
                        isOn: $prefs.streakAlertsEnabled
                    )
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 32)
                .frame(maxWidth: Layout.profileContentMaxWidth)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .task {
            authorizationStatus = await service.currentAuthorizationStatus()
            await service.sync(with: prefs)
        }
        .onChange(of: prefs.dailyReminderEnabled) { _, _ in
            handleToggleChange()
        }
        .onChange(of: prefs.weeklySummaryEnabled) { _, _ in
            handleToggleChange()
        }
        .onChange(of: prefs.streakAlertsEnabled) { _, _ in
            handleToggleChange()
        }
        .onChange(of: prefs.dailyReminderTime) { _, _ in
            Task { await service.sync(with: prefs) }
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.86), value: prefs.dailyReminderEnabled)
    }

    // MARK: - Permission banner

    private var permissionDeniedBanner: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "bell.slash.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color(red: 0.85, green: 0.55, blue: 0.20))

                Text(L10n.localized(.notificationsPermissionDenied))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.primaryBlueDark)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button {
                service.openSystemSettings()
            } label: {
                Text(L10n.localized(.notificationsOpenSettings))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(AppColors.primaryBlue)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(red: 1.00, green: 0.95, blue: 0.85))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(red: 0.95, green: 0.78, blue: 0.40).opacity(0.40), lineWidth: 1)
        )
    }

    // MARK: - Daily reminder

    private var dailyReminderCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(AppColors.primaryBlue.opacity(0.14))
                    Image(systemName: "alarm.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(AppColors.primaryBlue)
                }
                .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 3) {
                    Text(L10n.localized(.notificationsDailyReminder))
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.primaryBlueDark)
                    Text(L10n.localized(.notificationsDailyReminderHint))
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppColors.textSecondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 8)

                Toggle("", isOn: $prefs.dailyReminderEnabled)
                    .labelsHidden()
                    .tint(AppColors.primaryBlue)
            }

            if prefs.dailyReminderEnabled {
                Divider()
                    .background(AppColors.primaryBlue.opacity(0.08))

                HStack(spacing: 10) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(AppColors.primaryBlue.opacity(0.75))

                    Text(L10n.localized(.notificationsReminderTime))
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppColors.primaryBlueDark)

                    Spacer(minLength: 8)

                    DatePicker(
                        "",
                        selection: Binding(
                            get: { prefs.dailyReminderTime.asDate },
                            set: { prefs.dailyReminderTime = ReminderTime(date: $0) }
                        ),
                        displayedComponents: .hourAndMinute
                    )
                    .labelsHidden()
                    .tint(AppColors.primaryBlue)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .profileDashboardCard()
    }

    // MARK: - Reusable toggle card

    private func toggleCard(
        icon: String,
        title: String,
        hint: String,
        isOn: Binding<Bool>
    ) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppColors.primaryBlue.opacity(0.14))
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppColors.primaryBlue)
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.primaryBlueDark)
                Text(hint)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(AppColors.primaryBlue)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .profileDashboardCard()
    }

    // MARK: - Auth handling

    private func handleToggleChange() {
        let anyEnabled = prefs.dailyReminderEnabled
            || prefs.weeklySummaryEnabled
            || prefs.streakAlertsEnabled

        guard anyEnabled else {
            Task { await service.sync(with: prefs) }
            return
        }

        Task {
            if authorizationStatus == .notDetermined {
                isRequestingAuthorization = true
                authorizationStatus = await service.requestAuthorization()
                isRequestingAuthorization = false
            } else {
                authorizationStatus = await service.currentAuthorizationStatus()
            }

            if authorizationStatus == .denied {
                prefs.dailyReminderEnabled = false
                prefs.weeklySummaryEnabled = false
                prefs.streakAlertsEnabled = false
            }

            await service.sync(with: prefs)
        }
    }
}

#Preview {
    NavigationStack {
        NotificationsView()
    }
}
