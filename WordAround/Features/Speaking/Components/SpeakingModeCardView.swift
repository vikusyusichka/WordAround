import SwiftUI

struct SpeakingModeCardView: View {
    let mode: SpeakingMode

    var body: some View {
        let cornerRadius = Layout.speakingModeCardCornerRadius

        ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.white)

            StatBlobShape()
                .fill(mode.blobColor.opacity(0.72))
                .frame(
                    width: Layout.speakingModeBlobSize.width,
                    height: Layout.speakingModeBlobSize.height
                )
                .offset(
                    x: Layout.speakingModeBlobOffsetX,
                    y: Layout.speakingModeBlobOffsetY
                )

            VStack(alignment: .leading, spacing: 0) {
                ZStack {
                    Circle()
                        .fill(mode.accentColor.opacity(0.12))
                        .frame(
                            width: Layout.speakingModeIconCircleSize,
                            height: Layout.speakingModeIconCircleSize
                        )

                    Image(systemName: mode.systemImage)
                        .font(.system(size: Layout.speakingModeIconSize, weight: .semibold))
                        .foregroundColor(mode.accentColor)
                }

                Spacer(minLength: 10)

                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.title)
                        .font(.system(size: Layout.speakingModeTitleSize, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.primaryBlueDark)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(mode.subtitle)
                        .font(.system(size: Layout.speakingModeSubtitleSize, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(3)
                        .minimumScaleFactor(0.85)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 10)

                HStack {
                    Spacer()
                    ZStack {
                        Circle()
                            .fill(mode.accentColor.opacity(0.12))
                            .frame(
                                width: Layout.speakingModeArrowCircleSize,
                                height: Layout.speakingModeArrowCircleSize
                            )

                        Image(systemName: "arrow.right")
                            .font(.system(size: Layout.speakingModeArrowIconSize, weight: .semibold))
                            .foregroundColor(mode.accentColor)
                    }
                }
            }
            .padding(Layout.speakingModeCardPadding)
            .frame(maxWidth: .infinity, minHeight: Layout.speakingModeCardMinHeight, alignment: .topLeading)
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(Color.white.opacity(0.92), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.055), radius: 10, x: 0, y: 4)
        .contentShape(Rectangle())
    }
}

#Preview {
    ZStack {
        AppColors.appBackground.ignoresSafeArea()

        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            ForEach(SpeakingMode.allModes) { mode in
                SpeakingModeCardView(mode: mode)
            }
        }
        .padding(20)
    }
}
