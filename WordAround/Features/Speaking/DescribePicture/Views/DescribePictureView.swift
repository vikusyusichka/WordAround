import SwiftUI

struct DescribePictureView: View {
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel: DescribePictureViewModel

    @State private var showResult = false
    @State private var showRefreshConfirm = false
    @State private var activeHint: String?
    @State private var hintIndex = 0

    private let orange = AppColors.orangeAccent

    /// Local hint phrases only — never sent to AI, never added to transcript.
    private let hints = [
        "In this picture I can see…",
        "It looks like…",
        "There are several…",
        "In the background there is…",
        "The person seems to be…"
    ]

    init(setup: SpeakingConversationSetup) {
        _viewModel = StateObject(wrappedValue: DescribePictureViewModel(setup: setup))
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
                    VStack(spacing: 20) {
                        DescribePictureImageCardView(
                            image: viewModel.currentImage,
                            isLoading: viewModel.isLoadingImage,
                            errorMessage: viewModel.imageError,
                            onRefresh: handleRefresh
                        )

                        DescribePicturePromptCardView()

                        if viewModel.permissionsDenied {
                            banner("Microphone and speech recognition access are required for Describe Picture.")
                        } else if let error = viewModel.errorMessage, !error.isEmpty {
                            banner(error)
                        }

                        transcriptSection
                    }
                    .padding(.horizontal, Layout.homeHorizontalPadding)
                    .frame(maxWidth: Layout.convContentMaxWidth)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, Layout.convMicBarHeight + Layout.convMicBarBottomPadding + 60)
                }
            }

            if let hint = activeHint {
                hintBubble(hint)
                    .padding(.horizontal, Layout.homeBottomBarHorizontalPadding)
                    .padding(.bottom, Layout.convMicBarHeight + Layout.convMicBarBottomPadding + 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            DescribePictureMicBarView(
                isRecording: isRecording,
                onEnd: handleEnd,
                onMicTap: handleMicTap,
                onHint: handleHint
            )
            .speakingActionBarWidth()
            .padding(.horizontal, Layout.homeBottomBarHorizontalPadding)
            .padding(.bottom, Layout.homeBottomBarBottomPadding)
        }
        .ignoresSafeArea(edges: .bottom)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .task { viewModel.startSession() }
        .onAppear {
            viewModel.onTimerFinished = { showResult = true }
        }
        .onDisappear { viewModel.endSession() }
        .alert("Change picture?", isPresented: $showRefreshConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("New Picture", role: .destructive) { viewModel.refreshImage() }
        } message: {
            Text("Changing the picture will reset your current transcript.")
        }
        .navigationDestination(isPresented: $showResult) {
            ConversationResultView(
                viewModel: viewModel,
                completionTitle: "Describe Picture completed",
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
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
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
                Text("Describe Picture")
                    .font(.system(size: Layout.homeHeaderTitleSize, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.orangeTitle)

                Text("Describe images and improve your speaking.")
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
                        .foregroundColor(AppColors.orangeTitle)
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
                        .font(.system(size: Layout.convScenarioChipTextSize + 1, weight: .bold, design: .rounded))
                        .foregroundColor(orange)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(orange.opacity(0.10))
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

    // MARK: - Transcript

    private var transcriptSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Transcript")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.orangeTitle)

            if viewModel.transcriptChunks.isEmpty && viewModel.partialTranscript.isEmpty {
                emptyTranscriptState
            } else {
                liveTranscriptContent
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.easeInOut(duration: 0.22), value: viewModel.transcriptChunks.count)
    }

    private var liveTranscriptContent: some View {
        VStack(spacing: Layout.convMessageGroupSpacing) {
            ForEach(Array(viewModel.transcriptChunks.enumerated()), id: \.offset) { _, chunk in
                DescribePictureTranscriptCardView(text: chunk)
            }

            if !viewModel.partialTranscript.isEmpty {
                DescribePictureTranscriptCardView(text: viewModel.partialTranscript, isPlaceholder: true)
            }
        }
    }

    private var emptyTranscriptState: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(orange.opacity(0.10))
                    .frame(width: 54, height: 54)
                Image(systemName: "waveform")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(orange)
            }
            .padding(.top, 16)

            Text("Start speaking to build your description")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.orangeTitle)
                .multilineTextAlignment(.center)

            Text("Your description will appear here while you speak.")
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

    // MARK: - Hint Bubble

    private func hintBubble(_ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(orange)
            Text(text)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.orangeTitle)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.98))
                .shadow(color: Color.black.opacity(0.08), radius: 14, x: 0, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(orange.opacity(0.22), lineWidth: 1)
        )
    }

    private func banner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppColors.foodAccent)
            Text(message)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.orangeTitle)
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
        } else {
            Task { await viewModel.startListening() }
        }
    }

    private func handleRefresh() {
        if viewModel.hasTranscript {
            showRefreshConfirm = true
        } else {
            viewModel.refreshImage()
        }
    }

    private func handleHint() {
        let hint = hints[hintIndex % hints.count]
        hintIndex += 1
        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
            activeHint = hint
        }
        // Local only — auto-dismiss after a few seconds.
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 3_500_000_000)
            withAnimation(.easeInOut(duration: 0.25)) {
                if activeHint == hint { activeHint = nil }
            }
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
        DescribePictureView(
            setup: SpeakingConversationSetup(
                language: .english,
                level: .a2,
                scenario: nil,
                length: .short
            )
        )
    }
}
