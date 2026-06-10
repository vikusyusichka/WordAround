import SwiftUI

struct GrammarReviewSessionSummaryView: View {
    let totalReviewed: Int
    let correctCount: Int
    let incorrectCount: Int
    let forgotCount: Int
    let hardCount: Int
    let goodCount: Int
    let easyCount: Int
    let onDone: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                Spacer(minLength: 24)

                iconView

                titleSection

                if totalReviewed > 0 {
                    statsGrid
                    ratingBreakdown
                    nextReviewHint
                }

                Spacer(minLength: 0)

                doneButton
                    .padding(.bottom, 32)
            }
            .padding(.horizontal, 24)
        }
    }

    private var iconView: some View {
        ZStack {
            Circle()
                .fill(totalReviewed > 0
                      ? AppColors.primaryBlue.opacity(0.12)
                      : AppColors.textSecondary.opacity(0.10))
            Image(systemName: totalReviewed > 0 ? "checkmark.seal.fill" : "tray.fill")
                .font(.system(size: 38, weight: .bold))
                .foregroundStyle(totalReviewed > 0
                                 ? AppColors.primaryBlue
                                 : AppColors.textSecondary)
        }
        .frame(width: 96, height: 96)
    }

    private var titleSection: some View {
        VStack(spacing: 6) {
            Text(totalReviewed > 0 ? "Session complete" : "Nothing reviewed")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(AppColors.primaryBlueDark)
                .multilineTextAlignment(.center)

            Text(motivationalMessage)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 16)
        }
    }

    private var motivationalMessage: String {
        guard totalReviewed > 0 else {
            return L10n.string("notesSummaryNothingDue")
        }
        let failedCount = forgotCount + hardCount
        if failedCount == 0 {
            return L10n.string("notesSummaryPerfect")
        }
        if failedCount == totalReviewed {
            return L10n.string("notesSummaryTough")
        }
        if correctCount > incorrectCount {
            return L10n.string("notesSummaryNice")
        }
        return L10n.string("notesSummaryKeepGoing")
    }

    private var statsGrid: some View {
        HStack(spacing: 10) {
            statTile(value: totalReviewed, label: "Reviewed", tint: AppColors.primaryBlue)
            statTile(value: correctCount,  label: "Correct",  tint: CreateSetTheme.green.accent)
            statTile(value: incorrectCount, label: "Incorrect", tint: CreateSetTheme.red.accent)
        }
    }

    private func statTile(value: Int, label: String, tint: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(tint)
            Text(label)
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
                .textCase(.uppercase)
                .tracking(0.6)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(tint.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var ratingBreakdown: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.string("notesRatingBreakdown"))
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(AppColors.primaryBlueDark)
                .textCase(.uppercase)
                .tracking(0.6)

            HStack(spacing: 8) {
                ratingPill(count: forgotCount, result: .forgot, tint: CreateSetTheme.red.accent)
                ratingPill(count: hardCount,   result: .hard,   tint: Color(red: 0.85, green: 0.55, blue: 0.20))
                ratingPill(count: goodCount,   result: .good,   tint: AppColors.primaryBlue)
                ratingPill(count: easyCount,   result: .easy,   tint: CreateSetTheme.green.accent)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.88))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 5)
    }

    private func ratingPill(count: Int, result: GrammarReviewResult, tint: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: result.systemImage)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(tint)
            Text("\(count)")
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(AppColors.primaryBlueDark)
            Text(result.title)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(tint.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var nextReviewHint: some View {
        HStack(spacing: 10) {
            Image(systemName: "clock.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(AppColors.primaryBlue)

            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.string("notesNextReview"))
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(AppColors.primaryBlue)

                Text(nextReviewHintText)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(AppColors.primaryBlue.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var nextReviewHintText: String {
        if forgotCount > 0 { return L10n.string("notesNextDue4h") }
        if hardCount > 0 { return L10n.string("notesNextHardTomorrow") }
        if goodCount > 0 { return L10n.string("notesNextGood3d") }
        if easyCount > 0 { return L10n.string("notesNextEasy7d") }
        return L10n.string("notesNextScheduled")
    }

    private var doneButton: some View {
        Button(action: onDone) {
            Text(L10n.string("notesBackToNotes"))
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(AppColors.primaryBlue)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: AppColors.primaryBlue.opacity(0.18), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }
}

#Preview("Good session") {
    GrammarReviewSessionSummaryView(
        totalReviewed: 8,
        correctCount: 6,
        incorrectCount: 2,
        forgotCount: 1,
        hardCount: 1,
        goodCount: 4,
        easyCount: 2,
        onDone: {}
    )
    .background(AppColors.appBackground)
}

#Preview("Empty") {
    GrammarReviewSessionSummaryView(
        totalReviewed: 0,
        correctCount: 0,
        incorrectCount: 0,
        forgotCount: 0,
        hardCount: 0,
        goodCount: 0,
        easyCount: 0,
        onDone: {}
    )
    .background(AppColors.appBackground)
}
