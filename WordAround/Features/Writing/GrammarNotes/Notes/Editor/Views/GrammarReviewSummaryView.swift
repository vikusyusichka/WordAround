import SwiftUI

struct GrammarReviewSummaryView: View {
    let summary: GrammarReviewSummary
    let isLoading: Bool
    let errorMessage: String?
    let recommendations: [GrammarReviewRecommendation]
    let isAddingRecommendation: Bool
    let onStart: () -> Void
    let onRetry: () -> Void
    let onReviewRecommendation: (GrammarReviewRecommendation) -> Void
    let onAddRecommendation: (GrammarReviewRecommendation) -> Void

    init(
        summary: GrammarReviewSummary,
        isLoading: Bool,
        errorMessage: String?,
        recommendations: [GrammarReviewRecommendation] = [],
        isAddingRecommendation: Bool = false,
        onStart: @escaping () -> Void,
        onRetry: @escaping () -> Void = {},
        onReviewRecommendation: @escaping (GrammarReviewRecommendation) -> Void = { _ in },
        onAddRecommendation: @escaping (GrammarReviewRecommendation) -> Void = { _ in }
    ) {
        self.summary = summary
        self.isLoading = isLoading
        self.errorMessage = errorMessage
        self.recommendations = recommendations
        self.isAddingRecommendation = isAddingRecommendation
        self.onStart = onStart
        self.onRetry = onRetry
        self.onReviewRecommendation = onReviewRecommendation
        self.onAddRecommendation = onAddRecommendation
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            if isLoading {
                loadingRow
            } else if let errorMessage, !errorMessage.isEmpty {
                errorRow(errorMessage)
            } else if summary.dueTotal == 0 {
                emptyRow
                if !recommendations.isEmpty {
                    recommendationsSection
                }
            } else {
                countsRow
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
        }
    }

    private var headlineSubtitle: String {
        if isLoading { return "Loading review queue…" }
        if errorMessage != nil { return "Could not load review queue." }
        switch summary.dueTotal {
        case 0:
            return recommendations.isEmpty
                ? "Nothing due today. You're caught up."
                : "Nothing due today. Here are notes worth revisiting."
        case 1:  return "1 item ready for review."
        default: return "\(summary.dueTotal) items ready for review."
        }
    }

    private var countsRow: some View {
        HStack(spacing: 8) {
            countPill(value: summary.dueNotes, label: "Notes", systemImage: GrammarReviewSourceType.note.systemImage, tint: AppColors.primaryBlue)
            countPill(value: summary.dueMistakes, label: "Mistakes", systemImage: GrammarReviewSourceType.mistake.systemImage, tint: CreateSetTheme.red.accent)
            countPill(value: summary.dueQuizzes, label: "Quizzes", systemImage: GrammarReviewSourceType.quiz.systemImage, tint: CreateSetTheme.purple.accent)
        }
    }

    private func countPill(value: Int, label: String, systemImage: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 5) {
                Image(systemName: systemImage).font(.system(size: 10, weight: .bold))
                Text(label)
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
            .foregroundStyle(tint)

            Text("\(value)")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(AppColors.primaryBlueDark)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(tint.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

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
        .disabled(summary.dueTotal == 0)
    }

    private var emptyRow: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(CreateSetTheme.green.accent)
            Text("Nothing due today.")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
            Spacer(minLength: 0)
        }
    }

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Recommended to Review")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(AppColors.primaryBlueDark)
                Text("You're fully caught up. Here are some notes worth revisiting.")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)
            }

            ForEach(recommendations) { item in
                recommendationCard(item)
            }
        }
        .padding(.top, 4)
    }

    private func recommendationCard(_ item: GrammarReviewRecommendation) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title.isEmpty ? "Untitled note" : item.title)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.primaryBlueDark)
                        .lineLimit(1)

                    if !item.previewText.isEmpty {
                        Text(item.previewText)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppColors.textSecondary)
                            .lineLimit(2)
                    }
                }

                Spacer(minLength: 0)

                if !item.languageName.isEmpty {
                    Text(item.languageName)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.primaryBlue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppColors.primaryBlue.opacity(0.10))
                        .clipShape(Capsule())
                }
            }

            HStack(spacing: 8) {
                Text(item.label)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)

                Spacer(minLength: 0)

                Button {
                    onReviewRecommendation(item)
                } label: {
                    Text("Review Now")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 10)
                        .frame(height: 30)
                        .background(AppColors.primaryBlue)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Button {
                    onAddRecommendation(item)
                } label: {
                    Text("Add to Review")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.primaryBlue)
                        .padding(.horizontal, 10)
                        .frame(height: 30)
                        .background(AppColors.primaryBlue.opacity(0.10))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(isAddingRecommendation)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.66))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

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

#Preview("With items") {
    GrammarReviewSummaryView(
        summary: GrammarReviewSummary(dueTotal: 7, dueNotes: 3, dueMistakes: 2, dueQuizzes: 2),
        isLoading: false,
        errorMessage: nil,
        onStart: {}
    )
    .padding()
    .background(AppColors.appBackground)
}

#Preview("Empty with recommendations") {
    GrammarReviewSummaryView(
        summary: .empty,
        isLoading: false,
        errorMessage: nil,
        recommendations: [
            GrammarReviewRecommendation(
                id: "preview-topic_preview-note",
                ownerUID: "preview-user",
                topicId: "preview-topic",
                noteId: "preview-note",
                title: "Ser vs Estar",
                previewText: "Use ser for identity and estar for states.",
                languageCode: "es",
                languageName: "Spanish",
                lastOpenedAt: Date().addingTimeInterval(-3600),
                lastEditedAt: Date().addingTimeInterval(-7200)
            )
        ],
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
        onStart: {}
    )
    .padding()
    .background(AppColors.appBackground)
}
