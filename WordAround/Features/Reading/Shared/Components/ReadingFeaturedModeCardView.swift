import SwiftUI

struct ReadingFeaturedModeCardView: View {
    let mode: ReadingMode

    var body: some View {
        let cornerRadius = Layout.speakingModeCardCornerRadius + 2

        ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(mode.accentColor)

            StatBlobShape()
                .fill(Color.white.opacity(0.16))
                .frame(width: 150, height: 124)
                .offset(x: 26, y: 22)

            HStack(alignment: .top, spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.22))
                        .frame(width: 60, height: 60)
                    Image(systemName: mode.systemImage)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n.string("readingFeatured"))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.18))
                        .clipShape(Capsule())

                    Text(mode.title)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(mode.subtitle)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.92))
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
            .padding(Layout.speakingModeCardPadding + 2)
            .frame(maxWidth: .infinity, alignment: .topLeading)

            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.22))
                    .frame(width: Layout.speakingModeArrowCircleSize + 4, height: Layout.speakingModeArrowCircleSize + 4)
                Image(systemName: "arrow.right")
                    .font(.system(size: Layout.speakingModeArrowIconSize + 1, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(Layout.speakingModeCardPadding + 2)
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .shadow(color: mode.accentColor.opacity(0.30), radius: 16, x: 0, y: 8)
        .contentShape(Rectangle())
    }
}

#Preview {
    ZStack {
        AppColors.appBackground.ignoresSafeArea()
        ReadingFeaturedModeCardView(mode: ReadingMyTextsMode.homeCard)
            .padding(20)
    }
}
