import SwiftUI

struct PronunciationTrainerSetupView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedLanguage: GrammarLanguage = .english
    @State private var selectedLevel: EssayDifficulty = .b1
    @State private var selectedDifficulty: PronunciationDifficulty = .balanced
    @State private var selectedFocus: PronunciationFocus = .mixed
    @State private var showSession = false

    private let accent = PronunciationTrainerTheme.accent
    private let accentDark = PronunciationTrainerTheme.accentDark
    private let difficulties = PronunciationDifficulty.allCases
    private let focuses = PronunciationFocus.allCases

    private var focusColumns: [GridItem] {
        [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColors.appBackground.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: Layout.homeContentSpacing) {
                    SpeakingSetupTopBar(
                        title: "Pronunciation Trainer",
                        subtitle: "Focus on difficult sounds and words.",
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

                    SpeakingSetupSectionTitle("Difficulty", accentDark: accentDark)
                    difficultyPicker

                    SpeakingSetupSectionTitle("Focus area", accentDark: accentDark)
                    focusGrid

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
                title: "Start Training",
                icon: "waveform",
                accent: accent,
                accentDark: accentDark,
                action: { showSession = true }
            )
            .padding(.horizontal, Layout.homeHorizontalPadding)
            .padding(.bottom, Layout.homeBottomBarBottomPadding)
        }
        .ignoresSafeArea(edges: .bottom)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $showSession) {
            PronunciationTrainerView(
                setup: SpeakingConversationSetup(
                    language: selectedLanguage,
                    level: selectedLevel,
                    scenario: nil,
                    length: .short
                ),
                difficulty: selectedDifficulty,
                focus: selectedFocus
            )
        }
    }


    private var difficultyPicker: some View {
        HStack(spacing: Layout.convSetupGridSpacing) {
            ForEach(difficulties) { difficulty in
                let isSelected = selectedDifficulty == difficulty
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) { selectedDifficulty = difficulty }
                } label: {
                    Text(difficulty.title)
                        .font(.system(size: Layout.convSetupDurationChipTextSize, weight: .bold, design: .rounded))
                        .foregroundColor(isSelected ? .white : accentDark)
                        .frame(maxWidth: .infinity)
                        .frame(height: Layout.convSetupDurationChipHeight)
                        .background(isSelected ? accent : accent.opacity(0.10))
                        .clipShape(RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous)
                                .stroke(isSelected ? Color.clear : accent.opacity(0.22), lineWidth: 1)
                        )
                        .shadow(color: isSelected ? accent.opacity(0.22) : .clear, radius: isSelected ? 10 : 0, x: 0, y: isSelected ? 4 : 0)
                }
                .buttonStyle(SpeakingSetupPressStyle())
                .hoverEffect(.lift)
            }
        }
    }


    private var focusGrid: some View {
        LazyVGrid(columns: focusColumns, spacing: 10) {
            ForEach(focuses) { focus in
                let isSelected = selectedFocus == focus
                Button {
                    withAnimation(.easeInOut(duration: 0.16)) { selectedFocus = focus }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: focus.systemImage).font(.system(size: 14, weight: .semibold))
                        Text(focus.title)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        Spacer(minLength: 0)
                    }
                    .foregroundColor(isSelected ? .white : accentDark)
                    .padding(.horizontal, 14)
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
                    .background(isSelected ? accent : accent.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous)
                            .stroke(isSelected ? Color.clear : accent.opacity(0.22), lineWidth: 1)
                    )
                    .shadow(color: isSelected ? accent.opacity(0.22) : .clear, radius: isSelected ? 10 : 0, x: 0, y: isSelected ? 4 : 0)
                }
                .buttonStyle(SpeakingSetupPressStyle())
                .hoverEffect(.lift)
            }
        }
    }


    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(accent.opacity(0.12))
                        .frame(width: 60, height: 60)
                    Image(systemName: "waveform")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(accent)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(sample.text)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(accentDark)
                    Text("Sample item · \(selectedLanguage.title) · \(selectedDifficulty.title)")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                }
                Spacer(minLength: 0)
            }
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "lightbulb.fill").font(.system(size: 12, weight: .semibold)).foregroundColor(accent)
                Text(sample.tip)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(accentDark.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.94))
                .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 5)
        )
    }

    private var sample: (text: String, tip: String) {
        switch selectedLanguage {
        case .spanish: return ("perro", "Try to roll the rr sound.")
        case .french:  return ("rue", "Use the French r, then a rounded u.")
        case .german:  return ("schön", "Round the lips for the ö sound.")
        default:       return ("WORLD", "Focus on the ending sound.")
        }
    }
}

#Preview {
    NavigationStack { PronunciationTrainerSetupView() }
}
