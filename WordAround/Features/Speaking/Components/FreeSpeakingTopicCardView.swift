import SwiftUI

struct FreeSpeakingTopicCardView: View {
    let title: String
    let description: String
    let chips: [String]
    var onEdit: (() -> Void)? = nil

    private let corner = Layout.convScenarioCornerRadius
    private let greenLight = Color(red: 0.94, green: 0.98, blue: 0.95)

    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(greenLight)

            ProgressBlobShape()
                .fill(AppColors.blobGreen.opacity(0.55))
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
                    .overlay(Color.white.opacity(Layout.convScenarioDividerOpacity))
                footerRow
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
            ForEach(chips, id: \.self) { chip in
                Text(chip)
                    .font(.system(
                        size: Layout.convScenarioChipTextSize,
                        weight: .bold,
                        design: .rounded
                    ))
                    .foregroundColor(AppColors.greenTitle)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(AppColors.greenAccent.opacity(0.10))
                    .clipShape(Capsule())
            }
        }
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
