import SwiftUI

struct AIConversationSetupView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedLanguage: GrammarLanguage = .english
    @State private var selectedLevel: EssayDifficulty = .b1

    @State private var selectedScenario: ConversationScenario? = nil
    @State private var selectedLength: ConversationLength = .medium
    @State private var showConversation = false

    private let lengths = ConversationLength.allCases

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColors.appBackground.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: Layout.homeContentSpacing) {
                    topBar
                        .padding(.bottom, 4)

                    sectionTitle("Language")
                    LanguageSelectorView(selectedLanguage: selectedLanguage) { selectedLanguage = $0 }

                    sectionTitle("Level")
                    DifficultySelectorView(selectedDifficulty: selectedLevel) { selectedLevel = $0 }

                    sectionTitle("Scenario")
                    ConversationScenarioPickerView(selectedScenario: selectedScenario) { selectedScenario = $0 }

                    sectionTitle("Session length")
                    durationPicker

                    sectionTitle("Preview")
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

            startButton
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
                )
            )
        }
    }

    private var topBar: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Set up conversation")
                    .font(.system(
                        size: Layout.homeHeaderTitleSize,
                        weight: .bold,
                        design: .rounded
                    ))
                    .foregroundColor(AppColors.primaryBlueDark)

                Text("Choose what to practice today.")
                    .font(.system(
                        size: Layout.homeHeaderSubtitleSize,
                        weight: .medium,
                        design: .rounded
                    ))
                    .foregroundColor(AppColors.mutedText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, Layout.flashcardDetailTopButtonSize + 10)
            .padding(.trailing, 10)

            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(
                            size: Layout.flashcardDetailTopButtonIconSize,
                            weight: .bold
                        ))
                        .foregroundColor(AppColors.primaryBlueDark)
                        .frame(
                            width: Layout.flashcardDetailTopButtonSize,
                            height: Layout.flashcardDetailTopButtonSize
                        )
                        .background(Color.white.opacity(0.82))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Spacer()
            }
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
                title: "AI-generated topic",
                description: "We'll pick a fresh topic that fits \(selectedLanguage.title) · \(selectedLevel.title) when you start.",
                icon: "sparkles",
                chips: [selectedLevel.title, selectedLength.title, "Auto"]
            )
        }
    }

    private var durationPicker: some View {
        HStack(spacing: Layout.convSetupGridSpacing) {
            ForEach(lengths) { length in
                let isSelected = selectedLength == length
                Button { selectedLength = length } label: {
                    Text(length.title)
                        .font(.system(
                            size: Layout.convSetupDurationChipTextSize,
                            weight: .bold,
                            design: .rounded
                        ))
                        .foregroundColor(isSelected ? .white : AppColors.primaryBlue)
                        .frame(maxWidth: .infinity)
                        .frame(height: Layout.convSetupDurationChipHeight)
                        .background(isSelected ? AppColors.primaryBlue : AppColors.primaryBlue.opacity(0.09))
                        .clipShape(RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous)
                                .stroke(isSelected ? Color.clear : AppColors.primaryBlue.opacity(0.12), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .animation(.easeInOut(duration: 0.18), value: isSelected)
            }
        }
    }

    private var startButton: some View {
        Button {
            showConversation = true
        } label: {
            Text("Start Conversation")
                .font(.system(
                    size: Layout.convSetupStartButtonTextSize,
                    weight: .bold,
                    design: .rounded
                ))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: Layout.convSetupStartButtonHeight)
                .background(AppColors.primaryBlue)
                .clipShape(RoundedRectangle(cornerRadius: Layout.convSetupStartButtonCornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(
                size: Layout.homeSectionTitleSize,
                weight: .bold,
                design: .rounded
            ))
            .foregroundColor(AppColors.primaryBlueDark)
            .padding(.top, Layout.homeSectionTitleTopPadding)
    }
}

#Preview {
    NavigationStack {
        AIConversationSetupView()
    }
}
