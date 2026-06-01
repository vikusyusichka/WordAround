import SwiftUI

struct StoryChapterHeaderView: View {
    let chapterTitle: String
    let chapterNumber: Int
    var summary: String?
    let accent: Color
    let accentDark: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text("Chapter \(chapterNumber)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(accent.opacity(0.12))
                    .clipShape(Capsule())

                Text(chapterTitle)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(accentDark)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let summary, !summary.isEmpty {
                Text(summary)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
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
