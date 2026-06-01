import SwiftUI

struct ListeningModeCardView: View {
    let mode: ListeningMode

    private let corner = Layout.listeningModeCardCornerRadius

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(Color.white)

            StatBlobShape()
                .fill(mode.blobColor.opacity(0.72))
                .frame(
                    width: Layout.listeningModeBlobSize.width,
                    height: Layout.listeningModeBlobSize.height
                )
                .offset(x: Layout.listeningModeBlobOffsetX, y: Layout.listeningModeBlobOffsetY)

            VStack(alignment: .leading, spacing: 0) {
                ZStack {
                    Circle()
                        .fill(mode.accentColor.opacity(0.12))
                        .frame(
                            width: Layout.listeningModeIconCircleSize,
                            height: Layout.listeningModeIconCircleSize
                        )

                    Image(systemName: mode.systemImage)
                        .font(.system(size: Layout.listeningModeIconSize, weight: .semibold))
                        .foregroundColor(mode.accentColor)
                }

                Spacer(minLength: Layout.listeningModeContentSpacing)

                VStack(alignment: .leading, spacing: Layout.listeningModeTextSpacing) {
                    Text(mode.title)
                        .font(.system(size: Layout.listeningModeTitleSize, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.primaryBlueDark)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(mode.subtitle)
                        .font(.system(size: Layout.listeningModeSubtitleSize, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(3)
                        .minimumScaleFactor(0.85)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: Layout.listeningModeContentSpacing)

                HStack {
                    Spacer()
                    ZStack {
                        Circle()
                            .fill(mode.accentColor.opacity(0.12))
                            .frame(
                                width: Layout.listeningModeArrowCircleSize,
                                height: Layout.listeningModeArrowCircleSize
                            )

                        Image(systemName: "arrow.right")
                            .font(.system(size: Layout.listeningModeArrowIconSize, weight: .semibold))
                            .foregroundColor(mode.accentColor)
                    }
                }
            }
            .padding(Layout.listeningModeCardPadding)
            .frame(maxWidth: .infinity, minHeight: Layout.listeningModeCardMinHeight, alignment: .topLeading)
        }
        .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: corner, style: .continuous)
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
            ForEach(ListeningMode.allModes) { mode in
                ListeningModeCardView(mode: mode)
            }
        }
        .padding(20)
    }
}
