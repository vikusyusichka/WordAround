import SwiftUI

struct DebateModeSetupView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedLanguage: GrammarLanguage = .english
    @State private var selectedLevel: EssayDifficulty = .b1
    @State private var selectedLength: ConversationLength = .medium
    @State private var selectedSide: DebateSide = .agree
    @State private var showDebate = false

    private let lengths = ConversationLength.allCases
    private let accent = DebateTheme.accent
    private let accentDark = DebateTheme.accentDark

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColors.appBackground.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: Layout.homeContentSpacing) {
                    topBar
                        .padding(.bottom, 4)

                    sectionTitle("Language")
                    LanguageSelectorView(
                        selectedLanguage: selectedLanguage,
                        onSelect: { selectedLanguage = $0 },
                        accent: accent,
                        accentDark: accentDark
                    )

                    sectionTitle("Level")
                    DifficultySelectorView(
                        selectedDifficulty: selectedLevel,
                        onSelect: { selectedLevel = $0 },
                        accent: accent,
                        accentDark: accentDark
                    )

                    sectionTitle("Your side")
                    DebateSidePickerView(selectedSide: selectedSide) { selectedSide = $0 }

                    sectionTitle("Session length")
                    durationPicker

                    sectionTitle("Preview")
                    previewCard

                    Spacer().frame(height: Layout.convSetupStartButtonHeight + 32)
                }
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

    // MARK: - Top Bar

    private var topBar: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Debate Mode")
                    .font(.system(size: Layout.homeHeaderTitleSize, weight: .bold, design: .rounded))
                    .foregroundColor(accentDark)

                Text("Defend your ideas against an AI opponent.")
                    .font(.system(size: Layout.homeHeaderSubtitleSize, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.mutedText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, Layout.flashcardDetailTopButtonSize + 10)
            .padding(.trailing, 10)

            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: Layout.flashcardDetailTopButtonIconSize, weight: .bold))
                        .foregroundColor(accentDark)
                        .frame(width: Layout.flashcardDetailTopButtonSize, height: Layout.flashcardDetailTopButtonSize)
                        .background(accent.opacity(0.10))
                        .overlay(Circle().stroke(accent.opacity(0.22), lineWidth: 1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .hoverEffect(.lift)

                Spacer()
            }
        }
    }

    // MARK: - Preview Card

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

    // MARK: - Duration Picker

    private var durationPicker: some View {
        HStack(spacing: Layout.convSetupGridSpacing) {
            ForEach(lengths) { length in
                let isSelected = selectedLength == length
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) { selectedLength = length }
                } label: {
                    Text(length.title)
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
                        .shadow(
                            color: isSelected ? accent.opacity(0.22) : Color.clear,
                            radius: isSelected ? 10 : 0,
                            x: 0,
                            y: isSelected ? 4 : 0
                        )
                }
                .buttonStyle(DebatePressStyle())
                .hoverEffect(.lift)
            }
        }
    }

    // MARK: - Start Button

    private var startButton: some View {
        Button { showDebate = true } label: {
            HStack(spacing: 8) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: Layout.convSetupStartButtonTextSize - 2, weight: .bold))
                Text("Start Debate")
                    .font(.system(size: Layout.convSetupStartButtonTextSize, weight: .bold, design: .rounded))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: Layout.convSetupStartButtonHeight + (Layout.isPadLike ? 6 : 0))
            .background(
                LinearGradient(colors: [accent, accentDark], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: Layout.convSetupStartButtonCornerRadius, style: .continuous))
            .shadow(color: accent.opacity(0.30), radius: 16, x: 0, y: 8)
        }
        .buttonStyle(DebatePressStyle())
        .hoverEffect(.lift)
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: Layout.homeSectionTitleSize, weight: .bold, design: .rounded))
            .foregroundColor(accentDark)
            .padding(.top, Layout.homeSectionTitleTopPadding)
    }
}

struct DebatePressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

#Preview {
    NavigationStack {
        DebateModeSetupView()
    }
}
