import SwiftUI

struct SpeakingProgressCardView: View {
    let currentMinutes: Int
    let totalMinutes: Int

    var body: some View {
        ProgressCardView(
            layout: .goal,
            title: "Today progress",
            currentValue: currentMinutes,
            totalValue: totalMinutes,
            unit: "min",
            subtitle: "of speaking practice",
            progress: Double(currentMinutes) / Double(max(totalMinutes, 1)),
            tint: AppColors.primaryBlue,
            backgroundColor: AppColors.goalBackground,
            progressBackgroundColor: AppColors.goalProgressBackground,
            titleColor: AppColors.primaryBlueDark,
            valueColor: AppColors.primaryBlueDark,
            subtitleColor: AppColors.textSecondary,
            iconSystemName: "mic.fill",
            iconBackground: .white,
            blobColor: Color(red: 0.82, green: 0.86, blue: 0.98)
        )
    }
}

#Preview {
    ZStack {
        AppColors.appBackground.ignoresSafeArea()
        SpeakingProgressCardView(currentMinutes: 7, totalMinutes: 15)
            .padding(20)
    }
}
