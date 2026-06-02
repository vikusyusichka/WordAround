import SwiftUI

struct ImportVideoProcessingView: View {
    let setup: ListeningVideoImportSetup
    var onExitToSetup: (() -> Void)? = nil
    var onExitToListening: (() -> Void)? = nil

    @StateObject private var viewModel: ImportVideoProcessingViewModel

    private let accent = ListeningTheme.importVideoAccent
    private let accentDark = ListeningTheme.importVideoDark

    init(
        setup: ListeningVideoImportSetup,
        onExitToSetup: (() -> Void)? = nil,
        onExitToListening: (() -> Void)? = nil
    ) {
        self.setup = setup
        self.onExitToSetup = onExitToSetup
        self.onExitToListening = onExitToListening
        _viewModel = StateObject(wrappedValue: ImportVideoProcessingViewModel(setup: setup))
    }

    var body: some View {
        ZStack {
            AppColors.appBackground.ignoresSafeArea()

            VStack(spacing: Layout.homeContentSpacing) {
                Spacer()
                if viewModel.hasFailed {
                    errorState
                } else {
                    progressState
                }
                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { viewModel.run() }
        .navigationDestination(isPresented: $viewModel.showSession) {
            if let transcription = viewModel.transcription {
                ImportVideoSessionView(
                    setup: setup,
                    transcription: transcription,
                    sessionId: viewModel.sessionId,
                    onExitToSetup: onExitToSetup,
                    onExitToListening: onExitToListening
                )
            }
        }
    }

    private var progressState: some View {
        VStack(spacing: 20) {
            Text("Preparing your video practice")
                .font(.system(size: Layout.homeHeaderTitleSize, weight: .bold, design: .rounded))
                .foregroundColor(accentDark)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 14) {
                ForEach(Array(viewModel.stepTitles.enumerated()), id: \.offset) { index, step in
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(index <= viewModel.currentStep ? accent : accent.opacity(0.14))
                                .frame(width: 28, height: 28)
                            if index < viewModel.currentStep {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold)).foregroundColor(.white)
                            } else if index == viewModel.currentStep {
                                ProgressView().progressViewStyle(.circular).tint(.white).scaleEffect(0.7)
                            } else {
                                Circle().fill(Color.white.opacity(0.8)).frame(width: 8, height: 8)
                            }
                        }
                        Text(step)
                            .font(.system(size: 15, weight: index == viewModel.currentStep ? .bold : .medium, design: .rounded))
                            .foregroundColor(index <= viewModel.currentStep ? accentDark : AppColors.mutedText)
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
                    .fill(Color.white.opacity(0.94))
                    .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 4)
            )
        }
        .frame(maxWidth: Layout.convContentMaxWidth)
        .padding(.horizontal, Layout.homeHorizontalPadding)
    }

    private var errorState: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle().fill(Color(red: 0.95, green: 0.42, blue: 0.40).opacity(0.14)).frame(width: 64, height: 64)
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundColor(Color(red: 0.95, green: 0.42, blue: 0.40))
            }
            Text("We couldn't prepare this video")
                .font(.system(size: Layout.homeHeaderTitleSize, weight: .bold, design: .rounded))
                .foregroundColor(accentDark)
                .multilineTextAlignment(.center)
            Text(viewModel.errorMessage ?? "Something went wrong.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
            VStack(spacing: 10) {
                ListeningPrimaryButton(title: "Try Again", icon: "arrow.clockwise", accent: accent, accentDark: accentDark) {
                    viewModel.retry()
                }
                Button { onExitToSetup?() } label: {
                    Text("Choose another video")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(accentDark)
                        .frame(maxWidth: .infinity)
                        .frame(height: Layout.convSetupStartButtonHeight)
                        .background(accent.opacity(0.10))
                        .clipShape(RoundedRectangle(cornerRadius: Layout.convSetupStartButtonCornerRadius, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(24)
        .frame(maxWidth: Layout.convContentMaxWidth)
        .background(
            RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.94))
                .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 4)
        )
        .padding(.horizontal, Layout.homeHorizontalPadding)
    }
}
