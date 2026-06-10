import SwiftUI

struct ReadingScoreCardView: View {
    let comprehensionPercent: Int
    let accent: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(comprehensionPercent)%")
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundColor(accent)
            Text(L10n.string("readingComprehension"))
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
        }
    }
}
