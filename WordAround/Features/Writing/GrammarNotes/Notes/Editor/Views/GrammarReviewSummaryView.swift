import SwiftUI

struct GrammarReviewSummaryView: View {
    let summary: GrammarReviewSummary
    let isLoading: Bool
    let errorMessage: String?
    /// Number of cards the upcoming session will surface. This comes from
    /// the pre-built `GrammarReviewQueueBuilder.Result` so the card and the
    /// session are guaranteed to agree.
    let queueCount: Int
    /// Estimated minutes badge in the header — usually `max(1, count * 2)`.
    let estimatedMinutes: Int
    let isAddingRecommendation: Bool
    /// Which pool the upcoming session will use. `nil` means the queue is
    /// empty and the card shows the "Nothing due" hint.
    let effectivePool: GrammarReviewSourcePool?
    let onStart: () -> Void
    let onRetry: () -> Void

    init(
        summary: GrammarReviewSummary,
        isLoading: Bool,
        errorMessage: String?,
        queueCount: Int = 0,
        estimatedMinutes: Int = 1,
        isAddingRecommendation: Bool = false,
        effectivePool: GrammarReviewSourcePool? = nil,
        onStart: @escaping () -> Void,
        onRetry: @escaping () -> Void = {}
    ) {
        self.summary = summary
        self.isLoading = isLoading
        self.errorMessage = errorMessage
        self.queueCount = queueCount
        self.estimatedMinutes = max(1, estimatedMinutes)
        self.isAddingRecommendation = isAddingRecommendation
        self.effectivePool = effectivePool
        self.onStart = onStart
        self.onRetry = onRetry
    }

    /// Count of notes in the effective pool — drives the headline subtitle.
    /// Mirrors `GrammarReviewViewModel.effectiveCount`.
    private var effectiveCount: Int { queueCount }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
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
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.72), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 14, x: 0, y: 8)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(AppColors.primaryBlue.opacity(0.14))
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(AppColors.primaryBlue)
            }
            .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 3) {
                Text("Review Today")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(AppColors.primaryBlueDark)
                Text(headlineSubtitle)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)

            if !isLoading && effectivePool != nil {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("~\(estimatedMinutes) min")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.primaryBlue)
                    Text("estimated")
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
        }
    }

    private var headlineSubtitle: String {
        if isLoading { return "Loading review queue…" }
        if errorMessage != nil { return "Could not load review queue." }
        guard let pool = effectivePool else {
            return "Nothing due. Open a note to add it to review."
        }
        return pool.homeCardSubtitle(count: effectiveCount)
    }

    // MARK: - Source row

    /// Single pill showing the pool the upcoming session will use plus the
    /// count of notes inside it. Replaces the old "Manual + Recent" dual
    /// pill row — sessions only ever draw from one pool now.
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
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func sourceTint(_ pool: GrammarReviewSourcePool) -> Color {
        switch pool {
        case .manual:         return AppColors.primaryBlue
        case .recentlyOpened: return CreateSetTheme.green.accent
        case .recentlyEdited: return Color(red: 0.85, green: 0.55, blue: 0.20)
        }
    }

    // MARK: - Start button

    private var startButton: some View {
        Button(action: onStart) {
            HStack(spacing: 8) {
                Image(systemName: "play.fill").font(.system(size: 13, weight: .bold))
                Text("Start Review").font(.system(size: 15, weight: .bold, design: .rounded))
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

    // MARK: - Empty state

    private var emptyRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(CreateSetTheme.green.accent)
                Text("You're all caught up.")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)
                Spacer(minLength: 0)
            }

            Text("Open a grammar note and tap \"Add to Review\" to schedule it here.")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.textSecondary.opacity(0.75))
                .lineSpacing(2)
        }
    }

    // MARK: - Loading / Error

    private var loadingRow: some View {
        HStack(spacing: 10) {
            ProgressView().tint(AppColors.primaryBlue).scaleEffect(0.85)
            Text("Loading…")
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
                Text("Retry")
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

    // MARK: - Background

    private var cardBackground: some View {
        ZStack(alignment: .topTrailing) {
            Color.white.opacity(0.92)
            Circle()
                .fill(AppColors.primaryBlue.opacity(0.08))
                .frame(width: 130, height: 130)
                .offset(x: 50, y: -55)
        }
    }
}

// MARK: - Previews

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
