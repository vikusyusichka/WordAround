import SwiftUI

struct AIConversationSetupView: View {
    @Environment(\.dismiss) private var dismiss

    var onExitToSpeaking: (() -> Void)? = nil

    @State private var selectedLanguage: GrammarLanguage = .english
    @State private var selectedLevel: EssayDifficulty = .b1

    @State private var selectedScenario: ConversationScenario? = nil
    @State private var selectedLength: ConversationLength = .medium
    @State private var showConversation = false

    private let accent = AppColors.primaryBlue
    private let accentDark = AppColors.primaryBlueDark

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColors.appBackground.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: Layout.homeContentSpacing) {
                    SpeakingSetupTopBar(
                        title: L10n.string("aiConvSetupTitle"),
                        subtitle: L10n.string("aiConvSetupSubtitle"),
                        accent: accent,
                        accentDark: accentDark,
                        onBack: { dismiss() }
                    )
                    .padding(.bottom, 4)

                    SpeakingSetupSectionTitle(L10n.string("spkSectionLanguage"), accentDark: accentDark)
                    LanguageSelectorView(
                        selectedLanguage: selectedLanguage,
                        onSelect: { selectedLanguage = $0 },
                        accent: accent,
                        accentDark: accentDark
                    )

                    SpeakingSetupSectionTitle(L10n.string("spkSectionLevel"), accentDark: accentDark)
                    DifficultySelectorView(
                        selectedDifficulty: selectedLevel,
                        onSelect: { selectedLevel = $0 },
                        accent: accent,
                        accentDark: accentDark
                    )

                    SpeakingSetupSectionTitle(L10n.string("spkScenario"), accentDark: accentDark)
                    ConversationScenarioPickerView(selectedScenario: selectedScenario) { selectedScenario = $0 }

                    SpeakingSetupSectionTitle(L10n.string("spkSectionSessionLength"), accentDark: accentDark)
                    SpeakingSetupDurationPicker(
                        selection: $selectedLength,
                        accent: accent,
                        accentDark: accentDark
                    )

                    SpeakingSetupSectionTitle(L10n.string("commonPreview"), accentDark: accentDark)
                    previewCard
                        .transition(.opacity.combined(with: .scale(scale: 0.97)))

                    Spacer().frame(height: Layout.convSetupStartButtonHeight + 32)
                }
                .animation(.easeInOut(duration: 0.22), value: selectedScenario?.id)
                .frame(maxWidth: Layout.convContentMaxWidth)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, Layout.homeHorizontalPadding)
                .padding(.top, Layout.homeTopSpacing)
                .padding(.bottom, Layout.homeBottomSafeSpacing)
            }

            SpeakingSetupStartButton(
                title: L10n.string("aiConvStartConversation"),
                icon: "bubble.left.and.bubble.right.fill",
                accent: accent,
                accentDark: accentDark,
                action: { showConversation = true }
            )
            .padding(.horizontal, Layout.homeHorizontalPadding)
            .padding(.bottom, Layout.homeBottomBarBottomPadding)
        }
        .ignoresSafeArea(edges: .bottom)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $showConversation) {
            AIConversationView(
                setup: SpeakingConversationSetup(
                    language: selectedLanguage,
                    level: selectedLevel,
                    scenario: selectedScenario,
                    length: selectedLength
                ),
                onExitToSetup: { showConversation = false },
                onExitToSpeaking: onExitToSpeaking
            )
        }
    }

    @ViewBuilder
    private var previewCard: some View {
        if let scenario = selectedScenario {
            ConversationScenarioCardView(
                title: scenario.title,
                description: scenario.description,
                icon: scenario.icon,
                chips: [selectedLevel.title, selectedLength.title, scenario.category]
            )
        } else {
            ConversationScenarioCardView(
                title: L10n.string("aiConvAIGeneratedTopic"),
                description: String(format: L10n.string("aiConvAIGenTopicDescFmt"), selectedLanguage.title, selectedLevel.title),
                icon: "sparkles",
                chips: [selectedLevel.title, selectedLength.title, L10n.string("aiConvAutoChip")]
            )
        }
    }
}

#Preview {
    NavigationStack {
        AIConversationSetupView()
    }
}
