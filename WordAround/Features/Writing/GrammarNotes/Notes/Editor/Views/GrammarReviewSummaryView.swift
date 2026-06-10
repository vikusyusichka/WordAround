import SwiftUI

struct GrammarReviewSummaryView: View {
    let summary: GrammarReviewSummary
    let isLoading: Bool
    let errorMessage: String?
    let queueCount: Int
    let estimatedMinutes: Int
    let effectivePool: GrammarReviewSourcePool?
    let onStart: () -> Void
    let onRetry: () -> Void

    init(
        summary: GrammarReviewSummary,
        isLoading: Bool,
        errorMessage: String?,
        queueCount: Int = 0,
        estimatedMinutes: Int = 1,
        effectivePool: GrammarReviewSourcePool? = nil,
        onStart: @escaping () -> Void,
        onRetry: @escaping () -> Void = {}
    ) {
        self.summary = summary
        self.isLoading = isLoading
        self.errorMessage = errorMessage
        self.queueCount = queueCount
        self.estimatedMinutes = max(1, estimatedMinutes)
        self.effectivePool = effectivePool
        self.onStart = onStart
        self.onRetry = onRetry
    }

    private var effectiveCount: Int { queueCount }

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.grammarSettingsCardInnerSpacing) {
            header

            if isLoading {
                loadingRow
            } else if let errorMessage, !errorMessage.isEmpty {
                errorRow(errorMessage)
            } else if effectivePool == nil {
                emptyRow
            } else {
                sourceRow
                startButton
            }
        }
        .padding(Layout.grammarSettingsCardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
        .clipShape(
            RoundedRectangle(
                cornerRadius: Layout.grammarSettingsCardCornerRadius,
                style: .continuous
            )
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: Layout.grammarSettingsCardCornerRadius,
                style: .continuous
            )
            .stroke(Color.white.opacity(0.62), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.045), radius: 18, x: 0, y: 10)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 11) {
            ZStack {
                Circle().fill(AppColors.primaryBlue.opacity(0.12))
                Image(systemName: "brain.head.profile")
                    .font(.system(size: Layout.grammarSettingsSectionIconSize, weight: .bold))
                    .foregroundStyle(AppColors.primaryBlue)
            }
            .frame(
                width: Layout.grammarSettingsSectionIconBox,
                height: Layout.grammarSettingsSectionIconBox
            )

            VStack(alignment: .leading, spacing: 3) {
                Text(L10n.string("notesReviewToday"))
                    .font(.system(size: Layout.grammarSettingsSectionTitleSize, weight: .black, design: .rounded))
                    .foregroundStyle(AppColors.primaryBlueDark)
                Text(headlineSubtitle)
                    .font(.system(size: Layout.grammarSettingsSectionSubtitleSize, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)
                    .lineSpacing(3)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)

            if !isLoading && effectivePool != nil {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: L10n.string("notesEstimatedMinFormat"), estimatedMinutes))
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.primaryBlue)
                    Text(L10n.string("notesEstimated"))
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
        }
    }

    private var headlineSubtitle: String {
        if isLoading { return L10n.string("notesLoadingQueue") }
        if errorMessage != nil { return L10n.string("notesCouldNotLoadQueue") }
        guard let pool = effectivePool else {
            return L10n.string("notesNothingDue")
        }
        return pool.homeCardSubtitle(count: effectiveCount)
    }

    private var sourceRow: some View {
        guard let pool = effectivePool, effectiveCount > 0 else {
            return AnyView(EmptyView())
        }
        return AnyView(
            HStack(spacing: 8) {
                sourcePill(pool: pool, count: effectiveCount)
                Spacer(minLength: 0)
            }
        )
    }

    private func sourcePill(pool: GrammarReviewSourcePool, count: Int) -> some View {
        let tint = sourceTint(pool)
        return VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 5) {
                Image(systemName: pool.systemImage).font(.system(size: 10, weight: .bold))
                Text(pool.title)
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .textCase(.uppercase)
                    .tracking(0.5)
                    .lineLimit(1)
            }
            .foregroundStyle(tint)

            Text("\(count) note\(count == 1 ? "" : "s")")
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(AppColors.primaryBlueDark)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(tint.opacity(0.08))
        .clipShape(
            RoundedRectangle(
                cornerRadius: Layout.grammarSettingsRowCornerRadius,
                style: .continuous
            )
        )
    }

    private func sourceTint(_ pool: GrammarReviewSourcePool) -> Color {
        switch pool {
        case .manual:         return AppColors.primaryBlue
        case .recentlyOpened: return CreateSetTheme.green.accent
        case .recentlyEdited: return Color(red: 0.85, green: 0.55, blue: 0.20)
        }
    }

    private var startButton: some View {
        Button(action: onStart) {
            HStack(spacing: 8) {
                Image(systemName: "play.fill").font(.system(size: 13, weight: .bold))
                Text(L10n.string("notesStartReview")).font(.system(size: 15, weight: .bold, design: .rounded))
            }
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .background(AppColors.primaryBlue)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: AppColors.primaryBlue.opacity(0.18), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(.plain)
    }

    private var emptyRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(CreateSetTheme.green.accent)
                Text(L10n.string("notesAllCaughtUp"))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)
                Spacer(minLength: 0)
            }

            Text(L10n.string("notesAddToReviewHint"))
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.textSecondary.opacity(0.75))
                .lineSpacing(2)
        }
    }

    private var loadingRow: some View {
        HStack(spacing: 10) {
            ProgressView().tint(AppColors.primaryBlue).scaleEffect(0.85)
            Text(L10n.string("commonLoadingEllipsis"))
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
            Spacer(minLength: 0)
        }
    }

    private func errorRow(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(CreateSetTheme.red.accent)
                Text(message)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)
                    .lineLimit(3)
                Spacer(minLength: 0)
            }

            Button(action: onRetry) {
                Text(L10n.string("commonRetry"))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.primaryBlue)
                    .padding(.horizontal, 12)
                    .frame(height: 32)
                    .background(AppColors.primaryBlue.opacity(0.10))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    private var cardBackground: some View {
        ZStack(alignment: .topTrailing) {
            Color.white.opacity(0.84)

            BlobShape()
                .fill(AppColors.primaryBlue.opacity(0.09))
                .frame(
                    width: Layout.isPadLike ? 150 : 110,
                    height: Layout.isPadLike ? 120 : 90
                )
                .rotationEffect(.degrees(-9))
                .offset(
                    x: Layout.isPadLike ? 48 : 36,
                    y: Layout.isPadLike ? -40 : -28
                )
        }
    }
}

