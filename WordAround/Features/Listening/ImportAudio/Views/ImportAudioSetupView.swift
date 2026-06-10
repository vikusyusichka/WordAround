import SwiftUI
import UniformTypeIdentifiers

struct ImportAudioSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ImportAudioSetupViewModel()

    var onExitToListening: (() -> Void)? = nil

    private let accent = ListeningTheme.importAudioAccent
    private let accentDark = ListeningTheme.importAudioDark

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColors.appBackground.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: Layout.homeContentSpacing) {
                    ListeningSetupTopBar(
                        title: L10n.string("listenImportAudio"),
                        subtitle: L10n.string("importAudioSubtitle"),
                        accent: accent,
                        accentDark: accentDark,
                        onBack: { dismiss() }
                    )
                    .padding(.bottom, 4)

                    ListeningSetupSectionTitle(L10n.string("listenSectionAudioUpload"), accentDark: accentDark)
                    uploadCard

                    ListeningSetupSectionTitle(L10n.string("spkSectionLanguage"), accentDark: accentDark)
                    LanguageSelectorView(
                        selectedLanguage: viewModel.selectedLanguage,
                        onSelect: { viewModel.selectedLanguage = $0 },
                        accent: accent,
                        accentDark: accentDark
                    )

                    ListeningSetupSectionTitle(L10n.string("spkSectionLevel"), accentDark: accentDark)
                    DifficultySelectorView(
                        selectedDifficulty: viewModel.selectedLevel,
                        onSelect: { viewModel.selectedLevel = $0 },
                        accent: accent,
                        accentDark: accentDark
                    )

                    ListeningSetupSectionTitle(L10n.string("listenSectionQuestions"), accentDark: accentDark)
                    ListeningQuestionSettingsCard(
                        addQuestions: $viewModel.addQuestions,
                        questionCount: $viewModel.questionCount,
                        selectedTypes: $viewModel.questionTypes,
                        accent: accent,
                        accentDark: accentDark
                    )

                    infoNote

                    if let errorMessage = viewModel.errorMessage {
                        ListeningInlineErrorView(message: errorMessage, accent: accent)
                    }

                    Spacer().frame(height: Layout.convSetupStartButtonHeight + 32)
                }
                .frame(maxWidth: Layout.convContentMaxWidth)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, Layout.homeHorizontalPadding)
                .padding(.top, Layout.homeTopSpacing)
                .padding(.bottom, Layout.homeBottomSafeSpacing)
            }

            ListeningSetupStartButton(
                title: L10n.string("commonContinue"),
                icon: "arrow.right",
                accent: accent,
                accentDark: accentDark,
                action: { viewModel.continueToProcessing() }
            )
            .padding(.horizontal, Layout.homeHorizontalPadding)
            .padding(.bottom, Layout.homeBottomBarBottomPadding)
            .disabled(!viewModel.canContinue)
            .opacity(viewModel.canContinue ? 1 : 0.55)
        }
        .ignoresSafeArea(edges: .bottom)
        .tint(accentDark)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .fileImporter(
            isPresented: $viewModel.showFileImporter,
            allowedContentTypes: [.mp3, .mpeg4Audio, .wav, .audio],
            allowsMultipleSelection: false
        ) { result in
            viewModel.handleImportResult(result)
        }
        .navigationDestination(isPresented: $viewModel.showProcessing) {
            ImportAudioProcessingView(
                setup: viewModel.makeSetup(),
                onExitToSetup: { viewModel.showProcessing = false },
                onExitToListening: onExitToListening
            )
        }
    }

    private var uploadCard: some View {
        ListeningWhiteCard {
            VStack(spacing: 14) {
                if let fileName = viewModel.selectedFileName {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(accent.opacity(0.14))
                                .frame(width: 44, height: 44)
                            Image(systemName: "waveform")
                                .foregroundColor(accent)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(fileName)
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(accentDark)
                            Text("\(viewModel.selectedDuration) • \(viewModel.selectedFileSize)")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(AppColors.textSecondary)
                        }

                        Spacer()

                        Button(action: viewModel.clearSelectedFile) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(AppColors.mutedText)
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    VStack(spacing: 10) {
                        Image(systemName: "arrow.up.doc.fill")
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundColor(accent)

                        Text(L10n.string("listeningUploadAudio"))
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundColor(accentDark)

                        Text(L10n.string("listeningAudioFormats"))
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(AppColors.textSecondary)

                        Button {
                            viewModel.showFileImporter = true
                        } label: {
                            Text(L10n.string("listeningChooseFile"))
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(accentDark)
                                .padding(.horizontal, 18)
                                .frame(height: 40)
                                .background(accent.opacity(0.12))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
                .stroke(
                    viewModel.selectedFileName == nil ? accent.opacity(0.25) : Color.clear,
                    style: StrokeStyle(lineWidth: 1.5, dash: viewModel.selectedFileName == nil ? [6, 4] : [])
                )
        )
    }

    private var infoNote: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(accent)
            Text(L10n.string("listeningAudioPrivacy"))
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous)
                .fill(accent.opacity(0.08))
        )
    }
}

#Preview {
    NavigationStack {
        ImportAudioSetupView()
    }
}
