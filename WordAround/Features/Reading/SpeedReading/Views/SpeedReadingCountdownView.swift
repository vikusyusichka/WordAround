import SwiftUI

struct SpeedReadingCountdownView: View {
    let setup: ReadingSessionSetup
    var onExitToSetup: () -> Void
    var onExitToReading: () -> Void

    @StateObject private var viewModel: SpeedReadingSessionViewModel
    @State private var hasPushedSession = false

    init(
        setup: ReadingSessionSetup,
        onExitToSetup: @escaping () -> Void,
        onExitToReading: @escaping () -> Void
    ) {
        self.setup = setup
        self.onExitToSetup = onExitToSetup
        self.onExitToReading = onExitToReading
        _viewModel = StateObject(wrappedValue: SpeedReadingSessionViewModel(setup: setup))
    }

    init(
        item: ReadingLibraryItem,
        onExitToSetup: @escaping () -> Void,
        onExitToReading: @escaping () -> Void
    ) {
        let session = SpeedReadingSession.from(item: item)
        self.setup = ReadingSessionSetup(
            modeID: "speed-reading",
            language: session.configuration.language,
            selections: session.configuration.asSelections,
            toggles: [:],
            accent: ReadingSetupConfig.speedReading.accent,
            accentDark: ReadingSetupConfig.speedReading.accentDark,
            title: ReadingSetupConfig.speedReading.title,
            subtitle: ReadingSetupConfig.speedReading.subtitle
        )
        self.onExitToSetup = onExitToSetup
        self.onExitToReading = onExitToReading
        _viewModel = StateObject(wrappedValue: SpeedReadingSessionViewModel(item: item))
    }

    private var accent: Color { setup.accent }
    private var accentDark: Color { setup.accentDark }

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColors.appBackground.ignoresSafeArea()

            VStack(spacing: Layout.homeContentSpacing) {
                ReadingSessionHeaderView(
                    title: "Get Ready",
                    subtitle: subtitleForPhase,
                    accent: accent,
                    accentDark: accentDark,
                    onBack: {
                        viewModel.onDisappear()
                        onExitToSetup()
                    }
                )
                .padding(.horizontal, Layout.homeHorizontalPadding)
                .padding(.top, Layout.homeTopSpacing)

                Spacer()

                centerContent

                HStack(spacing: 8) {
                    ForEach(viewModel.countdownChips, id: \.self) { chip in
                        ReadingMetadataChip(text: chip, accent: accent)
                    }
                }
                .padding(.horizontal, Layout.homeHorizontalPadding)

                Spacer()

                if case .error(let message) = viewModel.phase {
                    errorBanner(message)
                        .padding(.horizontal, Layout.homeHorizontalPadding)
                    ReadingPrimaryButton(
                        title: "Try Again",
                        icon: "arrow.clockwise",
                        accent: accent,
                        accentDark: accentDark
                    ) { Task { await viewModel.retry() } }
                    .padding(.horizontal, Layout.homeHorizontalPadding)
                    .padding(.bottom, Layout.homeBottomBarBottomPadding)
                }
            }
            .frame(maxWidth: Layout.convContentMaxWidth)
            .frame(maxWidth: .infinity)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .task { await viewModel.load() }
        .onChange(of: viewModel.phase) { _, newPhase in
            switch newPhase {
            case .reading, .questions, .results:
                if !hasPushedSession { hasPushedSession = true }
            default: break
            }
        }
        .navigationDestination(isPresented: $hasPushedSession) {
            SpeedReadingSessionView(
                viewModel: viewModel,
                onExitToSetup: {
                    hasPushedSession = false
                    onExitToSetup()
                },
                onExitToReading: {
                    hasPushedSession = false
                    onExitToReading()
                }
            )
        }
    }

    // MARK: - Center content

    @ViewBuilder
    private var centerContent: some View {
        switch viewModel.phase {
        case .loading:
            VStack(spacing: 14) {
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(accent)
                Text(SpeedReadingSessionViewModel.loadingSteps[
                    min(viewModel.loadingStepIndex, SpeedReadingSessionViewModel.loadingSteps.count - 1)
                ])
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(accentDark)
                    .multilineTextAlignment(.center)
            }
        case .countdown:
            Text("\(viewModel.countdownValue)")
                .font(.system(size: 96, weight: .bold, design: .rounded))
                .foregroundColor(accent)
                .contentTransition(.numericText())
        case .error:
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 56, weight: .bold))
                .foregroundColor(.orange)
        case .reading, .questions, .results:
            ProgressView().tint(accent)
        }
    }

    private var subtitleForPhase: String {
        switch viewModel.phase {
        case .loading:  return "Building reading session for your pace."
        case .countdown: return "Focus before your timed reading begins."
        case .error:    return "We couldn't start the session."
        default:        return "Focus before your timed reading begins."
        }
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.orange)
            Text(message)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.primaryBlueDark)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.94))
        .clipShape(RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        SpeedReadingCountdownView(
            setup: ReadingSetupViewModel(config: .speedReading).makeSessionSetup(),
            onExitToSetup: {},
            onExitToReading: {}
        )
    }
}
