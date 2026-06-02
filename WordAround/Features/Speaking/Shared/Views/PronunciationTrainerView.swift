import SwiftUI

struct PronunciationTrainerView: View {
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel: PronunciationTrainerViewModel
    @State private var showResult = false

    private let accent = PronunciationTrainerTheme.accent
    private let accentDark = PronunciationTrainerTheme.accentDark

    init(setup: SpeakingConversationSetup, difficulty: PronunciationDifficulty, focus: PronunciationFocus) {
        _viewModel = StateObject(wrappedValue: PronunciationTrainerViewModel(setup: setup, difficulty: difficulty, focus: focus))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColors.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, Layout.homeHorizontalPadding)
                    .padding(.top, Layout.homeTopSpacing)
                    .padding(.bottom, 14)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        if !viewModel.items.isEmpty {
                            PronunciationProgressCardView(
                                currentIndex: viewModel.currentItemIndex,
                                total: viewModel.items.count,
                                progress: viewModel.sessionProgress
                            )
                            regenerateRow
                        }

                        PronunciationItemCardView(
                            item: viewModel.currentItem,
                            isLoading: viewModel.isLoadingItems,
                            isSpeaking: viewModel.isPlayingItem,
                            onPlay: { viewModel.playCurrentItem() },
                            onPlayExample: { viewModel.playExample() }
                        )

                        if viewModel.permissionsDenied {
                            banner("Microphone and speech recognition access are required for Pronunciation Trainer.", isError: true)
                        } else if let error = viewModel.errorMessage, !error.isEmpty {
                            banner(error, isError: true)
                        }

                        if viewModel.usedFallbackItems, let info = viewModel.itemGenerationError {
                            banner(info, isError: false)
                        }

                        transcriptSection

                        if viewModel.isAssessingPronunciation || viewModel.currentAssessment != nil {
                            PronunciationAssessmentCardView(
                                assessment: viewModel.currentAssessment,
                                isAssessing: viewModel.isAssessingPronunciation
                            )
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                    }
                    .padding(.horizontal, Layout.homeHorizontalPadding)
                    .frame(maxWidth: Layout.convContentMaxWidth)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, Layout.convMicBarHeight + Layout.convMicBarBottomPadding + 60)
                    .animation(.easeInOut(duration: 0.22), value: viewModel.currentAssessment)
                    .animation(.easeInOut(duration: 0.22), value: viewModel.isAssessingPronunciation)
                }
            }

            PronunciationMicBarView(
                state: viewModel.state,
                canRetry: viewModel.hasAttemptForCurrentItem || !viewModel.userTranscript.isEmpty,
                isLastItem: viewModel.isLastItem,
                onRetry: { viewModel.retryCurrentItem() },
                onMic: handleMicTap,
                onNext: handleNext
            )
            .speakingActionBarWidth()
            .padding(.horizontal, Layout.homeBottomBarHorizontalPadding)
            .padding(.bottom, Layout.homeBottomBarBottomPadding)
        }
        .ignoresSafeArea(edges: .bottom)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .task { viewModel.startSession() }
        .onAppear { viewModel.onSessionEnded = { showResult = true } }
        .onDisappear { viewModel.endSession() }
        .navigationDestination(isPresented: $showResult) {
            ConversationResultView(
                viewModel: viewModel,
                completionTitle: "Pronunciation Trainer completed",
                onPracticeAgain: {
                    viewModel.resetSession()
                    showResult = false
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 200_000_000)
                        viewModel.startSession()
                    }
                },
                onBackToSpeaking: {
                    showResult = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { dismiss() }
                }
            )
        }
    }

    private var topBar: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Pronunciation Trainer")
                    .font(.system(size: Layout.homeHeaderTitleSize, weight: .bold, design: .rounded))
                    .foregroundColor(accentDark)
                Text("Focus on difficult sounds and words.")
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

                    progressChip
                }
            }
        }
    }

    private var progressChip: some View {
        HStack(spacing: 5) {
            Image(systemName: "list.number").font(.system(size: 11, weight: .semibold))
            Text(viewModel.progressLabel).font(.system(size: 12, weight: .bold, design: .rounded))
        }
        .foregroundColor(AppColors.textSecondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(AppColors.textSecondary.opacity(0.10))
        .clipShape(Capsule())
    }

    private var transcriptSection: some View {
        Group {
            if !viewModel.partialTranscript.isEmpty {
                transcriptCard(viewModel.partialTranscript, isPlaceholder: true)
            } else if !viewModel.userTranscript.isEmpty {
                transcriptCard(viewModel.userTranscript, isPlaceholder: false)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.userTranscript)
        .animation(.easeInOut(duration: 0.2), value: viewModel.partialTranscript)
    }

    private func transcriptCard(_ text: String, isPlaceholder: Bool) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "waveform")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(accent)
            Text(text)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(isPlaceholder ? AppColors.textSecondary : accentDark)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
                .fill(Color.white.opacity(isPlaceholder ? 0.72 : 0.94))
                .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
        )
        .opacity(isPlaceholder ? 0.75 : 1)
    }

    private var regenerateRow: some View {
        HStack {
            Spacer()
            Button { viewModel.regenerateItems() } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.triangle.2.circlepath").font(.system(size: 12, weight: .bold))
                    Text("Regenerate items").font(.system(size: 13, weight: .bold, design: .rounded))
                }
                .foregroundColor(accent)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(accent.opacity(0.10))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isLoadingItems)
            .opacity(viewModel.isLoadingItems ? 0.5 : 1)
        }
    }

    private func banner(_ message: String, isError: Bool) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: isError ? "exclamationmark.triangle.fill" : "info.circle.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(isError ? AppColors.foodAccent : accent)
            Text(message)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(accentDark)
                .lineLimit(3)
            Spacer(minLength: 0)
            if isError {
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
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.96))
                .shadow(color: Color.black.opacity(0.06), radius: 11, x: 0, y: 4)
        )
    }

    private func handleMicTap() { Task { await viewModel.toggleListening() } }
    private func handleNext() { viewModel.goToNextItem() }
    private func handleBack() { viewModel.endSession(); dismiss() }
}

#Preview {
    NavigationStack {
        PronunciationTrainerView(
            setup: SpeakingConversationSetup(language: .spanish, level: .a2, scenario: nil, length: .short),
            difficulty: .balanced,
            focus: .minimalPairs
        )
    }
}
