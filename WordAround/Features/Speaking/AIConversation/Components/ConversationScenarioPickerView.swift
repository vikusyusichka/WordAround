import SwiftUI

struct ConversationScenarioPickerView: View {

    let selectedScenario: ConversationScenario?
    let onSelect: (ConversationScenario?) -> Void

    @State private var isExpanded = false

    private let scenarios = ConversationScenario.allScenarios

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
                Image(systemName: iconForSelection)
                    .font(.system(size: Layout.essaySelectorIconSize, weight: .semibold))
                    .foregroundColor(AppColors.primaryBlue)

                VStack(alignment: .leading, spacing: Layout.essaySelectorLabelSpacing) {
                    Text("Scenario")
                        .font(.system(size: Layout.essaySelectorLabelSize, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)

                    Text(titleForSelection)
                        .font(.system(size: Layout.essaySelectorTitleSize, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.primaryBlueDark)
                        .lineLimit(1)
                }

                Spacer(minLength: 6)

                Text(badgeForSelection)
                    .font(.system(size: Layout.essaySelectorBadgeTextSize, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primaryBlue)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                    .padding(.horizontal, Layout.essaySelectorBadgeHorizontalPadding)
                    .padding(.vertical, Layout.essaySelectorBadgeVerticalPadding)
                    .background(AppColors.primaryBlue.opacity(0.08))
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
                    .stroke(AppColors.primaryBlue.opacity(isExpanded ? 0.18 : 0.08), lineWidth: Layout.essaySelectorBorderWidth)
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
            optionRow(
                title: "Auto-generate topic",
                subtitle: "AI picks something for your level",
                icon: "sparkles",
                isSelected: selectedScenario == nil
            ) {
                onSelect(nil)
            }

            ForEach(scenarios) { scenario in
                optionRow(
                    title: scenario.title,
                    subtitle: scenario.description,
                    icon: scenario.systemImage,
                    isSelected: selectedScenario?.id == scenario.id
                ) {
                    onSelect(scenario)
                }
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

    private func optionRow(
        title: String,
        subtitle: String,
        icon: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            action()
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpanded = false
            }
        } label: {
            HStack(spacing: Layout.essaySelectorOptionContentSpacing) {
                Image(systemName: icon)
                    .font(.system(size: Layout.essaySelectorOptionBadgeTextSize, weight: .bold))
                    .foregroundColor(isSelected ? .white : AppColors.primaryBlue)
                    .frame(
                        width: Layout.essaySelectorOptionLevelWidth,
                        height: Layout.essaySelectorOptionBadgeHeight
                    )
                    .background(isSelected ? AppColors.primaryBlue : AppColors.primaryBlue.opacity(0.08))
                    .clipShape(Capsule())

                VStack(alignment: .leading, spacing: Layout.essaySelectorLabelSpacing) {
                    Text(title)
                        .font(.system(size: Layout.essaySelectorOptionTitleSize, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.primaryBlueDark)

                    Text(subtitle)
                        .font(.system(size: Layout.essaySelectorOptionSubtitleSize, weight: .semibold, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                Spacer(minLength: 0)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: Layout.essaySelectorCheckmarkSize, weight: .semibold))
                        .foregroundColor(AppColors.primaryBlue)
                }
            }
            .contentShape(Rectangle())
            .padding(.horizontal, Layout.essaySelectorOptionHorizontalPadding)
            .padding(.vertical, Layout.essaySelectorOptionVerticalPadding)
            .background(isSelected ? AppColors.primaryBlue.opacity(0.07) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: Layout.essaySelectorOptionCornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var titleForSelection: String {
        selectedScenario?.title ?? "Auto-generate topic"
    }

    private var iconForSelection: String {
        selectedScenario?.systemImage ?? "sparkles"
    }

    private var badgeForSelection: String {
        selectedScenario?.category ?? "Auto"
    }
}

#Preview {
    VStack(spacing: 14) {
        ConversationScenarioPickerView(selectedScenario: nil, onSelect: { _ in })
        ConversationScenarioPickerView(selectedScenario: ConversationScenario.allScenarios[0], onSelect: { _ in })
    }
    .padding()
    .background(AppColors.appBackground)
}
