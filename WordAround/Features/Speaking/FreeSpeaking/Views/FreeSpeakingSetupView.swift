import SwiftUI

struct FreeSpeakingSetupView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedLanguage: GrammarLanguage = .english
    @State private var selectedLevel: EssayDifficulty = .a2
    @State private var selectedLength: ConversationLength = .short
    @State private var showSession = false

    private let lengths = ConversationLength.allCases
    private let green = AppColors.greenAccent
    private let greenDark = AppColors.greenTitle

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
                        accent: green,
                        accentDark: greenDark
                    )

                    sectionTitle("Level")
                    DifficultySelectorView(
                        selectedDifficulty: selectedLevel,
                        onSelect: { selectedLevel = $0 },
                        accent: green,
                        accentDark: greenDark
                    )

                    sectionTitle("Session length")
                    durationPicker

                    sectionTitle("Preview")
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

            startButton
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
                )
            )
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Free Speaking")
                    .font(.system(
                        size: Layout.homeHeaderTitleSize,
                        weight: .bold,
                        design: .rounded
                    ))
                    .foregroundColor(greenDark)

                Text("Speak freely on a topic and get feedback.")
                    .font(.system(
                        size: Layout.homeHeaderSubtitleSize,
                        weight: .medium,
                        design: .rounded
                    ))
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
                        .font(.system(
                            size: Layout.flashcardDetailTopButtonIconSize,
                            weight: .bold
                        ))
                        .foregroundColor(greenDark)
                        .frame(
                            width: Layout.flashcardDetailTopButtonSize,
                            height: Layout.flashcardDetailTopButtonSize
                        )
                        .background(green.opacity(0.10))
                        .overlay(
                            Circle().stroke(green.opacity(0.22), lineWidth: 1)
                        )
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
        FreeSpeakingTopicCardView(
            title: "AI-generated topic",
            description: "We'll pick a fresh topic for \(selectedLanguage.title) · \(selectedLevel.title) when you start.",
            chips: [selectedLevel.title, selectedLength.title, "Auto"]
        )
    }

    // MARK: - Duration Picker

    private var durationPicker: some View {
        HStack(spacing: Layout.convSetupGridSpacing) {
            ForEach(lengths) { length in
                let isSelected = selectedLength == length
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        selectedLength = length
                    }
                } label: {
                    Text(length.title)
                        .font(.system(
                            size: Layout.convSetupDurationChipTextSize,
                            weight: .bold,
                            design: .rounded
                        ))
                        .foregroundColor(isSelected ? .white : greenDark)
                        .frame(maxWidth: .infinity)
                        .frame(height: Layout.convSetupDurationChipHeight)
                        .background(isSelected ? green : green.opacity(0.10))
                        .clipShape(RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous)
                                .stroke(isSelected ? Color.clear : green.opacity(0.22), lineWidth: 1)
                        )
                        .shadow(
                            color: isSelected ? green.opacity(0.22) : Color.clear,
                            radius: isSelected ? 10 : 0,
                            x: 0,
                            y: isSelected ? 4 : 0
                        )
                }
                .buttonStyle(PressableScaleButtonStyle())
                .hoverEffect(.lift)
            }
        }
    }

    // MARK: - Start Button

    private var startButton: some View {
        Button { showSession = true } label: {
            HStack(spacing: 8) {
                Image(systemName: "mic.fill")
                    .font(.system(size: Layout.convSetupStartButtonTextSize - 2, weight: .bold))
                Text("Start Free Speaking")
                    .font(.system(
                        size: Layout.convSetupStartButtonTextSize,
                        weight: .bold,
                        design: .rounded
                    ))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: Layout.convSetupStartButtonHeight + (Layout.isPadLike ? 6 : 0))
            .background(
                LinearGradient(
                    colors: [green, greenDark],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(
                cornerRadius: Layout.convSetupStartButtonCornerRadius,
                style: .continuous
            ))
            .shadow(color: green.opacity(0.30), radius: 16, x: 0, y: 8)
        }
        .buttonStyle(PressableScaleButtonStyle())
        .hoverEffect(.lift)
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(
                size: Layout.homeSectionTitleSize,
                weight: .bold,
                design: .rounded
            ))
            .foregroundColor(greenDark)
            .padding(.top, Layout.homeSectionTitleTopPadding)
    }
}

// MARK: - Press Style

/// Subtle scale-down on press for green action elements. Lives here
/// (file-private) so we don't introduce a shared button style.
private struct PressableScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

#Preview {
    NavigationStack {
        FreeSpeakingSetupView()
    }
}
