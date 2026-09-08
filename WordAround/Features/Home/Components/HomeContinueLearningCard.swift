import SwiftUI

/// The dominant hero of Home — a tall Continue Learning card that answers
/// "what should I learn right now?". Eyebrow + big title + subtitle, an icon
/// chip in the corner, and a bottom row with either a real progress bar
/// (when the set has tracked progress) or a cards-count capsule, next to a
/// prominent green circular CTA.
struct HomeContinueLearningCard: View {
    let item: ContinueLearningItem?
    let action: () -> Void

    // Continue Learning is the green-accented hero card of the dashboard.
    private let accent = AppColors.greenAccent
    private var icon: String { item?.icon ?? "play.circle.fill" }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(L10n.string("homeContinueLearning"))
                            .font(.system(size: Layout.homeDashboardEyebrowSize, weight: .bold, design: .rounded))
                            .foregroundColor(accent)
                            .textCase(.uppercase)
                            .tracking(0.5)
                            .lineLimit(1)

                        Text(activityTitle)
                            .font(.system(size: Layout.homeDashboardHeroTitleSize, weight: .bold, design: .rounded))
                            .foregroundColor(AppColors.greenTitle)
                            .lineLimit(2)
                            .minimumScaleFactor(0.75)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(activitySubtitle)
                            .font(.system(size: Layout.homeDashboardSubtitleSize, weight: .medium, design: .rounded))
                            .foregroundColor(AppColors.textSecondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }

                    Spacer(minLength: 8)

                    iconChip
                }

                Spacer(minLength: 8)

                HStack(alignment: .center, spacing: 12) {
                    bottomLeading
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ctaButton
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(Layout.homeDashboardCardPadding)
            .frame(minHeight: Layout.homeDashboardHeroMinHeight)
            .homeDashboardSurface(accent: accent)
            // Slightly more elevation than the smaller cards, kept neutral/soft.
            .shadow(color: Color.black.opacity(0.05), radius: 16, x: 0, y: 10)
            .contentShape(RoundedRectangle(cornerRadius: Layout.homeDashboardCardCornerRadius, style: .continuous))
        }
        .buttonStyle(HomeCardPressStyle())
    }

    private var activityTitle: String {
        item?.title ?? L10n.string("homeContinueLearningEmptyTitle")
    }

    private var activitySubtitle: String {
        item?.subtitle ?? L10n.string("homeContinueLearningEmptySubtitle")
    }

    @ViewBuilder
    private var bottomLeading: some View {
        if let progress = item?.progress {
            progressBlock(progress)
        } else if let cards = item?.cardsCount {
            cardsBadge(count: cards)
        } else {
            EmptyView()
        }
    }

    private func progressBlock(_ progress: ContinueLearningItem.Progress) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(String(format: L10n.string("homeContinueLearningProgressFmt"), progress.current, progress.total))
                    .font(.system(size: Layout.homeDashboardHeroProgressTextSize, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.greenTitle)
                    .lineLimit(1)

                Spacer(minLength: 8)

                Text("\(Int((progress.fraction * 100).rounded()))%")
                    .font(.system(size: Layout.homeDashboardHeroProgressTextSize, weight: .bold, design: .rounded))
                    .foregroundColor(accent)
                    .lineLimit(1)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(accent.opacity(0.15))

                    Capsule(style: .continuous)
                        .fill(accent)
                        .frame(width: proxy.size.width * min(max(progress.fraction, 0), 1))
                }
            }
            .frame(height: Layout.homeDashboardHeroProgressBarHeight)
        }
    }

    private func cardsBadge(count: Int) -> some View {
        Text(L10n.cardsCount(count))
            .font(.system(size: Layout.homeDashboardSubtitleSize, weight: .bold, design: .rounded))
            .foregroundColor(AppColors.greenTitle)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(accent.opacity(0.12))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(Color.white.opacity(0.65), lineWidth: 1)
            )
    }

    private var iconChip: some View {
        HomeDashboardIconChip(
            systemName: icon,
            accent: accent,
            size: Layout.homeDashboardHeroIconChipSize,
            iconSize: Layout.homeDashboardHeroIconSize,
            cornerRadius: 18
        )
    }

    private var ctaButton: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [accent, AppColors.greenTitle],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(
                    width: Layout.homeDashboardHeroCTASize,
                    height: Layout.homeDashboardHeroCTASize
                )
                .shadow(color: accent.opacity(0.28), radius: 8, x: 0, y: 4)

            Circle()
                .stroke(Color.white.opacity(0.28), lineWidth: 1)
                .frame(
                    width: Layout.homeDashboardHeroCTASize,
                    height: Layout.homeDashboardHeroCTASize
                )

            Image(systemName: "arrow.right")
                .font(.system(size: Layout.homeDashboardHeroIconSize * 0.7, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

#Preview {
    ZStack {
        AppColors.appBackground.ignoresSafeArea()
        VStack(spacing: 16) {
            HomeContinueLearningCard(item: nil, action: {})
        }
        .padding()
    }
}
