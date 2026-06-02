import SwiftUI

struct FreeSpeakingTopicCardView: View {
    let title: String
    let description: String
    let chips: [String]
    var onEdit: (() -> Void)? = nil

    private let corner = Layout.convScenarioCornerRadius

    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(AppColors.greenSoftBackground)

            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(AppColors.greenAccent.opacity(0.04))

            ProgressBlobShape()
                .fill(AppColors.blobGreen.opacity(0.65))
                .frame(
                    width: Layout.convScenarioBlobSize.width,
                    height: Layout.convScenarioBlobSize.height
                )
                .padding(.trailing, -18)
                .padding(.top, 6)
                .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: Layout.convScenarioContentSpacing) {
                headerRow
                chipRow
                Divider()
                    .overlay(AppColors.greenAccent.opacity(0.18))
                footerRow
            }
            .padding(Layout.convScenarioPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .stroke(AppColors.greenAccent.opacity(0.20), lineWidth: 1)
        )
        .shadow(color: AppColors.greenAccent.opacity(0.10), radius: 16, x: 0, y: 8)
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
                    .foregroundColor(AppColors.greenTitle)
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
            .padding(.trailing, onEdit == nil ? 0 : 4)

            if let onEdit {
                editButton(action: onEdit)
            }
        }
    }

    private func editButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "pencil")
                    .font(.system(
                        size: Layout.convScenarioChangeButtonIconSize,
                        weight: .bold
                    ))
                Text("Edit")
                    .font(.system(
                        size: Layout.convScenarioChangeButtonTextSize,
                        weight: .bold,
                        design: .rounded
                    ))
            }
            .foregroundColor(AppColors.greenAccent)
            .padding(.horizontal, Layout.convScenarioChangeButtonHorizontalPadding)
            .padding(.vertical, Layout.convScenarioChangeButtonVerticalPadding)
            .frame(minHeight: Layout.convScenarioChangeButtonMinHeight)
            .background(
                Capsule(style: .continuous)
                    .fill(AppColors.greenAccent.opacity(0.10))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(Color.white.opacity(0.65), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var chipRow: some View {
        HStack(spacing: 6) {
            ForEach(Array(chips.enumerated()), id: \.offset) { index, chip in
                chipView(chip, tier: chipTier(at: index))
            }
        }
    }

    private enum ChipTier { case primary, secondary, tertiary }

    private func chipTier(at index: Int) -> ChipTier {
        switch index {
        case 0:  return .primary
        case 1:  return .secondary
        default: return .tertiary
        }
    }

    private func chipView(_ chip: String, tier: ChipTier) -> some View {
        let foreground: Color
        let background: Color
        switch tier {
        case .primary:
            foreground = .white
            background = AppColors.greenAccent
        case .secondary:
            foreground = AppColors.greenTitle
            background = AppColors.greenAccent.opacity(0.18)
        case .tertiary:
            foreground = AppColors.greenTitle
            background = AppColors.greenAccent.opacity(0.08)
        }

        return Text(chip)
            .font(.system(
                size: Layout.convScenarioChipTextSize,
                weight: .bold,
                design: .rounded
            ))
            .foregroundColor(foreground)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(background)
            .clipShape(Capsule())
    }

    private var footerRow: some View {
        HStack(spacing: 8) {
            Label {
                Text("Free speaking topic")
                    .font(.system(
                        size: Layout.convScenarioFooterTextSize,
                        weight: .semibold,
                        design: .rounded
                    ))
                    .foregroundColor(AppColors.textSecondary)
            } icon: {
                Image(systemName: "leaf.fill")
                    .font(.system(
                        size: Layout.convScenarioFooterIconSize,
                        weight: .semibold
                    ))
                    .foregroundColor(AppColors.greenAccent)
            }
            Spacer(minLength: 0)
        }
    }
}

#Preview {
    FreeSpeakingTopicCardView(
        title: "Morning routine",
        description: "Talk about what you do every morning before work or school.",
        chips: ["A2", "5 min", "Daily life"],
        onEdit: {}
    )
    .padding(20)
    .background(AppColors.appBackground)
}
