import SwiftUI

struct ShadowingSetupView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedLanguage: GrammarLanguage = .english
    @State private var selectedLevel: EssayDifficulty = .b1
    @State private var selectedCategory: ShadowingCategory = .daily
    @State private var showSession = false

    private let accent = ShadowingTheme.accent
    private let accentDark = ShadowingTheme.accentDark
    private let categories = ShadowingCategory.allCases

    private var columns: [GridItem] {
        [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]
    }

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

                    sectionTitle("Phrase set")
                    categoryGrid

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
        .navigationDestination(isPresented: $showSession) {
            ShadowingView(
                setup: SpeakingConversationSetup(
                    language: selectedLanguage,
                    level: selectedLevel,
                    scenario: nil,
                    length: .short
                ),
                category: selectedCategory
            )
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Shadowing")
                    .font(.system(size: Layout.homeHeaderTitleSize, weight: .bold, design: .rounded))
                    .foregroundColor(accentDark)

                Text("Listen, repeat, and improve pronunciation.")
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

    // MARK: - Category Grid

    private var categoryGrid: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(categories) { category in
                let isSelected = selectedCategory == category
                Button {
                    withAnimation(.easeInOut(duration: 0.16)) { selectedCategory = category }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: category.systemImage)
                            .font(.system(size: 14, weight: .semibold))
                        Text(category.title)
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
                .buttonStyle(ShadowingPressStyle())
                .hoverEffect(.lift)
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
                Image(systemName: "headphones")
                    .font(.system(size: 26, weight: .medium))
                    .foregroundColor(accent)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(selectedCategory.title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(accentDark)
                Text("Listen and repeat \(selectedCategory.title.lowercased()) in \(selectedLanguage.title) · \(selectedLevel.title).")
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

    // MARK: - Start Button

    private var startButton: some View {
        Button { showSession = true } label: {
            HStack(spacing: 8) {
                Image(systemName: "headphones")
                    .font(.system(size: Layout.convSetupStartButtonTextSize - 2, weight: .bold))
                Text("Start Shadowing")
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
        .buttonStyle(ShadowingPressStyle())
        .hoverEffect(.lift)
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: Layout.homeSectionTitleSize, weight: .bold, design: .rounded))
            .foregroundColor(accentDark)
            .padding(.top, Layout.homeSectionTitleTopPadding)
    }
}

struct ShadowingPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

#Preview {
    NavigationStack {
        ShadowingSetupView()
    }
}
