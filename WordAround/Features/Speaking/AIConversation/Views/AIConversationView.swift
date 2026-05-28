import SwiftUI

struct AIConversationView: View {
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel: AIConversationViewModel
    @State private var showResult = false

    init(setup: SpeakingConversationSetup) {
        _viewModel = StateObject(wrappedValue: AIConversationViewModel(setup: setup))
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
                        VStack(spacing: 0) {
                            tappableScenarioCard
                                .padding(.horizontal, Layout.homeHorizontalPadding)
                                .padding(.bottom, 18)
                                .id("scenario-card")

                            VStack(alignment: .leading, spacing: Layout.convMessageGroupSpacing) {
                                ForEach(viewModel.messages) { message in
                                    ConversationMessageBubbleView(message: message)
                                        .id(message.id)
                                }

                                if !viewModel.partialTranscript.isEmpty {
                                    ConversationMessageBubbleView(
                                        message: SpeakingConversationMessage(
                                            role: .user,
                                            text: viewModel.partialTranscript
                                        )
                                    )
                                    .opacity(0.55)
                                    .id("partial")
                                }

                                if let hint = viewModel.currentHint {
                                    ConversationHintBubbleView(
                                        text: hint,
                                        onDismiss: { viewModel.clearHint() }
                                    )
                                    .id("hint-bubble")
                                    .transition(.opacity.combined(with: .move(edge: .trailing)))
                                }
                            }
                            .padding(.horizontal, Layout.homeHorizontalPadding)
                            .animation(.easeInOut(duration: 0.22), value: viewModel.currentHint)
                        }
                        .frame(maxWidth: Layout.convContentMaxWidth)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, Layout.convMicBarHeight + Layout.convMicBarBottomPadding + 60)
                    }
                    .onChange(of: viewModel.messages.count) { _, _ in
                        scrollToBottom(proxy: proxy)
                    }
                    .onChange(of: viewModel.partialTranscript) { _, _ in
                        scrollToBottom(proxy: proxy)
                    }
                    .onChange(of: viewModel.currentHint) { _, hint in
                        guard hint != nil else { return }
                        withAnimation(.easeOut(duration: 0.22)) {
                            proxy.scrollTo("hint-bubble", anchor: .bottom)
                        }
                    }
                }
            }

            VStack(spacing: 10) {
                if viewModel.usedFallbackTopic {
                    informationalBanner("Could not generate topic. Using fallback topic.")
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                if let errorMessage = viewModel.errorMessage {
                    errorBanner(errorMessage)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                ConversationMicBarView(
                    state: viewModel.state,
                    onEnd: handleEnd,
                    onMic: handleMicTap,
                    onHint: { viewModel.requestHint() }
                )
            }
            .padding(.horizontal, Layout.homeBottomBarHorizontalPadding)
            .padding(.bottom, Layout.homeBottomBarBottomPadding)
            .animation(.easeInOut(duration: 0.22), value: viewModel.errorMessage)
            .animation(.easeInOut(duration: 0.22), value: viewModel.usedFallbackTopic)
        }
        .ignoresSafeArea(edges: .bottom)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .task {
            viewModel.startConversation()
        }
        .onAppear {
            viewModel.onTimerFinished = { showResult = true }
        }
        .onDisappear {
            viewModel.endConversation()
        }
        .navigationDestination(isPresented: $showResult) {
            ConversationResultView(
                viewModel: viewModel,
                onPracticeAgain: {
                    viewModel.resetConversation()
                    showResult = false
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 200_000_000)
                        viewModel.startConversation()
                    }
                },
                onBackToSpeaking: {
                    showResult = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        dismiss()
                    }
                }
            )
        }
        .sheet(isPresented: $viewModel.showTopicPicker) {
            ConversationTopicPickerSheetView(viewModel: viewModel)
        }
    }

    @ViewBuilder
    private var tappableScenarioCard: some View {
        scenarioCard
    }

    @ViewBuilder
    private var scenarioCard: some View {
        let chips = [viewModel.setup.level.title, viewModel.setup.length.title]
        let isDisabled = viewModel.isGeneratingTopic

        if viewModel.isGeneratingTopic {
            ConversationScenarioCardView(
                title: "Generating topic…",
                description: "Picking something that fits your level.",
                icon: "sparkles",
                chips: chips + ["Auto"],
                footerLabel: "AI conversation topic",
                showsFooter: true,
                isChangeDisabled: true,
                onChange: openTopicPicker
            )
        } else if let context = viewModel.context {
            ConversationScenarioCardView(
                title: context.title,
                description: context.description,
                icon: context.systemImage,
                chips: chips + [context.category],
                footerLabel: contextFooterLabel(for: context),
                showsFooter: true,
                showsChevron: true,
                isChangeDisabled: isDisabled,
                onChange: openTopicPicker
            )
        } else if let scenario = viewModel.setup.scenario {
            ConversationScenarioCardView(
                title: scenario.title,
                description: scenario.description,
                icon: scenario.icon,
                chips: chips + [scenario.category],
                footerLabel: "Conversation scenario",
                showsFooter: true,
                showsChevron: true,
                isChangeDisabled: isDisabled,
                onChange: openTopicPicker
            )
        } else {
            ConversationScenarioCardView(
                title: "AI-generated topic",
                description: "Loading…",
                icon: "sparkles",
                chips: chips + ["Auto"],
                footerLabel: "AI conversation topic",
                showsFooter: true,
                isChangeDisabled: true,
                onChange: openTopicPicker
            )
        }
    }

    private func contextFooterLabel(for context: SpeakingConversationContext) -> String {
        switch context {
        case .generatedTopic:
            return "AI conversation topic"
        case .scenario:
            return "Conversation scenario"
        }
    }

    private func openTopicPicker() {
        guard !viewModel.isGeneratingTopic else { return }
        viewModel.showTopicPicker = true
    }

    private func handleMicTap() {
        Task { await viewModel.toggleListening() }
    }

    private func handleEnd() {
        viewModel.endConversation()
        showResult = true
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        guard let last = viewModel.messages.last else { return }
        withAnimation(.easeOut(duration: 0.22)) {
            proxy.scrollTo(last.id, anchor: .bottom)
        }
    }

    private var topBar: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("AI Conversation")
                    .font(.system(
                        size: Layout.homeHeaderTitleSize,
                        weight: .bold,
                        design: .rounded
                    ))
                    .foregroundColor(AppColors.primaryBlueDark)

                Text("Practice real conversations with an AI tutor.")
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
                        .foregroundColor(AppColors.primaryBlue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(AppColors.primaryBlue.opacity(0.09))
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

    private func handleBack() {
        viewModel.endConversation()
        dismiss()
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppColors.foodAccent)

            Text(message)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.primaryBlueDark)
                .lineLimit(3)

            Spacer(minLength: 0)

            Button {
                viewModel.clearError()
            } label: {
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
                .shadow(color: Color.black.opacity(0.07), radius: 12, x: 0, y: 4)
        )
    }

    private func informationalBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppColors.primaryBlue)

            Text(message)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.primaryBlueDark)
                .lineLimit(2)

            Spacer(minLength: 0)

            Button {
                viewModel.clearError()
            } label: {
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
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 3)
        )
    }
}

#Preview {
    NavigationStack {
        AIConversationView(
            setup: SpeakingConversationSetup(
                language: .english,
                level: .b1,
                scenario: ConversationScenario.allScenarios[0],
                length: .medium
            )
        )
    }
}
