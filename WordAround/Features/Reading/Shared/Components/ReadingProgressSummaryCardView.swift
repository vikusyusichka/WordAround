import SwiftUI

struct ReadingProgressSummaryCardView: View {
    let currentMinutes: Int
    let totalMinutes: Int

    var body: some View {
        ProgressCardView(
            layout: .goal,
            title: "Today progress",
            currentValue: currentMinutes,
            totalValue: totalMinutes,
            unit: "min",
            subtitle: "of reading practice",
            progress: Double(currentMinutes) / Double(max(totalMinutes, 1)),
            tint: ReadingHomeViewModel.indigo,
            backgroundColor: AppColors.goalBackground,
            progressBackgroundColor: AppColors.goalProgressBackground,
            titleColor: AppColors.primaryBlueDark,
            valueColor: AppColors.primaryBlueDark,
            subtitleColor: AppColors.textSecondary,
            iconSystemName: "book.fill",
            iconBackground: .white,
            blobColor: ReadingHomeViewModel.indigoBlob
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
