import SwiftUI

struct ReadingSetupSectionCard<Content: View>: View {
    let title: String
    var subtitle: String? = nil
    var helper: String? = nil
    var accentDark: Color = AppColors.primaryBlueDark
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: Layout.homeSectionTitleSize, weight: .bold, design: .rounded))
                    .foregroundColor(accentDark)

                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                }
            }

            content

            if let helper {
                Text(helper)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.mutedText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    ZStack {
        AppColors.appBackground.ignoresSafeArea()
        ReadingSetupSectionCard(title: "Reading Level", subtitle: "Choose text difficulty.") {
            ReadingSegmentedSelector(
                options: ReadingLevel.titles,
                selection: .constant("B1"),
                accent: AppColors.primaryBlue,
                accentDark: AppColors.primaryBlueDark
            )
        }
        .padding()
    }
}
