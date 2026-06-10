import SwiftUI

struct ListenFromTextSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ListenFromTextSessionViewModel

    var onExitToSetup: (() -> Void)? = nil
    var onExitToListening: (() -> Void)? = nil

    private let accent = ListeningTheme.listenFromTextAccent
    private let accentDark = ListeningTheme.listenFromTextDark

    init(
        setup: ListeningSessionSetup,
        restore: ListeningPersistedSession? = nil,
        onExitToSetup: (() -> Void)? = nil,
        onExitToListening: (() -> Void)? = nil
    ) {
        _viewModel = StateObject(wrappedValue: ListenFromTextSessionViewModel(setup: setup, restore: restore))
        self.onExitToSetup = onExitToSetup
        self.onExitToListening = onExitToListening
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColors.appBackground.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: Layout.homeContentSpacing) {
                    ReadingSessionHeaderView(
                        title: viewModel.setup.title,
                        subtitle: viewModel.setup.metadataLine,
                        trailingText: viewModel.timerText,
                        accent: accent,
                        accentDark: accentDark,
                        onBack: { dismiss() }
                    )

                    ListeningAudioPlayerCard(
                        isPlaying: .constant(viewModel.isPlaying),
                        progress: viewModel.progress,
                        currentTimeText: viewModel.currentTimeText,
                        durationText: viewModel.durationText,
                        speedLabel: viewModel.setup.voiceSpeed.rawValue,
                        accent: accent,
                        accentDark: accentDark,
                        onPlayPause: { viewModel.togglePlayback() },
                        onReplay: { viewModel.replay() }
                    )

                    if let errorMessage = viewModel.errorMessage {
                        ListeningInlineErrorView(message: errorMessage, accent: accent)
                    }

                    if viewModel.setup.showTextWhileListening {
                        ReadingSessionTextCardView(
                            title: "Transcript",
                            bodyText: viewModel.setup.text,
                            highlightColor: accent,
                            accent: accent,
                            accentDark: accentDark
                        )
                    }

                    if viewModel.setup.addQuestions {
                        ListeningSetupSectionTitle(L10n.string("listenSectionQuestions"), accentDark: accentDark)
                        if viewModel.isGeneratingQuestions {
                            ListeningLoadingRow(message: "Creating questions…", accent: accent)
                        }
                        ForEach(Array(viewModel.questions.enumerated()), id: \.element.id) { index, question in
                            questionBlock(question, index: index)
                        }
                    }

                    Spacer().frame(height: Layout.convSetupStartButtonHeight + 32)
                }
                .frame(maxWidth: Layout.convContentMaxWidth)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, Layout.homeHorizontalPadding)
                .padding(.top, Layout.homeTopSpacing)
                .padding(.bottom, Layout.homeBottomSafeSpacing)
            }

            ListeningSetupStartButton(
                title: viewModel.bottomButtonTitle,
                icon: viewModel.bottomButtonIcon,
                accent: accent,
                accentDark: accentDark,
                action: viewModel.handleBottomAction
            )
            .padding(.horizontal, Layout.homeHorizontalPadding)
            .padding(.bottom, Layout.homeBottomBarBottomPadding)
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
                subtitle: viewModel.setup.title,
                chips: [viewModel.setup.language.title, viewModel.setup.level.title, "Listen from Text"],
                accent: accent,
                accentDark: accentDark,
                practiceAgainTitle: "Practice Again",
                backButtonTitle: "Back to Listening",
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
        ListenFromTextSessionView(
            setup: ListeningSessionSetup(
                modeID: "listen-from-text",
                language: .english,
                level: .b1,
                title: ListeningPlaceholderData.sampleTitle,
                text: ListeningPlaceholderData.sampleText,
                voiceSpeed: .normal,
                voiceType: .default,
                showTextWhileListening: true,
                addQuestions: true,
                questionCount: 5,
                questionTypes: Set(ListeningQuestionType.allCases),
                estimatedMinutes: 3
            )
        )
    }
}
