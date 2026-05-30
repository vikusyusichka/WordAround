import SwiftUI

/// One uniform grid card for a Reading mode.
///
/// Every card is identical in size, padding, corner radius, spacing and shadow.
/// A `isFeatured` card differs ONLY by a stronger gradient fill, a small
/// "Featured" badge and a brighter icon treatment — never by size. Structure is
/// always: icon (top-left) + optional badge (top-right) → title → subtitle →
/// arrow (bottom-right).
struct ReadingModeCardView: View {
    let mode: ReadingMode
    var isFeatured: Bool = false

    private let corner = Layout.readingModeCardCornerRadius

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            background

            StatBlobShape()
                .fill(blobFill)
                .frame(
                    width: Layout.readingModeBlobSize.width,
                    height: Layout.readingModeBlobSize.height
                )
                .offset(x: Layout.readingModeBlobOffsetX, y: Layout.readingModeBlobOffsetY)

            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 8) {
                    iconCircle
                    Spacer(minLength: 0)
                    if isFeatured { featuredBadge }
                }

                Spacer(minLength: Layout.readingModeContentSpacing)

                VStack(alignment: .leading, spacing: Layout.readingModeTextSpacing) {
                    Text(mode.title)
                        .font(.system(size: Layout.readingModeTitleSize, weight: .bold, design: .rounded))
                        .foregroundColor(titleColor)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(mode.subtitle)
                        .font(.system(size: Layout.readingModeSubtitleSize, weight: .medium, design: .rounded))
                        .foregroundColor(subtitleColor)
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
                .stroke(strokeColor, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.055), radius: 10, x: 0, y: 4)
        .contentShape(Rectangle())
    }

    // MARK: - Pieces

    @ViewBuilder
    private var background: some View {
        let shape = RoundedRectangle(cornerRadius: corner, style: .continuous)
        if isFeatured {
            shape.fill(
                LinearGradient(
                    colors: [mode.accentColor, mode.accentColor.opacity(0.82)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        } else {
            shape.fill(Color.white)
        }
    }

    private var iconCircle: some View {
        ZStack {
            Circle()
                .fill(isFeatured ? Color.white.opacity(0.22) : mode.accentColor.opacity(0.12))
                .frame(width: Layout.readingModeIconCircleSize, height: Layout.readingModeIconCircleSize)
            Image(systemName: mode.systemImage)
                .font(.system(size: Layout.readingModeIconSize, weight: .semibold))
                .foregroundColor(isFeatured ? .white : mode.accentColor)
        }
    }

    private var arrowCircle: some View {
        ZStack {
            Circle()
                .fill(isFeatured ? Color.white.opacity(0.22) : mode.accentColor.opacity(0.12))
                .frame(width: Layout.readingModeArrowCircleSize, height: Layout.readingModeArrowCircleSize)
            Image(systemName: "arrow.right")
                .font(.system(size: Layout.readingModeArrowIconSize, weight: .semibold))
                .foregroundColor(isFeatured ? .white : mode.accentColor)
        }
    }

    private var featuredBadge: some View {
        Text("Featured")
            .font(.system(size: Layout.readingModeFeaturedBadgeTextSize, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.white.opacity(0.20))
            .clipShape(Capsule())
    }

    // MARK: - Colors

    private var titleColor: Color { isFeatured ? .white : AppColors.primaryBlueDark }
    private var subtitleColor: Color { isFeatured ? Color.white.opacity(0.92) : AppColors.textSecondary }
    private var blobFill: Color { isFeatured ? Color.white.opacity(0.16) : mode.blobColor.opacity(0.72) }
    private var strokeColor: Color { isFeatured ? Color.white.opacity(0.18) : Color.white.opacity(0.92) }
}

#Preview {
    ZStack {
        AppColors.appBackground.ignoresSafeArea()
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            ReadingModeCardView(
                mode: ReadingMode(
                    id: "generated-reading", title: "Generated Reading",
                    subtitle: "Fresh AI texts at your level — read and learn.",
                    systemImage: "sparkles",
                    accentColor: Color(red: 0.42, green: 0.36, blue: 0.86),
                    blobColor: Color(red: 0.88, green: 0.86, blue: 0.98)
                ),
                isFeatured: true
            )
            ReadingModeCardView(
                mode: ReadingMode(
                    id: "my-texts", title: "My Texts",
                    subtitle: "Paste your own text and read it with help.",
                    systemImage: "doc.text.fill",
                    accentColor: Color(red: 0.13, green: 0.66, blue: 0.74),
                    blobColor: Color(red: 0.80, green: 0.94, blue: 0.96)
                )
            )
        }
        .padding(20)
    }
}
