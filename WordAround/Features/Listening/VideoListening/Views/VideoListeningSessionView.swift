import SwiftUI

struct VideoListeningSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: VideoListeningSessionViewModel

    var onExitToResults: (() -> Void)? = nil
    var onExitToListening: (() -> Void)? = nil

    private let accent = ListeningTheme.videoListeningAccent
    private let accentDark = ListeningTheme.videoListeningDark

    init(
        setup: ListeningVideoSetup,
        video: ListeningVideoItem,
        onExitToResults: (() -> Void)? = nil,
        onExitToListening: (() -> Void)? = nil
    ) {
        _viewModel = StateObject(wrappedValue: VideoListeningSessionViewModel(setup: setup, video: video))
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

                    videoPlayerCard

                    if viewModel.video.hasCaptions {
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
                title: "Finish Practice",
                icon: "flag.checkered",
                accent: accent,
                accentDark: accentDark,
                action: { viewModel.showResult = true }
            )
            .padding(.horizontal, Layout.homeHorizontalPadding)
            .padding(.bottom, Layout.homeBottomBarBottomPadding)
        }
        .ignoresSafeArea(edges: .bottom)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $viewModel.showResult) {
            ListeningResultView(
                result: ListeningPlaceholderData.sampleResult,
                subtitle: "Listening Practice",
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

    private var videoPlayerCard: some View {
        VStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(accent.opacity(0.10))
                    .frame(height: 200)

                VStack(spacing: 12) {
                    Image(systemName: "play.rectangle.fill")
                        .font(.system(size: 48, weight: .semibold))
                        .foregroundColor(accent)

                    Button {} label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.up.right.square")
                            Text("Open in YouTube")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(accentDark)
                        .padding(.horizontal, 16)
                        .frame(height: 40)
                        .background(accent.opacity(0.12))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }

            Text(viewModel.video.channel)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.94))
                .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 4)
        )
    }

    @ViewBuilder
    private func questionBlock(_ question: ListeningQuestion, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ReadingQuestionCardView(
                title: "Question \(index + 1)",
                question: question.prompt,
                accent: accent
            )

            ReadingQuestionOptionsGrid {
                ForEach(Array(question.options.enumerated()), id: \.offset) { optionIndex, option in
                    let label = String(UnicodeScalar(65 + optionIndex)!)
                    ReadingAnswerOptionCard(
                        label: label,
                        text: option,
                        isSelected: viewModel.selectedAnswers[question.id] == optionIndex,
                        accent: accent,
                        accentDark: accentDark
                    ) {
                        viewModel.selectAnswer(questionID: question.id, optionIndex: optionIndex)
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
                topic: "Travel",
                length: .medium
            ),
            video: VideoListeningPreviewData.sampleVideos[0]
        )
    }
}
