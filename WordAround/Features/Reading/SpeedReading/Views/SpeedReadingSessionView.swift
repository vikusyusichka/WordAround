import SwiftUI

struct SpeedReadingSessionView: View {
    @ObservedObject var viewModel: SpeedReadingSessionViewModel
    var onExitToSetup: () -> Void
    var onExitToReading: () -> Void

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var accent: Color { viewModel.accent }
    private var accentDark: Color { viewModel.accentDark }

    private var contentMaxWidth: CGFloat {
        horizontalSizeClass == .regular ? Layout.convContentMaxWidth : .infinity
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColors.appBackground.ignoresSafeArea()

            content
        }
        .ignoresSafeArea(edges: .bottom)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onDisappear { viewModel.onDisappear() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.phase {
        case .loading, .countdown:
            ProgressView().tint(accent)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .reading, .questions, .results:
            readingLayout
        case .error(let message):
            errorState(message)
        }
    }

    private var readingLayout: some View {
        ZStack(alignment: .bottom) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: Layout.homeContentSpacing) {
                    header

                    SpeedReadingProgressCardView(
                        chunkProgressText: chunkProgressText,
                        overallProgress: viewModel.readingProgress,
                        currentWPM: viewModel.currentWPM,
                        targetWPM: viewModel.targetWPM,
                        paceStatus: viewModel.paceStatus,
                        timerHelperText: viewModel.configuration.timer.paceHelperText,
                        accent: accent,
                        accentDark: accentDark
                    )

                    switch viewModel.phase {
                    case .reading:  readingSection
                    case .questions: questionsSection
                    case .results:  resultSection
                    default: EmptyView()
                    }

                    Spacer().frame(height: Layout.convSetupStartButtonHeight + 24)
                }
                .frame(maxWidth: contentMaxWidth)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, Layout.homeHorizontalPadding)
                .padding(.top, Layout.homeTopSpacing)
                .padding(.bottom, Layout.homeBottomSafeSpacing)
            }

            if viewModel.phase != .results {
                bottomBar
                    .frame(maxWidth: contentMaxWidth)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, Layout.homeHorizontalPadding)
                    .padding(.bottom, Layout.homeBottomBarBottomPadding)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            Button {
                viewModel.onDisappear()
                onExitToReading()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: Layout.flashcardDetailTopButtonIconSize, weight: .bold))
                    .foregroundColor(accentDark)
                    .frame(width: Layout.flashcardDetailTopButtonSize, height: Layout.flashcardDetailTopButtonSize)
                    .background(Color.white.opacity(0.82))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.sessionTitle)
                    .font(.system(size: Layout.homeHeaderTitleSize, weight: .bold, design: .rounded))
                    .foregroundColor(accentDark)
                Text(headerSubtitle)
                    .font(.system(size: Layout.homeHeaderSubtitleSize, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.mutedText)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }

            Spacer()

            SpeedReadingTimerView(
                timerMode: viewModel.configuration.timer,
                displayText: viewModel.chunkTimerText,
                label: viewModel.chunkTimerLabel,
                progress: chunkProgressFraction,
                accent: accent
            )
        }
    }

    private var headerSubtitle: String {
        let pace = viewModel.paceLabel
        let length = viewModel.configuration.length.title
        return "\(pace) • \(length) • \(viewModel.timerText)"
    }

    private var chunkProgressText: String {
        guard !viewModel.chunks.isEmpty else { return "Chunk 0 / 0" }
        return "Chunk \(viewModel.currentChunkIndex + 1) / \(viewModel.chunks.count)"
    }

    private var chunkProgressFraction: Double {
        let total = viewModel.configuration.chunkSeconds
        guard total > 0 else { return 0 }
        let remaining = Double(viewModel.chunkTimeRemaining) / Double(total)
        return min(max(remaining, 0), 1)
    }

    private var readingSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            ReadingSessionTextCardView(
                bodyText: viewModel.currentChunkText,
                accent: accent
            )
            .scaleEffect(viewModel.fontScale)
            .animation(.easeInOut(duration: 0.18), value: viewModel.currentChunkIndex)

            controlRow
        }
    }

    private var controlRow: some View {
        HStack(spacing: 10) {
            secondaryButton(L10n.string("commonPrevious"), systemImage: "chevron.left") { viewModel.goPreviousChunk() }
                .disabled(viewModel.currentChunkIndex == 0)
                .opacity(viewModel.currentChunkIndex == 0 ? 0.45 : 1)
            secondaryButton(L10n.string(viewModel.isPaused ? "speedReadingResume" : "speedReadingPause"),
                            systemImage: viewModel.isPaused ? "play.fill" : "pause.fill") {
                viewModel.togglePause()
            }
            secondaryButton("A+", systemImage: "textformat.size.larger") { viewModel.increaseFont() }
            secondaryButton("A−", systemImage: "textformat.size.smaller") { viewModel.decreaseFont() }
        }
    }

    private func secondaryButton(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .labelStyle(.titleAndIcon)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(accentDark)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(accent.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var questionsSection: some View {
        if let question = viewModel.currentQuestion {
            VStack(alignment: .leading, spacing: 10) {
                Text(viewModel.questionProgressText)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(accent)
                ReadingQuestionSectionView(
                    question: question,
                    showVocabularyHints: false,
                    selectedAnswer: viewModel.selectedAnswer,
                    accent: accent,
                    accentDark: accentDark,
                    onSelect: { viewModel.selectAnswer($0) }
                )
            }
        } else {
            Text(L10n.string("speedReadingWrapping"))
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(20)
        }
    }

    @ViewBuilder
    private var resultSection: some View {
        if let result = viewModel.result {
            SpeedReadingResultView(
                result: result,
                configuration: viewModel.configuration,
                accent: accent,
                accentDark: accentDark,
                onTryAgain: {
                    viewModel.onDisappear()
                    onExitToSetup()
                },
                onBackToLibrary: {
                    viewModel.onDisappear()
                    onExitToReading()
                }
            )
        } else {
            ProgressView().tint(accent)
                .frame(maxWidth: .infinity)
                .padding(40)
        }
    }

    @ViewBuilder
    private var bottomBar: some View {
        switch viewModel.phase {
        case .reading:
            ReadingPrimaryButton(
                title: viewModel.isLastChunk ? (viewModel.hasQuestions ? L10n.string("readingStartQuestions") : L10n.string("commonFinish")) : L10n.string("speedReadingNextChunk"),
                icon: viewModel.isLastChunk ? "checkmark" : "arrow.right",
                accent: accent,
                accentDark: accentDark,
                action: { viewModel.advanceChunk() }
            )
        case .questions:
            ReadingPrimaryButton(
                title: viewModel.isLastQuestion ? L10n.string("commonFinish") : L10n.string("commonNext"),
                icon: viewModel.isLastQuestion ? "checkmark" : "arrow.right",
                accent: accent,
                accentDark: accentDark
            ) {
                guard viewModel.selectedAnswer != nil else { return }
                if viewModel.isLastQuestion {
                    Task { await viewModel.submitAnswers() }
                } else {
                    viewModel.goToNextQuestion()
                }
            }
            .opacity(viewModel.selectedAnswer == nil ? 0.55 : 1)
            .disabled(viewModel.selectedAnswer == nil)
        default:
            EmptyView()
        }
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(.orange)
            Text(L10n.string("speedReadingCantStart"))
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(accentDark)
            Text(message)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            Spacer()
            ReadingPrimaryButton(
                title: L10n.string("commonTryAgain"),
                icon: "arrow.clockwise",
                accent: accent,
                accentDark: accentDark,
                action: { Task { await viewModel.retry() } }
            )
            .frame(maxWidth: contentMaxWidth)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, Layout.homeHorizontalPadding)
            Button(action: {
                viewModel.onDisappear()
                onExitToReading()
            }) {
                Text(L10n.string("readingBackToLibrary"))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(accentDark)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(accent.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous))
            }
            .buttonStyle(.plain)
            .frame(maxWidth: contentMaxWidth)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, Layout.homeHorizontalPadding)
            .padding(.bottom, Layout.homeBottomBarBottomPadding)
        }
    }
}

#Preview {
    NavigationStack {
        SpeedReadingSessionView(
            viewModel: SpeedReadingSessionViewModel(
                setup: ReadingSetupViewModel(config: .speedReading).makeSessionSetup(),
                storage: MockReadingStorageService(),
                generation: MockSpeedReadingGenerationService(),
                currentUserId: { "preview-user" }
            ),
            onExitToSetup: {},
            onExitToReading: {}
        )
    }
}
