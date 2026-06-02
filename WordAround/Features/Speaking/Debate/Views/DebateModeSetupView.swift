import SwiftUI

struct DebateModeSetupView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedLanguage: GrammarLanguage = .english
    @State private var selectedLevel: EssayDifficulty = .b1
    @State private var selectedLength: ConversationLength = .medium
    @State private var selectedSide: DebateSide = .agree
    @State private var showDebate = false

    private let accent = DebateTheme.accent
    private let accentDark = DebateTheme.accentDark

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColors.appBackground.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: Layout.homeContentSpacing) {
                    SpeakingSetupTopBar(
                        title: "Debate Mode",
                        subtitle: "Defend your ideas against an AI opponent.",
                        accent: accent,
                        accentDark: accentDark,
                        onBack: { dismiss() }
                    )
                    .padding(.bottom, 4)

                    SpeakingSetupSectionTitle("Language", accentDark: accentDark)
                    LanguageSelectorView(
                        selectedLanguage: selectedLanguage,
                        onSelect: { selectedLanguage = $0 },
                        accent: accent,
                        accentDark: accentDark
                    )

                    SpeakingSetupSectionTitle("Level", accentDark: accentDark)
                    DifficultySelectorView(
                        selectedDifficulty: selectedLevel,
                        onSelect: { selectedLevel = $0 },
                        accent: accent,
                        accentDark: accentDark
                    )

                    SpeakingSetupSectionTitle("Your side", accentDark: accentDark)
                    DebateSidePickerView(selectedSide: selectedSide) { selectedSide = $0 }

                    SpeakingSetupSectionTitle("Session length", accentDark: accentDark)
                    SpeakingSetupDurationPicker(
                        selection: $selectedLength,
                        accent: accent,
                        accentDark: accentDark
                    )

                    SpeakingSetupSectionTitle("Preview", accentDark: accentDark)
                    previewCard

                    Spacer().frame(height: Layout.convSetupStartButtonHeight + 32)
                }
                .frame(maxWidth: Layout.convContentMaxWidth)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, Layout.homeHorizontalPadding)
                .padding(.top, Layout.homeTopSpacing)
                .padding(.bottom, Layout.homeBottomSafeSpacing)
            }

            SpeakingSetupStartButton(
                title: "Start Debate",
                icon: "person.2.fill",
                accent: accent,
                accentDark: accentDark,
                action: { showDebate = true }
            )
            .padding(.horizontal, Layout.homeHorizontalPadding)
            .padding(.bottom, Layout.homeBottomBarBottomPadding)
        }
        .ignoresSafeArea(edges: .bottom)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $showDebate) {
            DebateModeView(
                setup: SpeakingConversationSetup(
                    language: selectedLanguage,
                    level: selectedLevel,
                    scenario: nil,
                    length: selectedLength
                ),
                side: selectedSide
            )
        }
    }

    private var previewCard: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(accent.opacity(0.12))
                    .frame(width: 64, height: 64)
                Image(systemName: "bubble.left.and.text.bubble.right.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(accent)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("AI-generated debate")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(accentDark)
                Text("We'll pick a topic for \(selectedLanguage.title) · \(selectedLevel.title) and argue the \(opposingSideText) side.")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.94))
                .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 5)
        )
    }

    private var opposingSideText: String {
        switch selectedSide {
        case .agree:      return "opposing"
        case .disagree:   return "supporting"
        case .surpriseMe: return "other"
        }
    }
}

#Preview {
    NavigationStack {
        DebateModeSetupView()
    }
}
