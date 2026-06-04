import SwiftUI

struct AppearanceView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var prefs = UserPreferencesStore.shared

    var body: some View {
        ZStack {
            AppColors.appBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    ProfileSubScreenHeader(
                        title: L10n.localized(.appearanceTitle),
                        subtitle: L10n.localized(.appearanceSubtitle),
                        onBack: { dismiss() }
                    )

                    VStack(spacing: 10) {
                        ForEach(AppearanceTheme.allCases) { theme in
                            themeRow(theme)
                        }
                    }
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
        .animation(.spring(response: 0.32, dampingFraction: 0.86), value: prefs.theme)
    }

    private func themeRow(_ theme: AppearanceTheme) -> some View {
        Button {
            prefs.theme = theme
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(themeTint(theme).opacity(0.14))
                    Image(systemName: themeIcon(theme))
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(themeTint(theme))
                }
                .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 3) {
                    Text(themeName(theme))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.primaryBlueDark)

                    Text(themeHint(theme))
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppColors.textSecondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)

                if prefs.theme == theme {
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

    private func themeIcon(_ theme: AppearanceTheme) -> String {
        switch theme {
        case .system: return "circle.lefthalf.filled"
        case .light:  return "sun.max.fill"
        case .dark:   return "moon.fill"
        }
    }

    private func themeName(_ theme: AppearanceTheme) -> String {
        switch theme {
        case .system: return L10n.localized(.appearanceSystem)
        case .light:  return L10n.localized(.appearanceLight)
        case .dark:   return L10n.localized(.appearanceDark)
        }
    }

    private func themeHint(_ theme: AppearanceTheme) -> String {
        switch theme {
        case .system: return L10n.localized(.appearanceSystemHint)
        case .light:  return L10n.localized(.appearanceLightHint)
        case .dark:   return L10n.localized(.appearanceDarkHint)
        }
    }

    private func themeTint(_ theme: AppearanceTheme) -> Color {
        switch theme {
        case .system: return AppColors.primaryBlue
        case .light:  return Color(red: 0.95, green: 0.65, blue: 0.10)
        case .dark:   return Color(red: 0.40, green: 0.32, blue: 0.78)
        }
    }
}

#Preview {
    NavigationStack {
        AppearanceView()
    }
}
