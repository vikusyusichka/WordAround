import SwiftUI

struct ShadowingSetupView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedLanguage: GrammarLanguage = .english
    @State private var selectedLevel: EssayDifficulty = .b1
    @State private var selectedCategory: ShadowingCategory = .daily
    @State private var showSession = false

    private let accent = ShadowingTheme.accent
    private let accentDark = ShadowingTheme.accentDark
    private let categories = ShadowingCategory.selectableCases

    private var columns: [GridItem] {
        [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColors.appBackground.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: Layout.homeContentSpacing) {
                    SpeakingSetupTopBar(
                        title: L10n.string("spkShadowing"),
                        subtitle: L10n.string("spkShadowingSubtitle"),
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

                    SpeakingSetupSectionTitle(L10n.string("spkSectionPhraseSet"), accentDark: accentDark)
                    categoryGrid

                    SpeakingSetupSectionTitle(L10n.string("commonPreview"), accentDark: accentDark)
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
                title: L10n.string("spkStartShadowing"),
                icon: "headphones",
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
                .buttonStyle(SpeakingSetupPressStyle())
                .hoverEffect(.lift)
            }
        }
    }

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
                Text(String(format: L10n.string("spkListenAndRepeatFmt"), selectedCategory.title.lowercased(), selectedLanguage.title, selectedLevel.title))
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
}

#Preview {
    NavigationStack {
        ShadowingSetupView()
    }
}
