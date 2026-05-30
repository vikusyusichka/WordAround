import SwiftUI

struct FreeSpeakingView: View {
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel: FreeSpeakingViewModel

    @State private var isPaused = false
    @State private var showResult = false

    /// Pops the session (and the result pushed on top of it) back to the Free
    /// Speaking setup screen. Owned by the setup screen. `nil` in previews.
    private let onExitToSetup: (() -> Void)?

    /// Pops the whole Free Speaking flow (setup + session + result) back to
    /// the main Speaking screen. Supplied by `SpeakingView` via the setup
    /// screen. `nil` in previews.
    private let onExitToSpeaking: (() -> Void)?

    init(
        setup: SpeakingConversationSetup,
        onExitToSetup: (() -> Void)? = nil,
        onExitToSpeaking: (() -> Void)? = nil
    ) {
        _viewModel = StateObject(wrappedValue: FreeSpeakingViewModel(setup: setup))
        self.onExitToSetup = onExitToSetup
        self.onExitToSpeaking = onExitToSpeaking
    }

    private var isRecording: Bool { viewModel.state == .listening }

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColors.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, Layout.homeHorizontalPadding)
                    .padding(.top, Layout.homeTopSpacing)
                    .padding(.bottom, 14)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        topicCard
                            .padding(.horizontal, Layout.homeHorizontalPadding)
                            .padding(.bottom, 20)

                        if viewModel.usedFallbackTopic {
                            fallbackBanner("Could not generate topic. Using fallback topic.")
                                .padding(.horizontal, Layout.homeHorizontalPadding)
                                .padding(.bottom, 14)
                        }

                        if viewModel.permissionsDenied {
                            fallbackBanner("Microphone and speech recognition access are required for Free Speaking.")
                                .padding(.horizontal, Layout.homeHorizontalPadding)
                                .padding(.bottom, 14)
                        } else if let error = viewModel.errorMessage, !error.isEmpty {
                            fallbackBanner(error)
                                .padding(.horizontal, Layout.homeHorizontalPadding)
                                .padding(.bottom, 14)
                        }

                        transcriptSection
                            .padding(.horizontal, Layout.homeHorizontalPadding)
                    }
                    .frame(maxWidth: Layout.convContentMaxWidth)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, Layout.convMicBarHeight + Layout.convMicBarBottomPadding + 60)
                }
            }

            FreeSpeakingMicBarView(
                isRecording: isRecording,
                isPaused: isPaused,
                onEnd: handleEnd,
                onMicTap: handleMicTap,
                onPause: handlePause
            )
            .padding(.horizontal, Layout.homeBottomBarHorizontalPadding)
            .padding(.bottom, Layout.homeBottomBarBottomPadding)
        }
        .ignoresSafeArea(edges: .bottom)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .task { viewModel.startSession() }
        .onAppear {
            viewModel.onTimerFinished = {
                showResult = true
            }
        }
        .onDisappear { viewModel.endSession() }
        .sheet(isPresented: $viewModel.showTopicPicker) {
            ConversationTopicPickerSheetView(viewModel: viewModel)
        }
        .navigationDestination(isPresented: $showResult) {
            ConversationResultView(
                viewModel: viewModel,
                completionTitle: "Free Speaking completed",
                onPracticeAgain: {
                    // Return to the Free Speaking setup screen for a fresh run.
                    // The setup screen owns the binding, so this pops the
                    // session AND the result in one step.
                    viewModel.endSession()
                    if let onExitToSetup {
                        onExitToSetup()
                    } else {
                        showResult = false
                        dismiss()
                    }
                },
                onBackToSpeaking: {
                    // Leave the whole flow back to the main Speaking screen.
                    viewModel.endSession()
                    if let onExitToSpeaking {
                        onExitToSpeaking()
                    } else {
                        showResult = false
                        dismiss()
                    }
                }
            )
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Free Speaking")
                    .font(.system(
                        size: Layout.homeHeaderTitleSize,
                        weight: .bold,
                        design: .rounded
                    ))
                    .foregroundColor(AppColors.primaryBlueDark)

                Text("Speak freely about a topic and get feedback.")
                    .font(.system(
                        size: Layout.homeHeaderSubtitleSize,
                        weight: .medium,
                        design: .rounded
                    ))
                    .foregroundColor(AppColors.mutedText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, Layout.flashcardDetailTopButtonSize + 10)
            .padding(.trailing, 124)

            HStack {
                Button { handleBack() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(
                            size: Layout.flashcardDetailTopButtonIconSize,
                            weight: .bold
                        ))
                        .foregroundColor(AppColors.primaryBlueDark)
                        .frame(
                            width: Layout.flashcardDetailTopButtonSize,
                            height: Layout.flashcardDetailTopButtonSize
                        )
                        .background(Color.white.opacity(0.82))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(viewModel.setup.language.shortTitle) · \(viewModel.setup.level.title)")
                        .font(.system(
                            size: Layout.convScenarioChipTextSize + 1,
                            weight: .bold,
                            design: .rounded
                        ))
                        .foregroundColor(AppColors.greenAccent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(AppColors.greenAccent.opacity(0.09))
                        .clipShape(Capsule())

                    timerChip
                }
            }
        }
    }

    private var timerChip: some View {
        let isWarning = viewModel.isTimeRunningOut
        let tint: Color = isWarning ? AppColors.foodAccent : AppColors.textSecondary

        return HStack(spacing: 5) {
            Image(systemName: "timer")
                .font(.system(size: 11, weight: .semibold))
            Text("\(viewModel.formattedRemainingTime) left")
                .font(.system(size: 12, weight: .bold, design: .rounded))
        }
        .foregroundColor(tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(tint.opacity(0.10))
        .clipShape(Capsule())
        .animation(.easeInOut(duration: 0.18), value: isWarning)
    }

    // MARK: - Topic Card

    @ViewBuilder
    private var topicCard: some View {
        if viewModel.isGeneratingTopic && viewModel.context == nil {
            FreeSpeakingTopicCardView(
                title: "Generating topic…",
                description: "Picking something that fits your level.",
                chips: [viewModel.setup.level.title, viewModel.setup.length.title]
            )
        } else {
            FreeSpeakingTopicCardView(
                title: viewModel.context?.title ?? "Choose a topic",
                description: viewModel.context?.description ?? "Tap Edit to select or generate a topic.",
                chips: topicChips,
                onEdit: { viewModel.showTopicPicker = true }
            )
        }
    }

    private var topicChips: [String] {
        var chips = [viewModel.setup.level.title, viewModel.setup.length.title]
        if let category = viewModel.context?.category { chips.append(category) }
        return chips
    }

    // MARK: - Transcript Section

    private var transcriptSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Transcript")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.primaryBlueDark)

            if viewModel.messages.isEmpty && viewModel.partialTranscript.isEmpty {
                emptyTranscriptState
            } else {
                liveTranscriptContent
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.easeInOut(duration: 0.22), value: viewModel.messages.count)
    }

    private var liveTranscriptContent: some View {
        VStack(spacing: Layout.convMessageGroupSpacing) {
            ForEach(viewModel.messages) { msg in
                FreeSpeakingTranscriptCardView(text: msg.text)
            }

            if !viewModel.partialTranscript.isEmpty {
                FreeSpeakingTranscriptCardView(
                    text: viewModel.partialTranscript,
                    isPlaceholder: true
                )
            }
        }
    }

    private var emptyTranscriptState: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppColors.greenAccent.opacity(0.10))
                    .frame(width: 54, height: 54)
                Image(systemName: "waveform")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(AppColors.greenAccent)
            }
            .padding(.top, 16)

            Text("Start speaking")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.primaryBlueDark)

            Text("Your transcript will appear here while you speak.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .padding(.horizontal, 8)
                .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.72))
                .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
        )
    }

    // MARK: - Fallback Banner

    private func fallbackBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppColors.foodAccent)
            Text(message)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.primaryBlueDark)
                .lineLimit(2)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.96))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 3)
        )
    }

    // MARK: - Actions

    private func handleMicTap() {
        if isRecording {
            viewModel.stopListening()
            isPaused = false
        } else {
            isPaused = false
            Task { await viewModel.startListening() }
        }
    }

    private func handlePause() {
        if isRecording {
            isPaused = true
            viewModel.stopListening()
        } else if isPaused {
            isPaused = false
            Task { await viewModel.startListening() }
        }
    }

    private func handleEnd() {
        viewModel.endSession()
        showResult = true
    }

    private func handleBack() {
        viewModel.endSession()
        dismiss()
    }
}

#Preview {
    NavigationStack {
        FreeSpeakingView(
            setup: SpeakingConversationSetup(
                language: .english,
                level: .a2,
                scenario: nil,
                length: .short
            )
        )
    }
}
