import SwiftUI

struct ImportAudioSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ImportAudioSessionViewModel

    var onExitToSetup: (() -> Void)? = nil
    var onExitToListening: (() -> Void)? = nil

    private let accent = ListeningTheme.importAudioAccent
    private let accentDark = ListeningTheme.importAudioDark

    init(
        setup: ListeningAudioImportSetup,
        sessionId: String = UUID().uuidString,
        questions: [ListeningQuestion] = [],
        transcript: String = "",
        restore: ListeningPersistedSession? = nil,
        onExitToSetup: (() -> Void)? = nil,
        onExitToListening: (() -> Void)? = nil
    ) {
        _viewModel = StateObject(wrappedValue: ImportAudioSessionViewModel(
            setup: setup,
            sessionId: sessionId,
            questions: questions,
            transcript: transcript,
            restore: restore
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
                        speedLabel: "1.0x",
                        accent: accent,
                        accentDark: accentDark,
                        onPlayPause: { viewModel.togglePlayback() },
                        onReplay: { viewModel.replay() }
                    )

                    if let errorMessage = viewModel.errorMessage {
                        ListeningInlineErrorView(message: errorMessage, accent: accent)
                    }

                    hiddenTranscriptNote

                    if viewModel.setup.addQuestions {
                        ListeningSetupSectionTitle("Questions", accentDark: accentDark)
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
                subtitle: viewModel.setup.fileName,
                chips: [viewModel.setup.language.title, viewModel.setup.level.title, "Import Audio"],
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

    private var hiddenTranscriptNote: some View {
        HStack(spacing: 10) {
            Image(systemName: "eye.slash.fill")
                .foregroundColor(accent)
            Text("Transcript is hidden to keep this a real listening exercise.")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.94))
        )
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
        ImportAudioSessionView(
            setup: ListeningAudioImportSetup(
                language: .english,
                level: .b1,
                fileName: "podcast.mp3",
                storedFileName: "preview.mp3",
                durationText: "4:32",
                durationSeconds: 272,
                fileSizeText: "8.4 MB",
                addQuestions: true,
                questionCount: 5,
                questionTypes: Set(ListeningQuestionType.allCases)
            ),
            questions: ListeningPlaceholderData.sampleQuestions
        )
    }
}
