import SwiftUI

struct WriteWordsCountdownTimerView: View {
    let progress: CGFloat

    private var clampedProgress: CGFloat {
        min(max(progress, 0), 1)
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(0.72))

                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                AppColors.primaryBlue,
                                Color(red: 0.45, green: 0.39, blue: 1.00)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: proxy.size.width * clampedProgress)
            }
        }
        .frame(height: 4)
        .animation(.linear(duration: 0.08), value: clampedProgress)
        .accessibilityHidden(true)
    }
}

#Preview {
    VStack(spacing: 20) {
        WriteWordsCountdownTimerView(progress: 1.0)
        WriteWordsCountdownTimerView(progress: 0.55)
        WriteWordsCountdownTimerView(progress: 0.18)
    }
    .padding()
    .background(AppColors.appBackground)
}
