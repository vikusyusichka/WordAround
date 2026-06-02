import SwiftUI

struct DebateModeView: View {
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel: DebateModeViewModel
    @State private var showResult = false

    private let accent = DebateTheme.accent
    private let accentDark = DebateTheme.accentDark

    init(setup: SpeakingConversationSetup, side: DebateSide) {
        _viewModel = StateObject(wrappedValue: DebateModeViewModel(setup: setup, side: side))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColors.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, Layout.homeHorizontalPadding)
                    .padding(.top, Layout.homeTopSpacing)
                    .padding(.bottom, 14)

                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 16) {
                            DebateTopicCardView(
                                topicTitle: viewModel.session?.topic.title ?? "",
                                topicDescription: viewModel.session?.topic.description ?? "",
                                learnerSide: viewModel.learnerSide,
                                isLoading: viewModel.isGeneratingTopic
                            )

                            if !viewModel.rounds.isEmpty {
                                DebateProgressView(
                                    rounds: viewModel.rounds,
                                    currentIndex: viewModel.currentRoundIndex
                                )
                            }

                            if let round = viewModel.currentRound {
                                DebateRoundCardView(round: round)
                            }

                            messageList
                        }
                        .padding(.horizontal, Layout.homeHorizontalPadding)
                        .frame(maxWidth: Layout.convContentMaxWidth)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, Layout.convMicBarHeight + Layout.convMicBarBottomPadding + 60)
                    }
                    .onChange(of: viewModel.messages.count) { _, _ in scrollToBottom(proxy) }
                    .onChange(of: viewModel.partialTranscript) { _, _ in scrollToBottom(proxy) }
                }
            }

            VStack(spacing: 10) {
                if viewModel.usedFallbackTopic {
                    banner("Could not generate topic. Using a fallback topic.", icon: "info.circle.fill", tint: accent)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
                if let error = viewModel.errorMessage, !error.isEmpty {
                    banner(error, icon: "exclamationmark.triangle.fill", tint: AppColors.foodAccent)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                DebateMicBarView(
                    state: viewModel.state,
                    onEnd: handleEnd,
                    onMic: handleMicTap,
                    onHint: { viewModel.requestHint() }
                )
            }
            .speakingActionBarWidth()
            .padding(.horizontal, Layout.homeBottomBarHorizontalPadding)
            .padding(.bottom, Layout.homeBottomBarBottomPadding)
            .animation(.easeInOut(duration: 0.22), value: viewModel.errorMessage)
            .animation(.easeInOut(duration: 0.22), value: viewModel.usedFallbackTopic)
        }
        .ignoresSafeArea(edges: .bottom)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .task { viewModel.startDebate() }
        .onAppear { viewModel.onDebateEnded = { showResult = true } }
        .onDisappear { viewModel.endDebate() }
        .navigationDestination(isPresented: $showResult) {
            ConversationResultView(
                viewModel: viewModel,
                completionTitle: "Debate completed",
                onPracticeAgain: {
                    viewModel.resetDebate()
                    showResult = false
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 200_000_000)
                        viewModel.startDebate()
                    }
                },
                onBackToSpeaking: {
                    showResult = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { dismiss() }
                }
            )
        }
    }

    private var messageList: some View {
        VStack(alignment: .leading, spacing: Layout.convMessageGroupSpacing) {
            ForEach(viewModel.messages) { message in
                ConversationMessageBubbleView(message: message)
                    .id(message.id)
            }

            if !viewModel.partialTranscript.isEmpty {
                ConversationMessageBubbleView(
                    message: SpeakingConversationMessage(role: .user, text: viewModel.partialTranscript)
                )
                .opacity(0.55)
                .id("partial")
            }

            if let hint = viewModel.currentHint {
                ConversationHintBubbleView(text: hint, onDismiss: { viewModel.clearHint() })
                    .id("hint-bubble")
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.easeInOut(duration: 0.22), value: viewModel.currentHint)
    }

    private var topBar: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Debate Mode")
                    .font(.system(size: Layout.homeHeaderTitleSize, weight: .bold, design: .rounded))
                    .foregroundColor(accentDark)

                Text("Defend your ideas against an AI opponent.")
                    .font(.system(size: Layout.homeHeaderSubtitleSize, weight: .medium, design: .rounded))
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
                        .font(.system(size: Layout.flashcardDetailTopButtonIconSize, weight: .bold))
                        .foregroundColor(accentDark)
                        .frame(width: Layout.flashcardDetailTopButtonSize, height: Layout.flashcardDetailTopButtonSize)
                        .background(Color.white.opacity(0.82))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(viewModel.setup.language.shortTitle) · \(viewModel.setup.level.title)")
                        .font(.system(size: Layout.convScenarioChipTextSize + 1, weight: .bold, design: .rounded))
                        .foregroundColor(accent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(accent.opacity(0.10))
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

    private func banner(_ message: String, icon: String, tint: Color) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(tint)
            Text(message)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(accentDark)
                .lineLimit(3)
            Spacer(minLength: 0)
            Button { viewModel.clearError() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(AppColors.mutedText)
                    .padding(6)
                    .background(Color.white.opacity(0.6))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.96))
                .shadow(color: Color.black.opacity(0.06), radius: 11, x: 0, y: 4)
        )
    }

    private func handleMicTap() {
        Task { await viewModel.toggleListening() }
    }

    private func handleEnd() {
        viewModel.endDebate()
        showResult = true
    }

    private func handleBack() {
        viewModel.endDebate()
        dismiss()
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        guard let last = viewModel.messages.last else { return }
        withAnimation(.easeOut(duration: 0.22)) {
            proxy.scrollTo(last.id, anchor: .bottom)
        }
    }
}

#Preview {
    NavigationStack {
        DebateModeView(
            setup: SpeakingConversationSetup(
                language: .english,
                level: .b1,
                scenario: nil,
                length: .medium
            ),
            side: .agree
        )
    }
}
