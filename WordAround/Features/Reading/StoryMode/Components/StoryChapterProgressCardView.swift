import SwiftUI

struct StoryChapterProgressCardView: View {
    let storyTitle: String
    let typeTitle: String
    let difficultyTitle: String
    let languageTitle: String
    let lengthTitle: String
    let chapterProgressText: String
    let overallProgress: Double
    let accent: Color
    let accentDark: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(storyTitle)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(accentDark)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 6) {
                ReadingMetadataChip(text: typeTitle, accent: accent)
                ReadingMetadataChip(text: difficultyTitle, accent: accent)
                ReadingMetadataChip(text: languageTitle, accent: accent)
                ReadingMetadataChip(text: lengthTitle, accent: accent)
                Spacer(minLength: 0)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(chapterProgressText)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(accentDark)
                    Spacer()
                    Text("\(Int(overallProgress * 100))%")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(accent)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(accent.opacity(0.12))
                            .frame(height: 6)
                        Capsule()
                            .fill(accent)
                            .frame(width: geo.size.width * overallProgress, height: 6)
                    }
                }
                .frame(height: 6)
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
