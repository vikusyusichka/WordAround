import SwiftUI

struct DebateRoundCardView: View {
    let round: DebateRound

    private let accent = DebateTheme.accent
    private let accentDark = DebateTheme.accentDark

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(accent.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: "flag.checkered")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(accent)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(round.title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(accentDark)
                Text(round.learnerPrompt)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.94))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
    }
}

#Preview {
    ZStack {
        AppColors.appBackground.ignoresSafeArea()
        DebateRoundCardView(round: DebatePlan.rounds(for: .medium)[1])
            .padding()
    }
}
