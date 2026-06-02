import SwiftUI

struct ImportVideoSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ImportVideoSessionViewModel

    var onExitToSetup: (() -> Void)? = nil
    var onExitToListening: (() -> Void)? = nil

    private let accent = ListeningTheme.importVideoAccent
    private let accentDark = ListeningTheme.importVideoDark

    init(
        setup: ListeningVideoImportSetup,
        transcription: ListeningTranscriptionResponse,
        sessionId: String = UUID().uuidString,
        onExitToSetup: (() -> Void)? = nil,
        onExitToListening: (() -> Void)? = nil
    ) {
        _viewModel = StateObject(wrappedValue: ImportVideoSessionViewModel(
            setup: setup, transcription: transcription, sessionId: sessionId
        ))
        self.onExitToSetup = onExitToSetup
        self.onExitToListening = onExitToListening
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColors.appBackground.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: Layout.homeContentSpacing) {
                    ReadingSessionHeaderView(
                        title: viewModel.setup.fileName,
                        subtitle: viewModel.metadataLine,
                        accent: accent,
                        accentDark: accentDark,
                        onBack: { dismiss() }
                    )

                    ImportVideoPlayerView(
                        player: viewModel.player,
                        subtitlesEnabled: viewModel.subtitlesEnabled,
                        hasSubtitles: viewModel.hasSubtitles,
                        activeSubtitleText: viewModel.activeSubtitleText,
                        onToggleSubtitles: { viewModel.toggleSubtitles() },
                        onTapWord: { viewModel.selectWord($0) },
                        accent: accent,
                        accentDark: accentDark
                    )

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
        .sheet(isPresented: $viewModel.showTranslationSheet) {
            ImportVideoWordTranslationSheet(viewModel: viewModel)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.hidden)
        }
        .navigationDestination(isPresented: $viewModel.showResult) {
            ListeningResultView(
                result: viewModel.result ?? ListeningPlaceholderData.sampleResult,
                subtitle: viewModel.setup.fileName,
                chips: [viewModel.setup.language.title, viewModel.setup.level.title, "Import Video"],
                accent: accent,
                accentDark: accentDark,
                practiceAgainTitle: "Practice Again",
                backButtonTitle: "Back to Listening",
                secondaryCTATitle: "Start Shadowing",
                secondaryCTAIcon: "waveform.and.mic",
                onSecondaryCTA: { viewModel.startShadowing() },
                onPracticeAgain: {
                    viewModel.showResult = false
                    onExitToSetup?()
                },
                onBack: {
                    viewModel.showResult = false
                    onExitToListening?()
                    dismiss()
                }
            )
            .navigationDestination(isPresented: $viewModel.showShadowing) {
                let payload = viewModel.makeShadowingPayload()
                ShadowingView(
                    setup: payload.speakingSetup,
                    category: .fromVideo,
                    preloadedPhrases: payload.makeShadowingPhrases()
                )
            }
        }
    }


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
        infoCard(icon: "lock.fill",
                 title: "Questions locked",
                 message: "Watch the full video first, then check your understanding.")
    }

    private var questionsReadyCard: some View {
        VStack(spacing: 12) {
            infoCardContent(icon: "checkmark.seal.fill",
                            title: "Questions unlocked",
                            message: "Tap \"Start Questions\" below to check your understanding.")
            if viewModel.isGeneratingQuestions {
                ListeningLoadingRow(message: "Creating questions…", accent: accent)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(cardBackground)
    }

    private var questionCardsList: some View {
        VStack(alignment: .leading, spacing: Layout.homeContentSpacing) {
            ListeningSetupSectionTitle("Questions", accentDark: accentDark)
            if viewModel.isGeneratingQuestions {
                ListeningLoadingRow(message: "Creating questions…", accent: accent)
            }
            ForEach(Array(viewModel.questions.enumerated()), id: \.element.id) { index, question in
                questionBlock(question, index: index)
            }
            if let error = viewModel.wordTranslationError, viewModel.phase == .answeringQuestions {
                ListeningInlineErrorView(message: error, accent: accent)
            }
        }
    }

    private var watchOnlyNote: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "captions.bubble").foregroundColor(accent)
            Text("No questions for this session. Watch the video and tap subtitle words to translate and save them.")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous).fill(Color.white.opacity(0.94)))
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
                        label: label, text: option, isSelected: isSelected,
                        accent: accent, accentDark: accentDark
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


    private func infoCard(icon: String, title: String, message: String) -> some View {
        infoCardContent(icon: icon, title: title, message: message)
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(cardBackground)
    }

    private func infoCardContent(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().fill(accent.opacity(0.12)).frame(width: 56, height: 56)
                Image(systemName: icon).font(.system(size: 22, weight: .semibold)).foregroundColor(accent)
            }
            Text(title).font(.system(size: 17, weight: .bold, design: .rounded)).foregroundColor(accentDark)
            Text(message).font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.textSecondary).multilineTextAlignment(.center)
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
            .fill(Color.white.opacity(0.94))
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}
