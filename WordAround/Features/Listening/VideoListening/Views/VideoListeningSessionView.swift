import SwiftUI

struct VideoListeningSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @StateObject private var viewModel: VideoListeningSessionViewModel

    var onExitToResults: (() -> Void)? = nil
    var onExitToListening: (() -> Void)? = nil

    private let accent = ListeningTheme.videoListeningAccent
    private let accentDark = ListeningTheme.videoListeningDark

    init(
        setup: ListeningVideoSetup,
        video: ListeningVideoItem,
        sessionId: String = UUID().uuidString,
        restore: ListeningPersistedSession? = nil,
        onExitToResults: (() -> Void)? = nil,
        onExitToListening: (() -> Void)? = nil
    ) {
        _viewModel = StateObject(wrappedValue: VideoListeningSessionViewModel(
            setup: setup, video: video, sessionId: sessionId, restore: restore
        ))
        self.onExitToResults = onExitToResults
        self.onExitToListening = onExitToListening
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColors.appBackground.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: Layout.homeContentSpacing) {
                    ReadingSessionHeaderView(
                        title: viewModel.video.title,
                        subtitle: viewModel.metadataLine,
                        accent: accent,
                        accentDark: accentDark,
                        onBack: { dismiss() }
                    )

                    playerCard

                    if let errorMessage = viewModel.errorMessage {
                        ListeningInlineErrorView(message: errorMessage, accent: accent)
                    }

                    questionsArea

                    Spacer().frame(height: Layout.convSetupStartButtonHeight + 32)
                }
                .frame(maxWidth: Layout.convContentMaxWidth)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, Layout.homeHorizontalPadding)
                .padding(.top, Layout.homeTopSpacing)
                .padding(.bottom, Layout.homeBottomSafeSpacing)
            }

            if let title = viewModel.bottomButtonTitle {
                ListeningSetupStartButton(
                    title: title,
                    icon: viewModel.bottomButtonIcon,
                    accent: accent,
                    accentDark: accentDark,
                    action: { viewModel.handleBottomAction() }
                )
                .padding(.horizontal, Layout.homeHorizontalPadding)
                .padding(.bottom, Layout.homeBottomBarBottomPadding)
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .tint(accentDark)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.teardown() }
        .navigationDestination(isPresented: $viewModel.showResult) {
            ListeningResultView(
                result: viewModel.result ?? ListeningPlaceholderData.sampleResult,
                subtitle: viewModel.video.title,
                chips: [viewModel.setup.language.title, viewModel.setup.level.title, "Video Listening"],
                accent: accent,
                accentDark: accentDark,
                practiceAgainTitle: "Practice Again",
                backButtonTitle: "Back to Listening",
                onPracticeAgain: {
                    viewModel.showResult = false
                    onExitToResults?()
                },
                onBack: {
                    viewModel.showResult = false
                    onExitToListening?()
                    dismiss()
                }
            )
        }
    }

    // MARK: - Player

    private var playerCard: some View {
        VideoListeningPlayerView(
            video: viewModel.video,
            requiresExternalPlayback: viewModel.requiresExternalPlayback,
            isPlaying: viewModel.isPlaying,
            progress: viewModel.playbackProgress,
            currentTimeText: viewModel.currentTimeText,
            durationText: viewModel.durationText,
            isWatched: viewModel.isWatched,
            subtitlesEnabled: viewModel.subtitlesEnabled,
            subtitleLoadState: viewModel.subtitleLoadState,
            activeSubtitleText: viewModel.activeSubtitleText,
            selectedSubtitleText: viewModel.selectedSubtitleText,
            translatedSubtitleText: viewModel.translatedSubtitleText,
            isTranslating: viewModel.isTranslating,
            translationError: viewModel.translationError,
            canTranslate: viewModel.canTranslate,
            onPlayPause: { viewModel.togglePlayback() },
            onReplay: { viewModel.replayVideo() },
            onToggleSubtitles: { viewModel.toggleSubtitles() },
            onTapSubtitle: { viewModel.selectActiveSubtitle() },
            onTranslate: { viewModel.translateSelectedSubtitle() },
            onOpenExternal: { openVideo() },
            onMarkWatched: { viewModel.markVideoFinished() },
            accent: accent,
            accentDark: accentDark
        )
    }

    // MARK: - Questions area (state-driven)

    @ViewBuilder
    private var questionsArea: some View {
        if viewModel.supportsQuestions {
            switch viewModel.phase {
            case .watching:
                lockedQuestionsCard
            case .watched:
                questionsReadyCard
            case .answeringQuestions, .checkedAnswers, .completed:
                questionCardsList
            }
        } else {
            watchOnlyNote
        }
    }

    private var lockedQuestionsCard: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().fill(accent.opacity(0.12)).frame(width: 56, height: 56)
                Image(systemName: "lock.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(accent)
            }
            Text("Questions locked")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(accentDark)
            Text("Watch the video first, then check your understanding.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.94))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
    }

    private var questionsReadyCard: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().fill(accent.opacity(0.14)).frame(width: 56, height: 56)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(accent)
            }
            Text("Questions unlocked")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(accentDark)
            Text("Tap \"Start Questions\" below to check your understanding.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
            if viewModel.isGeneratingQuestions {
                ListeningLoadingRow(message: "Creating questions…", accent: accent)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.94))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
    }

    private var questionCardsList: some View {
        VStack(alignment: .leading, spacing: Layout.homeContentSpacing) {
            ListeningSetupSectionTitle("Questions", accentDark: accentDark)
            if viewModel.isGeneratingQuestions {
                ListeningLoadingRow(message: "Creating questions…", accent: accent)
            }
            ForEach(Array(viewModel.orderedQuestions.enumerated()), id: \.element.id) { index, question in
                questionBlock(question, index: index)
            }
        }
    }

    private var watchOnlyNote: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "eye.fill")
                .foregroundColor(accent)
            Text("This video has no transcript, so it's watch-only. Watch it, then finish to log your listening time.")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.94))
        )
    }

    private func openVideo() {
        guard let url = viewModel.watchURL else {
            viewModel.handleVideoOpenFailure()
            return
        }
        openURL(url) { accepted in
            if !accepted { viewModel.handleVideoOpenFailure() }
        }
    }

    @ViewBuilder
    private func questionBlock(_ question: ListeningQuestion, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ReadingQuestionCardView(
                title: "Question \(index + 1)",
                question: question.prompt,
                accent: accent,
                accentDark: accentDark
            )

            ReadingQuestionOptionsGrid {
                ForEach(Array(question.options.enumerated()), id: \.offset) { optionIndex, option in
                    let label = String(UnicodeScalar(65 + optionIndex)!)
                    let isSelected = viewModel.selectedAnswers[question.id] == optionIndex
                    let showState = viewModel.hasCheckedAnswers && isSelected
                    let isCorrect = optionIndex == question.correctIndex

                    ReadingAnswerOptionCard(
                        label: label,
                        text: option,
                        isSelected: isSelected,
                        accent: accent,
                        accentDark: accentDark
                    ) {
                        viewModel.selectAnswer(questionID: question.id, optionIndex: optionIndex)
                    }
                    .overlay(alignment: .trailing) {
                        if showState {
                            Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(isCorrect ? accent : Color(red: 0.95, green: 0.42, blue: 0.40))
                                .padding(.trailing, 14)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        VideoListeningSessionView(
            setup: ListeningVideoSetup(
                language: .english,
                level: .b1,
                length: .medium
            ),
            video: VideoListeningPreviewData.sampleVideos[0]
        )
    }
}
