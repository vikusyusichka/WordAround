import SwiftUI

struct ReadingProgressSummaryCardView: View {
    let currentMinutes: Int
    let totalMinutes: Int

    var body: some View {
        ProgressCardView(
            layout: .goal,
            title: L10n.string("progressToday"),
            currentValue: currentMinutes,
            totalValue: totalMinutes,
            unit: L10n.string("profileMinutesShort"),
            subtitle: L10n.string("progressOfReading"),
            progress: Double(currentMinutes) / Double(max(totalMinutes, 1)),
            tint: AppColors.primaryBlue,
            backgroundColor: AppColors.goalBackground,
            progressBackgroundColor: AppColors.goalProgressBackground,
            titleColor: AppColors.primaryBlueDark,
            valueColor: AppColors.primaryBlueDark,
            subtitleColor: AppColors.textSecondary,
            iconSystemName: "book.fill",
            iconBackground: .white,
            blobColor: Color(red: 0.82, green: 0.86, blue: 0.98)
        )
    }
}

#Preview {
    ZStack {
        AppColors.appBackground.ignoresSafeArea()
        ReadingProgressSummaryCardView(currentMinutes: 6, totalMinutes: 15)
            .padding(20)
    }
}
