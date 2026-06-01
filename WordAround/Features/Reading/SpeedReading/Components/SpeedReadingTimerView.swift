import SwiftUI

struct SpeedReadingTimerView: View {
    let timerMode: ReadingTimerStyle
    let displayText: String
    let label: String
    let progress: Double
    let accent: Color

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(accent.opacity(0.16), lineWidth: 4)
                    .frame(width: 64, height: 64)

                if timerMode.enforcesPace {
                    Circle()
                        .trim(from: 0, to: max(0.001, min(1, progress)))
                        .stroke(accent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 64, height: 64)
                        .animation(.linear(duration: 0.25), value: progress)
                }

                Text(displayText)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(accent)
                    .monospacedDigit()
            }

            Text(label)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
        }
    }
}

#Preview {
    HStack(spacing: 20) {
        SpeedReadingTimerView(
            timerMode: .strict,
            displayText: "00:08",
            label: "Time left",
            progress: 0.35,
            accent: ReadingSetupConfig.speedReading.accent
        )
        SpeedReadingTimerView(
            timerMode: .soft,
            displayText: "00:20",
            label: "Time left",
            progress: 0.7,
            accent: ReadingSetupConfig.speedReading.accent
        )
        SpeedReadingTimerView(
            timerMode: .noTimer,
            displayText: "01:12",
            label: "Chunk time",
            progress: 0,
            accent: ReadingSetupConfig.speedReading.accent
        )
    }
    .padding()
    .background(AppColors.appBackground)
}
