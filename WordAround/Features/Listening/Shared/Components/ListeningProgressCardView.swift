import SwiftUI

struct ListeningProgressCardView: View {
    let currentMinutes: Int
    let totalMinutes: Int

    var body: some View {
        ProgressCardView(
            layout: .goal,
            title: "Today progress",
            currentValue: currentMinutes,
            totalValue: totalMinutes,
            unit: "min",
            subtitle: "of listening practice",
            progress: Double(currentMinutes) / Double(max(totalMinutes, 1)),
            tint: ListeningTheme.accent,
            backgroundColor: AppColors.goalBackground,
            progressBackgroundColor: AppColors.goalProgressBackground,
            titleColor: AppColors.primaryBlueDark,
            valueColor: AppColors.primaryBlueDark,
            subtitleColor: AppColors.textSecondary,
            iconSystemName: "headphones",
            iconBackground: .white,
            blobColor: ListeningTheme.blobColor
        )
    }
}

#Preview {
    ZStack {
        AppColors.appBackground.ignoresSafeArea()
        ListeningProgressCardView(currentMinutes: 0, totalMinutes: 15)
            .padding(20)
    }
}
