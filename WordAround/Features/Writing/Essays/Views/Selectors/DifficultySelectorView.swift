import SwiftUI

struct DifficultySelectorView: View {
    let selectedDifficulty: EssayDifficulty
    let onSelect: (EssayDifficulty) -> Void

    /// Optional theme override. When omitted the selector keeps its
    /// original blue look — every existing call site is unchanged.
    /// Free Speaking opts into green by passing greenAccent / greenTitle.
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
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: Layout.essaySelectorIconSize, weight: .semibold))
                    .foregroundColor(accent)

                VStack(alignment: .leading, spacing: Layout.essaySelectorLabelSpacing) {
                    Text("Level")
                        .font(.system(size: Layout.essaySelectorLabelSize, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)

                    Text(selectedDifficulty.title)
                        .font(.system(size: Layout.essaySelectorTitleSize, weight: .bold, design: .rounded))
                        .foregroundColor(accentDark)
                }

                Spacer(minLength: 6)

                Text(selectedDifficulty.helperIntensityTitle)
                    .font(.system(size: Layout.essaySelectorBadgeTextSize, weight: .bold, design: .rounded))
                    .foregroundColor(accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
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

    private var optionsList: some View {
        VStack(spacing: Layout.essaySelectorOptionsSpacing) {
            ForEach(EssayDifficulty.allCases) { difficulty in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        onSelect(difficulty)
                        isExpanded = false
                    }
                } label: {
                    HStack(spacing: Layout.essaySelectorOptionContentSpacing) {
                        Text(difficulty.title)
                            .font(.system(size: Layout.essaySelectorOptionBadgeTextSize, weight: .bold, design: .rounded))
                            .foregroundColor(selectedDifficulty == difficulty ? .white : accent)
                            .frame(
                                width: Layout.essaySelectorOptionLevelWidth,
                                height: Layout.essaySelectorOptionBadgeHeight
                            )
                            .background(selectedDifficulty == difficulty ? accent : accent.opacity(0.08))
                            .clipShape(Capsule())

                        VStack(alignment: .leading, spacing: Layout.essaySelectorLabelSpacing) {
                            Text(difficulty.helperIntensityTitle)
                                .font(.system(size: Layout.essaySelectorOptionTitleSize, weight: .bold, design: .rounded))
                                .foregroundColor(accentDark)

                            Text("\(difficulty.hintsLimit) hints • \(difficulty.allowsTranslation ? "translation" : "no translation")")
                                .font(.system(size: Layout.essaySelectorOptionSubtitleSize, weight: .semibold, design: .rounded))
                                .foregroundColor(AppColors.textSecondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }

                        Spacer(minLength: 0)

                        if selectedDifficulty == difficulty {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: Layout.essaySelectorCheckmarkSize, weight: .semibold))
                                .foregroundColor(accent)
                        }
                    }
                    .contentShape(Rectangle())
                    .padding(.horizontal, Layout.essaySelectorOptionHorizontalPadding)
                    .padding(.vertical, Layout.essaySelectorOptionVerticalPadding)
                    .background(selectedDifficulty == difficulty ? accent.opacity(0.07) : Color.clear)
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
    DifficultySelectorView(
        selectedDifficulty: .b1,
        onSelect: { _ in }
    )
    .padding()
    .background(AppColors.appBackground)
}
