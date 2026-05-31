import SwiftUI

struct SpeedReadingSessionView: View {
    let setup: ReadingSessionSetup
    @ObservedObject var viewModel: SpeedReadingSessionViewModel
    var onExitToSetup: () -> Void
    var onExitToReading: () -> Void

    @State private var showResult = false

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColors.appBackground.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: Layout.homeContentSpacing) {
                    headerRow

                    ReadingProgressBar(progress: viewModel.readingProgress, accent: setup.accent)

                    ReadingSessionTextCardView(
                        bodyText: viewModel.chunks[viewModel.currentChunkIndex],
                        accent: setup.accent
                    )
                    .scaleEffect(viewModel.fontScale)

                    controlRow

                    ReadingPaceCard(
                        currentWPM: viewModel.currentWPM,
                        targetWPM: viewModel.targetWPM,
                        status: viewModel.paceStatus,
                        accent: setup.accent
                    )

                    Spacer().frame(height: Layout.convSetupStartButtonHeight + 24)
                }
                .frame(maxWidth: Layout.convContentMaxWidth)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, Layout.homeHorizontalPadding)
                .padding(.top, Layout.homeTopSpacing)
                .padding(.bottom, Layout.homeBottomSafeSpacing)
            }

            ReadingContinueButton(
                title: "Finish Session",
                icon: "flag.checkered",
                accent: setup.accent,
                accentDark: setup.accentDark
            ) {
                showResult = true
            }
            .frame(maxWidth: Layout.convContentMaxWidth)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, Layout.homeHorizontalPadding)
            .padding(.bottom, Layout.homeBottomBarBottomPadding)
        }
        .ignoresSafeArea(edges: .bottom)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $showResult) {
            SpeedReadingResultView(
                setup: setup,
                onExitToSetup: onExitToSetup,
                onExitToReading: onExitToReading
            )
        }
    }

    private var headerRow: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Speed Reading")
                    .font(.system(size: Layout.homeHeaderTitleSize, weight: .bold, design: .rounded))
                    .foregroundColor(setup.accentDark)
                Text(viewModel.paceLabel)
                    .font(.system(size: Layout.homeHeaderSubtitleSize, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.mutedText)
            }
            Spacer()
            ReadingTimerCard(timeText: viewModel.timerText, label: "Timer", accent: setup.accent)
        }
    }

    private var controlRow: some View {
        HStack(spacing: 10) {
            controlButton("Previous", systemImage: "chevron.left") { viewModel.goPreviousChunk() }
            controlButton(viewModel.isPaused ? "Resume" : "Pause", systemImage: viewModel.isPaused ? "play.fill" : "pause.fill") {
                viewModel.togglePause()
            }
            controlButton("Next", systemImage: "chevron.right") { viewModel.goNextChunk() }
            controlButton("A+", systemImage: "textformat.size.larger") { viewModel.increaseFont() }
        }
    }

    private func controlButton(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(setup.accentDark)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(setup.accent.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        SpeedReadingSessionView(
            setup: ReadingSetupViewModel(config: .speedReading).makeSessionSetup(),
            viewModel: SpeedReadingSessionViewModel(setup: ReadingSetupViewModel(config: .speedReading).makeSessionSetup()),
            onExitToSetup: {},
            onExitToReading: {}
        )
    }
}
