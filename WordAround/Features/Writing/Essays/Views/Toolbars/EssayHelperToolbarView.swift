import SwiftUI

struct EssayHelperToolbarView: View {
    let hintsLeft: Int
    let canUseHint: Bool
    let canUseTranslation: Bool
    let canUseSynonym: Bool
    let assistanceUsageText: String
    let onHint: () -> Void
    let onTranslate: () -> Void
    let onSynonym: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.essayHelperToolbarSpacing) {
            HStack(spacing: Layout.essayHelperToolbarButtonSpacing) {
                helperButton(
                    title: "Hint",
                    subtitle: "\(hintsLeft) left",
                    systemImage: "lightbulb.fill",
                    isEnabled: canUseHint,
                    action: onHint
                )

                helperButton(
                    title: "Translate",
                    subtitle: canUseTranslation ? "helper" : "locked",
                    systemImage: "character.book.closed.fill",
                    isEnabled: canUseTranslation,
                    action: onTranslate
                )

                helperButton(
                    title: "Synonym",
                    subtitle: canUseSynonym ? "helper" : "locked",
                    systemImage: "textformat.abc.dottedunderline",
                    isEnabled: canUseSynonym,
                    action: onSynonym
                )
            }

            Text(assistanceUsageText)
                .font(.system(size: Layout.essayHelperUsageTextSize, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
        }
    }

    private func helperButton(
        title: String,
        subtitle: String,
        systemImage: String,
        isEnabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: Layout.essayHelperButtonInnerSpacing) {
                Image(systemName: systemImage)
                    .font(.system(size: Layout.essayHelperButtonIconSize, weight: .semibold))

                VStack(spacing: 1) {
                    Text(title)
                        .font(.system(size: Layout.essayHelperButtonTitleSize, weight: .bold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)

                    Text(subtitle)
                        .font(.system(size: Layout.essayHelperButtonSubtitleSize, weight: .bold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
            }
            .foregroundColor(isEnabled ? AppColors.primaryBlue : AppColors.textSecondary.opacity(0.55))
            .frame(maxWidth: .infinity)
            .padding(.vertical, Layout.essayHelperButtonVerticalPadding)
            .background(isEnabled ? AppColors.primaryBlue.opacity(0.08) : Color.white.opacity(0.56))
            .clipShape(RoundedRectangle(cornerRadius: Layout.essayHelperButtonCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Layout.essayHelperButtonCornerRadius, style: .continuous)
                    .stroke(AppColors.primaryBlue.opacity(isEnabled ? 0.10 : 0.04), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}

#Preview {
    EssayHelperToolbarView(
        hintsLeft: 7,
        canUseHint: true,
        canUseTranslation: true,
        canUseSynonym: true,
        assistanceUsageText: "Hints: 0  ·  Translations: 0  ·  Synonyms: 0",
        onHint: {},
        onTranslate: {},
        onSynonym: {}
    )
    .padding()
    .background(AppColors.appBackground)
}
