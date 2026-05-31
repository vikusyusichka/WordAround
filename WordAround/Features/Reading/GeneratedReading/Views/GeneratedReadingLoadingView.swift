import SwiftUI

struct GeneratedReadingLoadingView: View {
    let setup: ReadingSessionSetup
    var onExitToSetup: () -> Void
    var onExitToReading: () -> Void

    @StateObject private var viewModel: GeneratedReadingSessionViewModel
    @State private var showSession = false
    @State private var pulse = false

    init(setup: ReadingSessionSetup, onExitToSetup: @escaping () -> Void, onExitToReading: @escaping () -> Void) {
        self.setup = setup
        self.onExitToSetup = onExitToSetup
        self.onExitToReading = onExitToReading
        _viewModel = StateObject(wrappedValue: GeneratedReadingSessionViewModel(setup: setup))
    }

    var body: some View {
        ZStack {
            AppColors.appBackground.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: Layout.homeContentSpacing) {
                    ReadingSessionHeaderView(
                        title: "Preparing your reading",
                        subtitle: "Creating a text for your level.",
                        accent: setup.accent,
                        accentDark: setup.accentDark,
                        onBack: onExitToSetup
                    )

                    centerCard
                }
                .frame(maxWidth: Layout.convContentMaxWidth)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, Layout.homeHorizontalPadding)
                .padding(.top, Layout.homeTopSpacing)
                .padding(.bottom, Layout.homeBottomSafeSpacing)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            pulse = true
            cycleLoadingSteps()
        }
        .navigationDestination(isPresented: $showSession) {
            GeneratedReadingSessionView(
                setup: setup,
                onExitToSetup: onExitToSetup,
                onExitToReading: onExitToReading
            )
        }
    }

    private var centerCard: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(setup.accent.opacity(0.12))
                    .frame(width: 88, height: 88)
                    .scaleEffect(pulse ? 1.06 : 0.94)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulse)

                Image(systemName: "sparkles")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundColor(setup.accent)
            }

            HStack(spacing: 8) {
                ForEach(viewModel.loadingChips, id: \.self) { chip in
                    ReadingMetadataChip(text: chip, accent: setup.accent)
                }
            }

            Text(GeneratedReadingSessionViewModel.loadingSteps[viewModel.loadingStepIndex])
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
                .animation(.easeInOut, value: viewModel.loadingStepIndex)

            ReadingContinueButton(
                title: "Continue",
                icon: "arrow.right",
                accent: setup.accent,
                accentDark: setup.accentDark
            ) {
                showSession = true
            }
            .padding(.top, 8)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.94))
        )
        .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 4)
    }

    private func cycleLoadingSteps() {
        Task {
            for step in 0..<GeneratedReadingSessionViewModel.loadingSteps.count {
                try? await Task.sleep(nanoseconds: 1_200_000_000)
                viewModel.loadingStepIndex = step
            }
            try? await Task.sleep(nanoseconds: 800_000_000)
            showSession = true
        }
    }
}

#Preview {
    NavigationStack {
        GeneratedReadingLoadingView(
            setup: ReadingSetupViewModel(config: .generatedReading).makeSessionSetup(),
            onExitToSetup: {},
            onExitToReading: {}
        )
    }
}