#Preview("Manual") {
    GrammarReviewSummaryView(
        summary: GrammarReviewSummary(dueTotal: 3, dueNotes: 2, dueMistakes: 1, dueQuizzes: 0),
        isLoading: false,
        errorMessage: nil,
        queueCount: 3,
        estimatedMinutes: 6,
        effectivePool: .manual,
        onStart: {}
    )
    .padding()
    .background(AppColors.appBackground)
}

#Preview("Recently opened") {
    GrammarReviewSummaryView(
        summary: .empty,
        isLoading: false,
        errorMessage: nil,
        queueCount: 2,
        estimatedMinutes: 4,
        effectivePool: .recentlyOpened,
        onStart: {}
    )
    .padding()
    .background(AppColors.appBackground)
}

#Preview("Empty") {
    GrammarReviewSummaryView(
        summary: .empty,
        isLoading: false,
        errorMessage: nil,
        queueCount: 0,
        estimatedMinutes: 1,
        effectivePool: nil,
        onStart: {}
    )
    .padding()
    .background(AppColors.appBackground)
}

#Preview("Loading") {
    GrammarReviewSummaryView(
        summary: .empty,
        isLoading: true,
        errorMessage: nil,
        queueCount: 0,
        estimatedMinutes: 1,
        effectivePool: nil,
        onStart: {}
    )
    .padding()
    .background(AppColors.appBackground)
}
