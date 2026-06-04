import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @ObservedObject private var preferences = UserPreferencesStore.shared

    @State private var isEditing = false
    @State private var isConfirmingSignOut = false
    @State private var isConfirmingDeletionFirstStep = false
    @State private var isDeleteSheetPresented = false
    @State private var safariLink: SafariLink?

    @State private var pushLanguage = false
    @State private var pushAppearance = false
    @State private var pushNotifications = false

    private let privacyPolicyURL = URL(string: "https://wordaround.app/privacy")!
    private let termsOfUseURL = URL(string: "https://wordaround.app/terms")!

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 18) {
                profileCard
                statsGrid
                accountSection
                supportSection
                dangerSection
            }
            .padding(.top, 8)
            .padding(.bottom, Layout.homeScrollBottomPadding)
            .frame(maxWidth: Layout.profileContentMaxWidth)
            .frame(maxWidth: .infinity)
        }
        .task { await viewModel.loadProfile() }
        .sheet(isPresented: $isEditing) {
            EditProfileSheet(viewModel: viewModel) {
                isEditing = false
            }
        }
        .sheet(isPresented: $isDeleteSheetPresented) {
            DeleteAccountConfirmationSheet(
                viewModel: viewModel,
                onCancel: { isDeleteSheetPresented = false },
                onDeleted: { isDeleteSheetPresented = false }
            )
        }
        .sheet(item: $safariLink) { link in
            SafariSheet(url: link.url)
                .ignoresSafeArea()
        }
        .alert(
            L10n.localized(.signOutTitle),
            isPresented: $isConfirmingSignOut
        ) {
            Button(L10n.localized(.signOutConfirm), role: .destructive) {
                viewModel.signOut()
            }
            Button(L10n.localized(.commonCancel), role: .cancel) {}
        } message: {
            Text(L10n.localized(.signOutMessage))
        }
        .alert(
            L10n.localized(.deleteAccountTitle),
            isPresented: $isConfirmingDeletionFirstStep
        ) {
            Button(L10n.localized(.deleteAccountContinue), role: .destructive) {
                isDeleteSheetPresented = true
            }
            Button(L10n.localized(.commonCancel), role: .cancel) {}
        } message: {
            Text(L10n.localized(.deleteAccountFirstMessage))
        }
        .navigationDestination(isPresented: $pushLanguage) {
            LanguageSelectionView()
        }
        .navigationDestination(isPresented: $pushAppearance) {
            AppearanceView()
        }
        .navigationDestination(isPresented: $pushNotifications) {
            NotificationsView()
        }
    }
}

// MARK: - Profile card

private extension ProfileView {
    var profileCard: some View {
        HStack(alignment: .center, spacing: 16) {
            avatar

            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.hasDisplayName
                     ? viewModel.displayName
                     : L10n.localized(.profileAddName))
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundColor(viewModel.hasDisplayName
                                     ? AppColors.primaryBlueDark
                                     : AppColors.textSecondary)
                    .lineLimit(1)

                Text(viewModel.email)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                editButton
                    .padding(.top, 8)
            }

