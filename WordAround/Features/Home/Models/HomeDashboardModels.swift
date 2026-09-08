import SwiftUI

// MARK: - Continue Learning

struct ContinueLearningItem {
    /// Real learning progress for the hero card. Only present when the set
    /// actually has tracked progress (> 0) — never synthesized, so the hero
    /// shows a progress bar the moment the app starts recording it and an
    /// honest cards-count badge until then.
    struct Progress {
        let current: Int
        let total: Int
        let fraction: Double
    }

    let title: String
    let subtitle: String
    let icon: String
    let cardsCount: Int?
    let progress: Progress?

    init?(set: HomeSetPreviewItem?) {
        guard let set else { return nil }
        self.title = set.title
        self.subtitle = set.subtitle.isEmpty
            ? L10n.string("homeContinueLearningContinueSession")
            : set.subtitle
        self.icon = set.iconSystemName
        self.cardsCount = set.sourceSet?.cards.count
        self.progress = set.progress > 0
            ? Progress(current: set.currentValue, total: set.totalValue, fraction: set.progress)
            : nil
    }
}

// MARK: - Daily Tip

struct DailyTip: Identifiable, Equatable {
    let id: Int
    let short: String
    let detail: String
}

enum DailyTipProvider {
    private static let count = 6

    static func todayTip(for date: Date = Date(), calendar: Calendar = .current) -> DailyTip {
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        let index = ((dayOfYear - 1) % count) + 1
        return DailyTip(
            id: index,
            short: L10n.string("homeTipShort\(index)"),
            detail: L10n.string("homeTipDetail\(index)")
        )
    }
}

// MARK: - Streak

enum HomeStreakState: Equatable {
    case active(days: Int)
    case empty
}

// MARK: - Shared dashboard card chrome

extension View {
    func homeDashboardSurface(
        accent: Color,
        cornerRadius: CGFloat = Layout.homeDashboardCardCornerRadius
    ) -> some View {
        background(
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.white)

                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(accent.opacity(0.05))

                // Layered decorative accents — a soft corner blob plus a faint
                // secondary blob, echoing the set / Speaking cards without glow.
                BlobShape()
                    .fill(accent.opacity(0.16))
                    .frame(
                        width: Layout.homeDashboardBlobSize.width,
                        height: Layout.homeDashboardBlobSize.height
                    )
                    .rotationEffect(.degrees(-8))
                    .offset(x: 28, y: -26)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)

                BlobShape()
                    .fill(accent.opacity(0.07))
                    .frame(
                        width: Layout.homeDashboardBlobSize.width * 0.6,
                        height: Layout.homeDashboardBlobSize.height * 0.6
                    )
                    .offset(x: -22, y: 30)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .allowsHitTesting(false)
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.85), accent.opacity(0.14)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        // Soft neutral elevation — no strong colored glow.
        .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 7)
    }
}

/// Vivid icon capsule used across the dashboard cards — a solid accent squircle
/// with a white glyph and a soft colored drop shadow. This is the main "pop"
/// element that gives the otherwise-white cards life, matching the set cards.
struct HomeDashboardIconChip: View {
    let systemName: String
    let accent: Color
    var size: CGFloat = Layout.homeDashboardIconChipSize
    var iconSize: CGFloat = Layout.homeDashboardIconSize
    var cornerRadius: CGFloat = 15

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [accent.opacity(0.88), accent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .shadow(color: accent.opacity(0.25), radius: 6, x: 0, y: 3)

            // Glassy inner rim — a faint white edge that catches the light,
            // matching the layered look of the set / Speaking cards.
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(Color.white.opacity(0.28), lineWidth: 1)
                .frame(width: size, height: size)

            Image(systemName: systemName)
                .font(.system(size: iconSize, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

/// Shared press feedback for the tappable Home cards — a gentle scale-down,
/// no springs, matching the calm WordAround motion language.
struct HomeCardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
