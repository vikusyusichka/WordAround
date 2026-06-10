import SwiftUI

struct WritingProgressSummaryCardView: View {
    let currentWords: Int
    let totalWords: Int

    var body: some View {
        ProgressCardView(
            layout: .goal,
            title: L10n.string("progressToday"),
            currentValue: currentWords,
            totalValue: totalWords,
            unit: L10n.string("commonWords"),
            subtitle: L10n.string("progressOfWriting"),
            progress: Double(currentWords) / Double(max(totalWords, 1)),
            tint: AppColors.primaryBlue,
            backgroundColor: AppColors.goalBackground,
            progressBackgroundColor: AppColors.goalProgressBackground,
            titleColor: AppColors.primaryBlueDark,
            valueColor: AppColors.primaryBlueDark,
            subtitleColor: AppColors.textSecondary,
            iconSystemName: "pencil",
            iconBackground: .white,
            blobColor: Color(red: 0.82, green: 0.86, blue: 0.98)
        )
    }
}

#Preview {
    ZStack {
        AppColors.appBackground.ignoresSafeArea()
        WritingProgressSummaryCardView(currentWords: 120, totalWords: 200)
            .padding(20)
    }
}
