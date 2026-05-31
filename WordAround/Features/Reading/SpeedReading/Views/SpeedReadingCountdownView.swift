import SwiftUI

struct SpeedReadingCountdownView: View {
    let setup: ReadingSessionSetup
    var onExitToSetup: () -> Void
    var onExitToReading: () -> Void

    @StateObject private var viewModel: SpeedReadingSessionViewModel
    @State private var showSession = false

    init(setup: ReadingSessionSetup, onExitToSetup: @escaping () -> Void, onExitToReading: @escaping () -> Void) {
        self.setup = setup
        self.onExitToSetup = onExitToSetup
        self.onExitToReading = onExitToReading
        _viewModel = StateObject(wrappedValue: SpeedReadingSessionViewModel(setup: setup))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColors.appBackground.ignoresSafeArea()

            VStack(spacing: Layout.homeContentSpacing) {
                ReadingSessionHeaderView(
                    title: "Get Ready",
                    subtitle: "Focus before your timed reading begins.",
                    accent: setup.accent,
                    accentDark: setup.accentDark,
                    onBack: onExitToSetup
                )
                .padding(.horizontal, Layout.homeHorizontalPadding)
                .padding(.top, Layout.homeTopSpacing)

                Spacer()

                Text("\(viewModel.countdownValue)")
                    .font(.system(size: 96, weight: .bold, design: .rounded))
                    .foregroundColor(setup.accent)
                    .contentTransition(.numericText())

                HStack(spacing: 8) {
                    ForEach(viewModel.countdownChips, id: \.self) { chip in
                        ReadingMetadataChip(text: chip, accent: setup.accent)
                    }
                }
                .padding(.horizontal, Layout.homeHorizontalPadding)

                Spacer()

                ReadingContinueButton(
                    title: "Start Now",
                    icon: "bolt.fill",
                    accent: setup.accent,
                    accentDark: setup.accentDark
                ) {
                    showSession = true
                }
                .padding(.horizontal, Layout.homeHorizontalPadding)
                .padding(.bottom, Layout.homeBottomBarBottomPadding)
            }
            .frame(maxWidth: Layout.convContentMaxWidth)
            .frame(maxWidth: .infinity)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            viewModel.startCountdown()
            runCountdown()
        }
        .navigationDestination(isPresented: $showSession) {
            SpeedReadingSessionView(
                setup: setup,
                viewModel: viewModel,
                onExitToSetup: onExitToSetup,
                onExitToReading: onExitToReading
            )
        }
    }

    private func runCountdown() {
        Task {
            for value in stride(from: 3, through: 1, by: -1) {
                viewModel.countdownValue = value
                try? await Task.sleep(nanoseconds: 900_000_000)
            }
            showSession = true
        }
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
