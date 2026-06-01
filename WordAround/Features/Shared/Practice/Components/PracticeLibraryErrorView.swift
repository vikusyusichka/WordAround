import SwiftUI

struct PracticeLibraryErrorView: View {
    let message: String
    let accent: Color
    let accentDark: Color
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 30, weight: .semibold))
                .foregroundColor(accent)
            Text(message)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)
            Button(action: onRetry) {
                Text("Retry")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 22)
                    .frame(height: 42)
                    .background(accent)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .background(practiceCardBackground)
    }

    private var practiceCardBackground: some View {
        RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
            .fill(Color.white.opacity(0.94))
            .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 5)
    }
}
