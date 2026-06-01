import SwiftUI

struct SpeedReadingProgressCardView: View {
    let chunkProgressText: String
    let overallProgress: Double
    let currentWPM: Int
    let targetWPM: Int
    let paceStatus: String
    let timerHelperText: String
    let accent: Color
    let accentDark: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(chunkProgressText)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(accentDark)
                    Text(timerHelperText)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(2)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(currentWPM)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(accent)
                        .monospacedDigit()
                    Text("WPM")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                }
            }

            ReadingProgressBar(progress: overallProgress, accent: accent)

            HStack {
                Text("Target: \(targetWPM) WPM")
                Spacer()
                Text(paceStatus)
            }
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundColor(AppColors.textSecondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.94))
                .shadow(color: accent.opacity(0.06), radius: 10, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
                .stroke(accent.opacity(0.12), lineWidth: 1)
        )
    }
}

#Preview {
    SpeedReadingProgressCardView(
        chunkProgressText: "Chunk 2 / 6",
        overallProgress: 0.33,
        currentWPM: 215,
        targetWPM: 240,
        paceStatus: "Slightly below target",
        timerHelperText: "Recommended pace — keep moving.",
        accent: ReadingSetupConfig.speedReading.accent,
        accentDark: ReadingSetupConfig.speedReading.accentDark
    )
    .padding()
    .background(AppColors.appBackground)
}
