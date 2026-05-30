import SwiftUI

/// Summary card shown above the CTA on each setup screen. Displays an icon,
/// a title + subtitle, and a wrapping row of metadata chips.
struct ReadingPreviewCard: View {
    let title: String
    let subtitle: String
    let chips: [String]
    var accent: Color = AppColors.primaryBlue
    var accentDark: Color = AppColors.primaryBlueDark
    var systemImage: String = "book.fill"

    private var chipColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 78), spacing: 8, alignment: .leading)]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(accent.opacity(0.14))
                        .frame(width: 56, height: 56)
                    Image(systemName: systemImage)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(accent)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(accentDark)
                    Text(subtitle)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            if !chips.isEmpty {
                LazyVGrid(columns: chipColumns, alignment: .leading, spacing: 8) {
                    ForEach(chips, id: \.self) { ReadingMetadataChip(text: $0, accent: accent) }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.94))
                .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 5)
        )
    }
}

#Preview {
    ZStack {
        AppColors.appBackground.ignoresSafeArea()
        ReadingPreviewCard(
            title: "Generated Reading",
            subtitle: "A fresh text created for your level.",
            chips: ["B1", "Medium", "Random topic", "8 questions"],
            accent: AppColors.primaryBlue,
            accentDark: AppColors.primaryBlueDark,
            systemImage: "sparkles"
        )
        .padding()
    }
}
