import SwiftUI

struct WritingMenuCardView: View {
    let item: WritingMenuItem

    private let corner = Layout.readingModeCardCornerRadius

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(Color.white)

            StatBlobShape()
                .fill(item.blobColor.opacity(0.72))
                .frame(
                    width: Layout.readingModeBlobSize.width,
                    height: Layout.readingModeBlobSize.height
                )
                .offset(x: Layout.readingModeBlobOffsetX, y: Layout.readingModeBlobOffsetY)

            VStack(alignment: .leading, spacing: 0) {
                iconCircle

                Spacer(minLength: Layout.readingModeContentSpacing)

                VStack(alignment: .leading, spacing: Layout.readingModeTextSpacing) {
                    Text(item.title)
                        .font(.system(size: Layout.readingModeTitleSize, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.primaryBlueDark)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(item.subtitle)
                        .font(.system(size: Layout.readingModeSubtitleSize, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(3)
                        .minimumScaleFactor(0.85)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: Layout.readingModeContentSpacing)

                HStack {
                    Spacer()
                    arrowCircle
                }
            }
            .padding(Layout.readingModeCardPadding)
            .frame(maxWidth: .infinity, minHeight: Layout.readingModeCardMinHeight, alignment: .topLeading)
        }
        .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .stroke(Color.white.opacity(0.92), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.055), radius: 10, x: 0, y: 4)
        .contentShape(Rectangle())
    }

    private var iconCircle: some View {
        ZStack {
            Circle()
                .fill(item.accentColor.opacity(0.12))
                .frame(width: Layout.readingModeIconCircleSize, height: Layout.readingModeIconCircleSize)
            Image(systemName: item.systemImage)
                .font(.system(size: Layout.readingModeIconSize, weight: .semibold))
                .foregroundColor(item.accentColor)
        }
    }

    private var arrowCircle: some View {
        ZStack {
            Circle()
                .fill(item.accentColor.opacity(0.12))
                .frame(width: Layout.readingModeArrowCircleSize, height: Layout.readingModeArrowCircleSize)
            Image(systemName: "arrow.right")
                .font(.system(size: Layout.readingModeArrowIconSize, weight: .semibold))
                .foregroundColor(item.accentColor)
        }
    }
}

#Preview {
    ZStack {
        AppColors.appBackground.ignoresSafeArea()
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            ForEach(WritingViewModel().menuItems) { item in
                WritingMenuCardView(item: item)
            }
        }
        .padding(20)
    }
}
