import SwiftUI

struct FreeSpeakingSetupView: View {
    @Environment(\.dismiss) private var dismiss

    var onExitToSpeaking: (() -> Void)? = nil

    @State private var selectedLanguage: GrammarLanguage = .english
    @State private var selectedLevel: EssayDifficulty = .a2
    @State private var selectedLength: ConversationLength = .short
    @State private var showSession = false

    private let green = AppColors.greenAccent
    private let greenDark = AppColors.greenTitle

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColors.appBackground.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: Layout.homeContentSpacing) {
                    SpeakingSetupTopBar(
                        title: L10n.string("spkFreeSpeaking"),
                        subtitle: L10n.string("fsSubtitle"),
                        accent: green,
                        accentDark: greenDark,
                        onBack: { dismiss() }
                    )
                    .padding(.bottom, 4)

                    SpeakingSetupSectionTitle(L10n.string("spkSectionLanguage"), accentDark: greenDark)
                    LanguageSelectorView(
                        selectedLanguage: selectedLanguage,
                        onSelect: { selectedLanguage = $0 },
                        accent: green,
                        accentDark: greenDark
                    )

                    SpeakingSetupSectionTitle(L10n.string("spkSectionLevel"), accentDark: greenDark)
                    DifficultySelectorView(
                        selectedDifficulty: selectedLevel,
                        onSelect: { selectedLevel = $0 },
                        accent: green,
                        accentDark: greenDark
                    )

                    SpeakingSetupSectionTitle(L10n.string("spkSectionSessionLength"), accentDark: greenDark)
                    SpeakingSetupDurationPicker(
                        selection: $selectedLength,
                        accent: green,
                        accentDark: greenDark
                    )

                    SpeakingSetupSectionTitle(L10n.string("commonPreview"), accentDark: greenDark)
                    previewCard
                        .animation(.easeInOut(duration: 0.22), value: selectedLanguage)
                        .animation(.easeInOut(duration: 0.22), value: selectedLevel)
                        .animation(.easeInOut(duration: 0.22), value: selectedLength)

                    Spacer().frame(height: Layout.convSetupStartButtonHeight + 32)
                }
                .frame(maxWidth: Layout.convContentMaxWidth)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, Layout.homeHorizontalPadding)
                .padding(.top, Layout.homeTopSpacing)
                .padding(.bottom, Layout.homeBottomSafeSpacing)
            }

            SpeakingSetupStartButton(
                title: L10n.string("fsStartFreeSpeaking"),
                icon: "mic.fill",
                accent: green,
                accentDark: greenDark,
                action: { showSession = true }
            )
            .padding(.horizontal, Layout.homeHorizontalPadding)
            .padding(.bottom, Layout.homeBottomBarBottomPadding)
        }
        .ignoresSafeArea(edges: .bottom)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $showSession) {
            FreeSpeakingView(
                setup: SpeakingConversationSetup(
                    language: selectedLanguage,
                    level: selectedLevel,
                    scenario: nil,
                    length: selectedLength
                ),
                onExitToSetup: { showSession = false },
                onExitToSpeaking: onExitToSpeaking
            )
        }
    }

    private var previewCard: some View {
        FreeSpeakingTopicCardView(
            title: L10n.string("aiConvAIGeneratedTopic"),
            description: String(format: L10n.string("fsTopicDescFmt"), selectedLanguage.title, selectedLevel.title),
            chips: [selectedLevel.title, selectedLength.title, L10n.string("aiConvAutoChip")]
        )
    }
}

#Preview {
    NavigationStack {
        FreeSpeakingSetupView()
    }
}
