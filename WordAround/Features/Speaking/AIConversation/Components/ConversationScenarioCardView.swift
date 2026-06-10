import SwiftUI

struct ConversationScenarioCardView: View {
    let title: String
    let description: String
    let icon: String
    let chips: [String]
    var footerLabel: String = "AI conversation topic"
    var showsFooter: Bool = false
    var showsChevron: Bool = false
    var isChangeDisabled: Bool = false
    var onChange: (() -> Void)? = nil

    init(
        title: String,
        description: String,
        icon: String = "cup.and.saucer.fill",
        chips: [String],
        footerLabel: String = "AI conversation topic",
        showsFooter: Bool = false,
        showsChevron: Bool = false,
        isChangeDisabled: Bool = false,
        onChange: (() -> Void)? = nil
    ) {
        self.title = title
        self.description = description
        self.icon = icon
        self.chips = chips
        self.footerLabel = footerLabel
        self.showsFooter = showsFooter
        self.showsChevron = showsChevron
        self.isChangeDisabled = isChangeDisabled
        self.onChange = onChange
    }

    var body: some View {
        let corner = Layout.convScenarioCornerRadius

        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(AppColors.goalBackground)

            if onChange == nil {
                ProgressBlobShape()
                    .fill(AppColors.blobBlue.opacity(0.35))
                    .frame(
                        width: Layout.convScenarioBlobSize.width,
                        height: Layout.convScenarioBlobSize.height
                    )
                    .padding(.trailing, -18)
                    .padding(.top, 6)
                    .allowsHitTesting(false)
            }

            VStack(alignment: .leading, spacing: Layout.convScenarioContentSpacing) {
                headerRow

                chipRow

                if showsFooter {
                    Divider()
                        .overlay(Color.white.opacity(Layout.convScenarioDividerOpacity))

                    footerRow
                }
            }
            .padding(Layout.convScenarioPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .stroke(Color.white.opacity(0.90), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 16, x: 0, y: 8)
    }

    private var headerRow: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: Layout.convScenarioHeaderSpacing) {
                Text(title)
                    .font(.system(
                        size: Layout.convScenarioTitleSize,
                        weight: .bold,
                        design: .rounded
                    ))
                    .foregroundColor(AppColors.primaryBlueDark)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(description)
                    .font(.system(
                        size: Layout.convScenarioDescriptionSize,
                        weight: .medium,
                        design: .rounded
                    ))
                    .foregroundColor(AppColors.textSecondary)
                    .lineSpacing(3)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.trailing, onChange == nil ? 0 : 4)

            if let onChange {
                changeButton(action: onChange)
            }
        }
    }

    private func changeButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(
                        size: Layout.convScenarioChangeButtonIconSize,
                        weight: .bold
                    ))
                Text(L10n.string("spkChange"))
                    .font(.system(
                        size: Layout.convScenarioChangeButtonTextSize,
                        weight: .bold,
                        design: .rounded
                    ))
            }
            .foregroundColor(AppColors.primaryBlue)
            .padding(.horizontal, Layout.convScenarioChangeButtonHorizontalPadding)
            .padding(.vertical, Layout.convScenarioChangeButtonVerticalPadding)
            .frame(minHeight: Layout.convScenarioChangeButtonMinHeight)
            .background(
                Capsule(style: .continuous)
                    .fill(AppColors.primaryBlue.opacity(0.10))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(Color.white.opacity(0.65), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isChangeDisabled)
        .opacity(isChangeDisabled ? 0.55 : 1)
    }

    private var chipRow: some View {
        HStack(spacing: 6) {
            ForEach(chips, id: \.self) { chip in
                Text(chip)
                    .font(.system(
                        size: Layout.convScenarioChipTextSize,
                        weight: .bold,
                        design: .rounded
                    ))
                    .foregroundColor(AppColors.primaryBlue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(AppColors.primaryBlue.opacity(0.10))
                    .clipShape(Capsule())
            }
        }
    }

    private var footerRow: some View {
        HStack(spacing: 8) {
            Label {
                Text(footerLabel)
                    .font(.system(
                        size: Layout.convScenarioFooterTextSize,
                        weight: .semibold,
                        design: .rounded
                    ))
                    .foregroundColor(AppColors.textSecondary)
            } icon: {
                Image(systemName: "sparkles")
                    .font(.system(
                        size: Layout.convScenarioFooterIconSize,
                        weight: .semibold
                    ))
                    .foregroundColor(AppColors.primaryBlue)
            }

            Spacer(minLength: 0)

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(
                        size: Layout.convScenarioChevronSize,
                        weight: .bold
                    ))
                    .foregroundColor(AppColors.primaryBlue.opacity(0.75))
            }
        }
    }
}

#Preview("Standard") {
    ConversationScenarioCardView(
        title: "Cafe conversation",
        description: "Order a drink and ask about desserts.",
        chips: ["A2", "5 min", "Daily life"]
    )
    .padding(20)
    .background(AppColors.appBackground)
}

#Preview("Interactive") {
    ConversationScenarioCardView(
        title: "Weekend plans",
        description: "Discuss what you want to do this weekend with your tutor.",
        icon: "sparkles",
        chips: ["B1", "5 min", "Social"],
        showsFooter: true,
        showsChevron: true,
        onChange: {}
    )
    .padding(20)
    .background(AppColors.appBackground)
}
