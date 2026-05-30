import SwiftUI

/// Back button + title + subtitle header shared by all Reading setup screens.
/// Matches the Speaking setup header (white circular back button, themed text).
struct ReadingSetupHeaderView: View {
    let title: String
    let subtitle: String
    var accent: Color = AppColors.primaryBlue
    var accentDark: Color = AppColors.primaryBlueDark
    let onBack: () -> Void

    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: Layout.homeHeaderTitleSize, weight: .bold, design: .rounded))
                    .foregroundColor(accentDark)

                Text(subtitle)
                    .font(.system(size: Layout.homeHeaderSubtitleSize, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.mutedText)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, Layout.flashcardDetailTopButtonSize + 10)
            .padding(.trailing, 10)

            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: Layout.flashcardDetailTopButtonIconSize, weight: .bold))
                        .foregroundColor(accentDark)
                        .frame(
                            width: Layout.flashcardDetailTopButtonSize,
                            height: Layout.flashcardDetailTopButtonSize
                        )
                        .background(Color.white.opacity(0.82))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .hoverEffect(.lift)

                Spacer()
            }
        }
    }
}

#Preview {
    ZStack {
        AppColors.appBackground.ignoresSafeArea()
        ReadingSetupHeaderView(
            title: "Generated Reading",
            subtitle: "A fresh text created for your level.",
            accent: AppColors.primaryBlue,
            accentDark: AppColors.primaryBlueDark
        ) {}
        .padding()
    }
}
