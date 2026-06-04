import SwiftUI

struct LanguageSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var prefs = UserPreferencesStore.shared

    var body: some View {
        ZStack {
            AppColors.appBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    ProfileSubScreenHeader(
                        title: L10n.localized(.languageTitle),
                        subtitle: L10n.localized(.languageSubtitle),
                        onBack: { dismiss() }
                    )

                    VStack(spacing: 10) {
                        ForEach(AppLanguage.allCases) { language in
                            languageRow(language)
                        }
                    }

                    restartNote
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
        .animation(.spring(response: 0.32, dampingFraction: 0.86), value: prefs.language)
    }

    private func languageRow(_ language: AppLanguage) -> some View {
        Button {
            prefs.language = language
            NotificationCenter.default.post(
                name: .appLanguageDidChange,
                object: nil,
                userInfo: ["language": language.rawValue]
            )
        } label: {
            HStack(spacing: 14) {
                Text(language.nativeFlag)
                    .font(.system(size: 28))
                    .frame(width: 44, height: 44)
                    .background(AppColors.primaryBlue.opacity(0.10))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(language.displayName)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.primaryBlueDark)

                    Text(language.rawValue.uppercased())
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .tracking(0.6)
                        .foregroundStyle(AppColors.textSecondary)
                }

                Spacer(minLength: 0)

                if prefs.language == language {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(AppColors.primaryBlue)
                } else {
                    Circle()
                        .stroke(AppColors.primaryBlue.opacity(0.18), lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .profileDashboardCard()
        }
        .buttonStyle(.plain)
    }

    private var restartNote: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(AppColors.primaryBlue.opacity(0.7))
                .padding(.top, 1)

            Text(L10n.localized(.languageRestartNote))
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppColors.primaryBlue.opacity(0.06))
        )
        .padding(.top, 6)
    }
}

extension Notification.Name {
    static let appLanguageDidChange = Notification.Name("WordAround.appLanguageDidChange")
}

#Preview {
    NavigationStack {
        LanguageSelectionView()
    }
}
