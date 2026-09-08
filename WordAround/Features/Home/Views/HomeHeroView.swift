import SwiftUI

/// A compact, personalized greeting that sits above Daily Practice and makes
/// Home feel like a personal hub rather than a menu. Purely typographic (no
/// heavy card) plus a small streak pill, matching the calm WordAround style.
struct HomeHeroView: View {
    let streak: HomeStreakState
    var now: Date = Date()

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: Layout.homeHeroSpacing) {
                Text(greeting)
                    .font(.system(size: Layout.homeHeroEyebrowSize, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
                    .textCase(.uppercase)
                    .tracking(0.6)
                    .lineLimit(1)

                Text(headline)
                    .font(.system(size: Layout.homeHeroHeadlineSize, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppColors.primaryBlueDark, AppColors.primaryBlue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            if case let .active(days) = streak {
                streakPill(days: days)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: now)
        switch hour {
        case 5..<12:  return L10n.string("homeHeroGreetingMorning")
        case 12..<18: return L10n.string("homeHeroGreetingAfternoon")
        default:      return L10n.string("homeHeroGreetingEvening")
        }
    }

    private var headline: String {
        if case let .active(days) = streak {
            return String(format: L10n.string("homeHeroHeadlineStreakFmt"), days)
        }
        return L10n.string("homeHeroHeadlineNoStreak")
    }

    private func streakPill(days: Int) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "flame.fill")
                .font(.system(size: Layout.homeHeroPillIconSize, weight: .bold))
                .foregroundColor(AppColors.streakAccent)
                .symbolEffect(.pulse)

            Text("\(days)")
                .font(.system(size: Layout.homeHeroPillTextSize, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.primaryBlueDark)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(
            Capsule(style: .continuous)
                .fill(Color.white)
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(AppColors.streakAccent.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: AppColors.streakAccent.opacity(0.12), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    ZStack {
        AppColors.appBackground.ignoresSafeArea()
        VStack(spacing: 24) {
            HomeHeroView(streak: .active(days: 5))
            HomeHeroView(streak: .empty)
        }
        .padding()
    }
}
