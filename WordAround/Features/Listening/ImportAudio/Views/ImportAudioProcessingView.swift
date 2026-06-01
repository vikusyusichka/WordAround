import SwiftUI

struct ImportAudioProcessingView: View {
    let setup: ListeningAudioImportSetup
    var onExitToSetup: (() -> Void)? = nil
    var onExitToListening: (() -> Void)? = nil

    @StateObject private var viewModel: ImportAudioProcessingViewModel

    private let accent = ListeningTheme.importAudioAccent
    private let accentDark = ListeningTheme.importAudioDark

    init(
        setup: ListeningAudioImportSetup,
        onExitToSetup: (() -> Void)? = nil,
        onExitToListening: (() -> Void)? = nil
    ) {
        self.setup = setup
        self.onExitToSetup = onExitToSetup
        self.onExitToListening = onExitToListening
        _viewModel = StateObject(wrappedValue: ImportAudioProcessingViewModel(setup: setup))
    }

    var body: some View {
        ZStack {
            AppColors.appBackground.ignoresSafeArea()

            VStack(spacing: Layout.homeContentSpacing) {
                Spacer()

                VStack(spacing: 20) {
                    Text("Preparing your listening practice")
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
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.white)
                                    } else if index == viewModel.currentStep {
                                        ProgressView()
                                            .progressViewStyle(.circular)
                                            .tint(.white)
                                            .scaleEffect(0.7)
                                    } else {
                                        Circle()
                                            .fill(Color.white.opacity(0.8))
                                            .frame(width: 8, height: 8)
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

                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { viewModel.runProcessing() }
        .navigationDestination(isPresented: $viewModel.showSession) {
            ImportAudioSessionView(
                setup: setup,
                onExitToSetup: onExitToSetup,
                onExitToListening: onExitToListening
            )
        }
    }
}

#Preview {
    NavigationStack {
        ImportAudioProcessingView(
            setup: ListeningAudioImportSetup(
                language: .english,
                level: .b1,
                fileName: "podcast.mp3",
                durationText: "4:32",
                fileSizeText: "8.4 MB",
                addQuestions: true,
                questionCount: 5,
                questionTypes: Set(ListeningQuestionType.allCases)
            )
        )
    }
}
