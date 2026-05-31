import SwiftUI

struct ReadingContinueReadingCardView: View {
    let title: String
    let languageTitle: String
    let levelTitle: String
    let progress: Double
    let lastOpenedText: String
    let onContinue: () -> Void

    private let accent = ReadingMyTextsTheme.accent
    private let accentDark = ReadingMyTextsTheme.accentDark

    private var progressPercent: Int { Int((progress * 100).rounded()) }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(accent.opacity(0.16))
                        .frame(width: 48, height: 48)
                    Image(systemName: "book.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(accent)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Continue reading")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(accent)
                        .textCase(.uppercase)

                    Text(title)
                        .font(.system(size: Layout.isPadLike ? 18 : 16, weight: .bold, design: .rounded))
                        .foregroundColor(accentDark)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 8) {
                ReadingMetadataChip(text: languageTitle, accent: accent)
                ReadingMetadataChip(text: levelTitle, accent: accent)
                Spacer(minLength: 0)
                Text("Opened \(lastOpenedText)")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.mutedText)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("\(progressPercent)% complete")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                    Spacer()
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(accent.opacity(0.14))
                            .frame(height: 6)
                        Capsule()
                            .fill(accent)
                            .frame(width: max(6, geo.size.width * progress), height: 6)
                    }
                }
                .frame(height: 6)
            }

            Button(action: onContinue) {
                HStack(spacing: 6) {
                    Text("Continue")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 18)
                .frame(height: 40)
                .background(accent)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.96))
                .shadow(color: accent.opacity(0.12), radius: 14, x: 0, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
                .stroke(accent.opacity(0.22), lineWidth: 1)
        )
    }
}

#Preview {
    ZStack {
        AppColors.appBackground.ignoresSafeArea()
        ReadingContinueReadingCardView(
            title: "A Morning in the City",
            languageTitle: "English",
            levelTitle: "B1",
            progress: 0.65,
            lastOpenedText: "Yesterday",
            onContinue: {}
        )
        .padding()
    }
}
