import SwiftUI

struct ListenFromTextSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ListenFromTextSetupViewModel()

    var onExitToListening: (() -> Void)? = nil

    private let accent = ListeningTheme.listenFromTextAccent
    private let accentDark = ListeningTheme.listenFromTextDark

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColors.appBackground.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: Layout.homeContentSpacing) {
                    ListeningSetupTopBar(
                        title: "Listen From Text",
                        subtitle: "Paste text and turn it into listening practice.",
                        accent: accent,
                        accentDark: accentDark,
                        onBack: { dismiss() }
                    )
                    .padding(.bottom, 4)

                    ListeningSetupSectionTitle("Language", accentDark: accentDark)
                    LanguageSelectorView(
                        selectedLanguage: viewModel.selectedLanguage,
                        onSelect: { viewModel.selectedLanguage = $0 },
                        accent: accent,
                        accentDark: accentDark
                    )

                    ListeningSetupSectionTitle("Level", accentDark: accentDark)
                    DifficultySelectorView(
                        selectedDifficulty: viewModel.selectedLevel,
                        onSelect: { viewModel.selectedLevel = $0 },
                        accent: accent,
                        accentDark: accentDark
                    )

                    ListeningSetupSectionTitle("Voice Settings", accentDark: accentDark)
                    ListeningVoiceSettingsCard(
                        voiceSpeed: $viewModel.voiceSpeed,
                        voiceType: $viewModel.voiceType,
                        showTextWhileListening: $viewModel.showTextWhileListening,
                        accent: accent,
                        accentDark: accentDark
                    )

                    ListeningSetupSectionTitle("Questions", accentDark: accentDark)
                    ListeningQuestionSettingsCard(
                        addQuestions: $viewModel.addQuestions,
                        questionCount: $viewModel.questionCount,
                        selectedTypes: $viewModel.questionTypes,
                        accent: accent,
                        accentDark: accentDark
                    )

                    ListeningSetupSectionTitle("Text Input", accentDark: accentDark)
                    textInputCard

                    if let validationMessage = viewModel.validationMessage {
                        Text(validationMessage)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(Color(red: 0.95, green: 0.42, blue: 0.40))
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
                title: "Start Listening",
                icon: "headphones",
                accent: accent,
                accentDark: accentDark,
                action: viewModel.startListening
            )
            .padding(.horizontal, Layout.homeHorizontalPadding)
            .padding(.bottom, Layout.homeBottomBarBottomPadding)
        }
        .ignoresSafeArea(edges: .bottom)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $viewModel.showSession) {
            ListenFromTextSessionView(
                setup: viewModel.makeSetup(),
                onExitToSetup: { viewModel.showSession = false },
                onExitToListening: onExitToListening
            )
        }
    }

    private var textInputCard: some View {
        ListeningWhiteCard {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Optional title")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)

                    TextField("Give your text a name", text: $viewModel.optionalTitle)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(accentDark)
                        .padding(.horizontal, 14)
                        .frame(height: 48)
                        .background(fieldBackground)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Text")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)

                    ZStack(alignment: .topLeading) {
                        if viewModel.textBody.isEmpty {
                            Text("Paste your text here...")
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundColor(AppColors.textSecondary.opacity(0.65))
                                .padding(.top, 12)
                                .padding(.horizontal, 10)
                                .allowsHitTesting(false)
                        }

                        TextEditor(text: $viewModel.textBody)
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(accentDark)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: Layout.isPadLike ? 200 : 160)
                            .padding(8)
                    }
                    .background(fieldBackground)
                }

                Text("Recommended: 80–500 words.")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.mutedText)
            }
        }
    }

    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous)
            .fill(accent.opacity(0.06))
            .overlay(
                RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous)
                    .stroke(accent.opacity(0.12), lineWidth: 1)
            )
    }
}

#Preview {
    NavigationStack {
        ListenFromTextSetupView()
    }
}