            Spacer(minLength: 0)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .profileDashboardCard()
    }

    var avatar: some View {
        ZStack {
            Circle().fill(preferences.avatarColor.fillColor)

            if let url = viewModel.photoURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        initialsLabel
                    }
                }
                .clipShape(Circle())
            } else {
                initialsLabel
            }
        }
        .frame(width: 72, height: 72)
        .overlay(
            Circle().stroke(Color.white.opacity(0.7), lineWidth: 3)
        )
    }

    var initialsLabel: some View {
        Group {
            if viewModel.initials.isEmpty {
                Image(systemName: "person.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(preferences.avatarColor.accentColor)
            } else {
                Text(viewModel.initials)
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundColor(preferences.avatarColor.accentColor)
            }
        }
    }

    var editButton: some View {
        Button {
            viewModel.beginEditing()
            isEditing = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "pencil")
                    .font(.system(size: 11, weight: .bold))
                Text(L10n.localized(.profileEditButton))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(AppColors.primaryBlue)
            .clipShape(Capsule())
            .shadow(color: AppColors.primaryBlue.opacity(0.20), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Stats grid

private extension ProfileView {
    var statsGrid: some View {
        HStack(spacing: 12) {
            statCard(
                icon: "clock.fill",
                value: "\(viewModel.totalPracticeMinutes) \(L10n.localized(.profileMinutesShort))",
                label: L10n.localized(.profileStatPracticeTime)
            )
            statCard(
                icon: "calendar",
                value: viewModel.joinedDate.map { Self.shortMonthFormatter.string(from: $0) } ?? "—",
                label: L10n.localized(.profileStatMemberSince)
            )
        }
    }

    func statCard(icon: String, value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                Circle().fill(AppColors.primaryBlue.opacity(0.14))
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppColors.primaryBlue)
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundColor(AppColors.primaryBlueDark)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(label)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(1)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .profileDashboardCard()
    }
}

// MARK: - Settings sections

private extension ProfileView {
    var accountSection: some View {
        section(title: L10n.localized(.profileSectionAccount)) {
            VStack(spacing: 0) {
                settingsRow(
                    icon: "globe",
                    title: L10n.localized(.profileRowLanguage),
                    trailing: preferences.language.displayName,
                    showsDivider: true,
                    action: { pushLanguage = true }
                )
                settingsRow(
                    icon: "paintbrush.fill",
                    title: L10n.localized(.profileRowAppearance),
                    trailing: appearanceLabel,
                    showsDivider: true,
                    action: { pushAppearance = true }
                )
                settingsRow(
                    icon: "bell.fill",
                    title: L10n.localized(.profileRowNotifications),
                    trailing: notificationsLabel,
                    showsDivider: false,
                    action: { pushNotifications = true }
                )
            }
            .frame(maxWidth: .infinity)
            .profileDashboardCard()
        }
    }

    var appearanceLabel: String {
        switch preferences.theme {
        case .system: return L10n.localized(.appearanceSystem)
        case .light:  return L10n.localized(.appearanceLight)
        case .dark:   return L10n.localized(.appearanceDark)
        }
    }

    var notificationsLabel: String? {
        let count = [
            preferences.dailyReminderEnabled,
            preferences.weeklySummaryEnabled,
            preferences.streakAlertsEnabled
        ].filter { $0 }.count
        return count == 0 ? nil : "\(count)"
    }

    var supportSection: some View {
        section(title: L10n.localized(.profileSectionSupport)) {
            VStack(spacing: 0) {
                settingsRow(
                    icon: "hand.raised.fill",
                    title: L10n.localized(.profileRowPrivacy),
                    trailing: nil,
                    showsDivider: true,
                    action: { safariLink = SafariLink(url: privacyPolicyURL) }
                )
                settingsRow(
                    icon: "doc.text.fill",
                    title: L10n.localized(.profileRowTerms),
                    trailing: nil,
                    showsDivider: false,
                    action: { safariLink = SafariLink(url: termsOfUseURL) }
                )
            }
            .frame(maxWidth: .infinity)
            .profileDashboardCard()
        }
    }

    @ViewBuilder
    func section<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle(title, color: AppColors.textSecondary)
            content()
        }
    }

    func sectionTitle(_ text: String, color: Color) -> some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .black, design: .rounded))
            .tracking(0.8)
            .foregroundColor(color)
            .padding(.leading, 6)
    }

    func settingsRow(
        icon: String,
        title: String,
        trailing: String?,
        showsDivider: Bool,
        action: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 0) {
            Button(action: action) {
                HStack(spacing: 14) {
                    iconBox(
                        systemName: icon,
                        tint: AppColors.primaryBlue.opacity(0.14),
                        foreground: AppColors.primaryBlue
                    )

                    Text(title)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.primaryBlueDark)

                    Spacer()

                    if let trailing {
                        Text(trailing)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(AppColors.textSecondary)
                            .lineLimit(1)
                    }

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AppColors.textSecondary.opacity(0.6))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if showsDivider {
                Rectangle()
                    .fill(AppColors.primaryBlue.opacity(0.06))
                    .frame(height: 0.5)
                    .padding(.leading, 16 + 36 + 14)
            }
        }
    }
}

// MARK: - Danger zone

private extension ProfileView {
    var dangerSection: some View {
        section(title: L10n.localized(.profileSectionDanger)) {
            VStack(spacing: 0) {
                dangerRow(
                    icon: "rectangle.portrait.and.arrow.right",
                    title: L10n.localized(.profileRowSignOut),
                    showsDivider: true,
                    action: { isConfirmingSignOut = true }
                )
                dangerRow(
                    icon: "trash.fill",
                    title: L10n.localized(.profileRowDeleteAccount),
                    showsDivider: false,
                    action: { isConfirmingDeletionFirstStep = true }
                )
            }
            .frame(maxWidth: .infinity)
            .profileDashboardCard(
                accent: Color(red: 0.85, green: 0.30, blue: 0.30),
                blobOpacity: 0.07
            )
        }
    }

    func dangerRow(
        icon: String,
        title: String,
        showsDivider: Bool,
        action: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 0) {
            Button(action: action) {
                HStack(spacing: 14) {
                    iconBox(
                        systemName: icon,
                        tint: Color(red: 1.00, green: 0.92, blue: 0.91),
                        foreground: Color(red: 0.85, green: 0.30, blue: 0.30)
                    )

                    Text(title)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.85, green: 0.30, blue: 0.30))

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(red: 0.85, green: 0.30, blue: 0.30).opacity(0.45))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if showsDivider {
                Rectangle()
                    .fill(Color(red: 0.85, green: 0.30, blue: 0.30).opacity(0.10))
                    .frame(height: 0.5)
                    .padding(.leading, 16 + 36 + 14)
            }
        }
    }
}

// MARK: - Shared chrome

private extension ProfileView {
    func iconBox(systemName: String, tint: Color, foreground: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(tint)
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(foreground)
        }
        .frame(width: 36, height: 36)
    }

    static let shortMonthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM yyyy"
        return f
    }()
}

#Preview {
    NavigationStack {
        ZStack {
            AppColors.appBackground.ignoresSafeArea()
            ProfileView()
                .padding(.horizontal, 16)
        }
    }
}
