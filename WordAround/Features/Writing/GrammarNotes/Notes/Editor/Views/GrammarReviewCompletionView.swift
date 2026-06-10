import SwiftUI

struct GrammarReviewCompletionView: View {
    let reviewedCount: Int
    let hardCount: Int
    let forgotCount: Int
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 0)

            ZStack {
                Circle().fill(AppColors.primaryBlue.opacity(0.12))
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundStyle(AppColors.primaryBlue)
            }
            .frame(width: 96, height: 96)

            Text(L10n.string(reviewedCount > 0 ? "reviewCompleteTitle" : "reviewCompleteNothing"))
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(AppColors.primaryBlueDark)
                .multilineTextAlignment(.center)

            Text(encouragingMessage)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 32)

            if reviewedCount > 0 {
                statsRow
            }

            Spacer(minLength: 0)

            Button(action: onDone) {
                Text(L10n.localized(.commonDone))
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(AppColors.primaryBlue)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: AppColors.primaryBlue.opacity(0.18), radius: 12, x: 0, y: 6)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var encouragingMessage: String {
        if reviewedCount == 0 {
            return L10n.string("reviewMsgEmpty")
        }
        let troubled = hardCount + forgotCount
        if troubled == 0 {
            return L10n.string("reviewMsgClean")
        }
        if troubled == reviewedCount {
            return L10n.string("reviewMsgTough")
        }
        return L10n.string("reviewMsgMixed")
    }

    private var statsRow: some View {
        HStack(spacing: 10) {
            statTile(value: reviewedCount, label: L10n.string("reviewStatReviewed"), tint: AppColors.primaryBlue)
            statTile(value: hardCount,     label: L10n.string("reviewStatHard"),     tint: Color(red: 0.85, green: 0.55, blue: 0.20))
            statTile(value: forgotCount,   label: L10n.string("reviewStatForgot"),   tint: CreateSetTheme.red.accent)
        }
        .padding(.horizontal, 8)
    }

    private func statTile(value: Int, label: String, tint: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(tint)
            Text(label)
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
                .textCase(.uppercase)
                .tracking(0.6)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(tint.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

#Preview("Successful session") {
    GrammarReviewCompletionView(reviewedCount: 8, hardCount: 1, forgotCount: 0, onDone: {})
        .background(AppColors.appBackground)
}

#Preview("Tough session") {
    GrammarReviewCompletionView(reviewedCount: 5, hardCount: 2, forgotCount: 3, onDone: {})
        .background(AppColors.appBackground)
}

#Preview("Empty") {
    GrammarReviewCompletionView(reviewedCount: 0, hardCount: 0, forgotCount: 0, onDone: {})
        .background(AppColors.appBackground)
}
