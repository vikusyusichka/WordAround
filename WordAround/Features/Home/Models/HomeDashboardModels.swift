import SwiftUI

// MARK: - Continue Learning

struct ContinueLearningItem {
    let title: String
    let subtitle: String
    let icon: String

    init?(set: HomeSetPreviewItem?) {
        guard let set else { return nil }
        self.title = set.title
        self.subtitle = set.subtitle.isEmpty
            ? L10n.string("homeContinueLearningContinueSession")
            : set.subtitle
        self.icon = set.iconSystemName
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
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.white)

                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(accent.opacity(0.05))

                BlobShape()
                    .fill(accent.opacity(0.12))
                    .frame(
                        width: Layout.homeDashboardBlobSize.width,
                        height: Layout.homeDashboardBlobSize.height
                    )
                    .offset(x: 30, y: -28)
                    .allowsHitTesting(false)
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(accent.opacity(0.16), lineWidth: 1)
        )
        .shadow(color: accent.opacity(0.12), radius: 16, x: 0, y: 8)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
    }
}
