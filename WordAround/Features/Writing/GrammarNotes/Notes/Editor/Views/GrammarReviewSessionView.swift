import SwiftUI

/// Sheet-hosted review loop. Walks the user through each due item and
/// records their rating. When the last item is rated, switches to the
/// `GrammarReviewCompletionView` summary.
///
/// Owns NO Firebase calls — everything is delegated to the shared
/// `GrammarReviewViewModel`. The host injects the VM so the same one
/// powers the home summary card too.
struct GrammarReviewSessionView: View {
    @ObservedObject var viewModel: GrammarReviewViewModel
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            AppColors.appBackground.ignoresSafeArea()

            if viewModel.sessionFinished {
                GrammarReviewCompletionView(
                    reviewedCount: viewModel.ratedCount,
                    hardCount: viewModel.ratedHardCount,
                    forgotCount: viewModel.ratedForgotCount,
                    onDone: onDismiss
                )
            } else if viewModel.isLoadingSession {
                loadingState
            } else if let error = viewModel.sessionError {
                errorState(error)
            } else if let item = viewModel.currentItem {
                content(for: item)
            } else {
                // Defensive fallback — shouldn't normally happen because
                // empty fetches flip `sessionFinished = true`.
                GrammarReviewCompletionView(
                    reviewedCount: 0,
                    hardCount: 0,
                    forgotCount: 0,
                    onDone: onDismiss
                )
            }
        }
    }

    // MARK: - Active card

    @ViewBuilder
    private func content(for item: GrammarReviewItem) -> some View {
        VStack(spacing: 18) {
            header
            progressBar
            cardView(item)
            ratingRow
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 24)
    }

    private var header: some View {
        HStack {
            Button(action: onDismiss) {
                Text("Close")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.primaryBlueDark)
                    .padding(.horizontal, 14)
                    .frame(height: 36)
                    .background(Color.white.opacity(0.92))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Review")
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(AppColors.primaryBlueDark)

            Spacer()

            Button {
                viewModel.skipCurrent()
            } label: {
                Text("Skip")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.primaryBlue)
                    .padding(.horizontal, 14)
                    .frame(height: 36)
                    .background(AppColors.primaryBlue.opacity(0.10))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isRating)
        }
    }

    private var progressBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Item \(min(viewModel.currentIndex + 1, viewModel.totalItems)) of \(viewModel.totalItems)")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)
                    .textCase(.uppercase)
                    .tracking(0.6)
                Spacer()
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(AppColors.primaryBlue.opacity(0.10))
                    Capsule()
                        .fill(AppColors.primaryBlue)
                        .frame(width: max(8, proxy.size.width * viewModel.progressFraction))
                }
            }
            .frame(height: 6)
        }
    }

    private func cardView(_ item: GrammarReviewItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                badge(text: item.sourceType.title, systemImage: item.sourceType.systemImage, tint: tint(for: item.sourceType))
                if !item.languageName.isEmpty {
                    badge(text: item.languageName, systemImage: "globe", tint: AppColors.textSecondary)
                }
                if item.priority == .high {
                    badge(text: "High", systemImage: item.priority.systemImage, tint: CreateSetTheme.red.accent)
                }
                Spacer(minLength: 0)
            }

            Text(item.title)
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(AppColors.primaryBlueDark)
                .fixedSize(horizontal: false, vertical: true)

            if !item.previewText.isEmpty {
                Text(item.previewText)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            metaFooter(item)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.72), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 14, x: 0, y: 8)
    }

    private func metaFooter(_ item: GrammarReviewItem) -> some View {
        HStack(spacing: 10) {
            if item.reviewCount > 0 {
                Label("\(item.reviewCount) reviews", systemImage: "clock")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)
            }
            if item.correctStreak > 0 {
                Label("Streak \(item.correctStreak)", systemImage: "flame.fill")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(CreateSetTheme.green.accent)
            }
            Spacer(minLength: 0)
        }
    }

    private func badge(text: String, systemImage: String, tint: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: systemImage)
                .font(.system(size: 9, weight: .bold))
            Text(text)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .lineLimit(1)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(tint.opacity(0.12))
        .clipShape(Capsule())
    }

    private var ratingRow: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                ratingButton(.forgot, tint: CreateSetTheme.red.accent)
                ratingButton(.hard,   tint: Color(red: 0.85, green: 0.55, blue: 0.20))
            }
            HStack(spacing: 10) {
                ratingButton(.good, tint: AppColors.primaryBlue)
                ratingButton(.easy, tint: CreateSetTheme.green.accent)
            }
        }
        .opacity(viewModel.isRating ? 0.65 : 1)
        .animation(.easeInOut(duration: 0.18), value: viewModel.isRating)
    }

    private func ratingButton(_ result: GrammarReviewResult, tint: Color) -> some View {
        Button {
            Task { await viewModel.rate(result) }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: result.systemImage)
                    .font(.system(size: 13, weight: .bold))
                Text(result.title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
            }
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(tint)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isRating)
    }

    // MARK: - States

    private var loadingState: some View {
        VStack(spacing: 12) {
            ProgressView().tint(AppColors.primaryBlue).scaleEffect(1.1)
            Text("Loading review queue…")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(CreateSetTheme.red.accent)
            Text(message)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button(action: onDismiss) {
                Text("Close")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 20)
                    .frame(height: 44)
                    .background(AppColors.primaryBlue)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Tint

    private func tint(for type: GrammarReviewSourceType) -> Color {
        switch type {
        case .note:    return AppColors.primaryBlue
        case .mistake: return CreateSetTheme.red.accent
        case .quiz:    return CreateSetTheme.purple.accent
        }
    }
}

// MARK: - Previews

private final class _PreviewReviewVM {
    @MainActor
    static func make(items: [GrammarReviewItem]) -> GrammarReviewViewModel {
        let vm = GrammarReviewViewModel(
            ownerUID: "preview",
            service: MockGrammarReviewService(items: items)
        )
        Task { await vm.startSession() }
        return vm
    }
}

#Preview("Active session") {
    GrammarReviewSessionView(
        viewModel: _PreviewReviewVM.make(items: [
            .preview(sourceType: .mistake, title: "I am agree with you", priority: .high),
            .preview(sourceType: .note,    title: "Ser vs Estar"),
            .preview(sourceType: .quiz,    title: "Quiz: Spanish A1", priority: .high)
        ]),
        onDismiss: {}
    )
}

#Preview("Empty queue") {
    GrammarReviewSessionView(
        viewModel: _PreviewReviewVM.make(items: []),
        onDismiss: {}
    )
}
