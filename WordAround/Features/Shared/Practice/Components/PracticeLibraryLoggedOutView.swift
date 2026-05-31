import SwiftUI

struct PracticeLibraryLoggedOutView: View {
    let title: String
    let message: String
    let accent: Color
    let accentDark: Color

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 32, weight: .semibold))
                .foregroundColor(accent)
            Text(title)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(accentDark)
            Text(message)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .background(
            RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.94))
                .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 5)
        )
    }
}
