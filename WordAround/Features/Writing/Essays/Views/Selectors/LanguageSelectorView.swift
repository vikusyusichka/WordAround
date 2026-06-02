import SwiftUI

struct LanguageSelectorView: View {
    let selectedLanguage: GrammarLanguage
    let onSelect: (GrammarLanguage) -> Void

    var label: String = "Language"
    var excludedLanguages: Set<GrammarLanguage> = []
    var accent: Color = AppColors.primaryBlue
    var accentDark: Color = AppColors.primaryBlueDark

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.essaySelectorOuterSpacing) {
            selectorButton

            if isExpanded {
                optionsList
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: Layout.essaySelectorAnimationDuration), value: isExpanded)
    }

    private var selectorButton: some View {
        Button {
            withAnimation(.easeInOut(duration: Layout.essaySelectorAnimationDuration)) {
                isExpanded.toggle()
            }
        } label: {
            HStack(spacing: Layout.essaySelectorButtonContentSpacing) {
                Image(systemName: "globe.europe.africa.fill")
                    .font(.system(size: Layout.essaySelectorIconSize, weight: .semibold))
                    .foregroundColor(accent)

                VStack(alignment: .leading, spacing: Layout.essaySelectorLabelSpacing) {
                    Text(label)
                        .font(.system(size: Layout.essaySelectorLabelSize, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)

                    Text(selectedLanguage.title)
                        .font(.system(size: Layout.essaySelectorTitleSize, weight: .bold, design: .rounded))
                        .foregroundColor(accentDark)
                        .lineLimit(1)
                }

                Spacer(minLength: 6)

                Text(selectedLanguage.shortTitle)
                    .font(.system(size: Layout.essaySelectorBadgeTextSize, weight: .bold, design: .rounded))
                    .foregroundColor(accent)
                    .padding(.horizontal, Layout.essaySelectorBadgeHorizontalPadding)
                    .padding(.vertical, Layout.essaySelectorBadgeVerticalPadding)
                    .background(accent.opacity(0.08))
                    .clipShape(Capsule())

                Image(systemName: "chevron.down")
                    .font(.system(size: Layout.essaySelectorChevronSize, weight: .bold))
                    .foregroundColor(AppColors.textSecondary)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
            }
            .contentShape(Rectangle())
            .padding(.horizontal, Layout.essaySelectorHorizontalPadding)
            .padding(.vertical, Layout.essaySelectorVerticalPadding)
            .background(Color.white.opacity(0.86))
            .clipShape(RoundedRectangle(cornerRadius: Layout.essaySelectorCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Layout.essaySelectorCornerRadius, style: .continuous)
                    .stroke(accent.opacity(isExpanded ? 0.18 : 0.08), lineWidth: Layout.essaySelectorBorderWidth)
            )
            .shadow(
                color: Color.black.opacity(Layout.essaySelectorShadowOpacity),
                radius: Layout.essaySelectorShadowRadius,
                x: 0,
                y: Layout.essaySelectorShadowYOffset
            )
        }
        .buttonStyle(.plain)
    }

    private var availableLanguages: [GrammarLanguage] {
        GrammarLanguage.allCases.filter { !excludedLanguages.contains($0) }
    }

    private var optionsList: some View {
        VStack(spacing: Layout.essaySelectorOptionsSpacing) {
            ForEach(availableLanguages) { language in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        onSelect(language)
                        isExpanded = false
                    }
                } label: {
                    HStack(spacing: Layout.essaySelectorOptionContentSpacing) {
                        Text(language.shortTitle)
                            .font(.system(size: Layout.essaySelectorOptionBadgeTextSize, weight: .bold, design: .rounded))
                            .foregroundColor(selectedLanguage == language ? .white : accent)
                            .frame(
                                width: Layout.essaySelectorOptionCodeWidth,
                                height: Layout.essaySelectorOptionBadgeHeight
                            )
                            .background(selectedLanguage == language ? accent : accent.opacity(0.08))
                            .clipShape(Capsule())

                        Text(language.title)
                            .font(.system(size: Layout.essaySelectorOptionTitleSize, weight: .semibold, design: .rounded))
                            .foregroundColor(accentDark)

                        Spacer(minLength: 0)

                        if selectedLanguage == language {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: Layout.essaySelectorCheckmarkSize, weight: .semibold))
                                .foregroundColor(accent)
                        }
                    }
                    .contentShape(Rectangle())
                    .padding(.horizontal, Layout.essaySelectorOptionHorizontalPadding)
                    .padding(.vertical, Layout.essaySelectorOptionVerticalPadding)
                    .background(selectedLanguage == language ? accent.opacity(0.07) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: Layout.essaySelectorOptionCornerRadius, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Layout.essaySelectorOptionsPadding)
        .background(Color.white.opacity(0.96))
        .clipShape(RoundedRectangle(cornerRadius: Layout.essaySelectorCornerRadius, style: .continuous))
        .shadow(
            color: Color.black.opacity(Layout.essaySelectorOptionsShadowOpacity),
            radius: Layout.essaySelectorOptionsShadowRadius,
            x: 0,
            y: Layout.essaySelectorOptionsShadowYOffset
        )
    }
}

#Preview {
    LanguageSelectorView(
        selectedLanguage: .english,
        onSelect: { _ in }
    )
    .padding()
    .background(AppColors.appBackground)
}
