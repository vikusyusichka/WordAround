import SwiftUI

struct EssayHelperToolbarView: View {
    let hintsLeft: Int
    let translateLeft: Int
    let synonymLeft: Int
    let canUseHint: Bool
    let canUseTranslation: Bool
    let canUseSynonym: Bool
    let assistanceUsageText: String
    let onHint: () -> Void
    let onTranslate: () -> Void
    let onSynonym: () -> Void
    let setsCount: Int
    let onSets: () -> Void

    var body: some View {
        HStack(spacing: Layout.essayHelperToolbarButtonSpacing) {
            helperButton(
                title: L10n.string("essayHint"),
                subtitle: "\(hintsLeft) left",
                systemImage: "lightbulb.fill",
                isEnabled: canUseHint,
                action: onHint
            )

            helperButton(
                title: L10n.string("essayTranslate"),
                subtitle: "\(translateLeft) left",
                systemImage: "character.book.closed.fill",
                isEnabled: canUseTranslation,
                action: onTranslate
            )

            helperButton(
                title: L10n.string("essaySynonym"),
                subtitle: "\(synonymLeft) left",
                systemImage: "textformat.abc.dottedunderline",
                isEnabled: canUseSynonym,
                action: onSynonym
            )

            helperButton(
                title: L10n.string("essaySets"),
                subtitle: "\(setsCount) selected",
                systemImage: "shippingbox.fill",
                isEnabled: true,
                action: onSets
            )
        }
    }

    private func helperButton(
        title: String,
        subtitle: String,
        systemImage: String,
        isEnabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            guard isEnabled else { return }
            action()
        } label: {
            VStack(spacing: Layout.essayHelperButtonInnerSpacing) {
                Image(systemName: systemImage)
                    .font(.system(size: Layout.essayHelperButtonIconSize, weight: .bold))
                    .foregroundColor(isEnabled ? AppColors.primaryBlue : AppColors.textSecondary.opacity(0.45))

                VStack(spacing: 2) {
                    Text(title)
                        .font(.system(size: Layout.essayHelperButtonTitleSize, weight: .bold, design: .rounded))
                        .foregroundColor(isEnabled ? AppColors.primaryBlue : AppColors.textSecondary.opacity(0.55))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    Text(subtitle)
                        .font(.system(size: Layout.essayHelperButtonSubtitleSize, weight: .bold, design: .rounded))
                        .foregroundColor(isEnabled ? AppColors.primaryBlue : AppColors.textSecondary.opacity(0.5))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Layout.essayHelperButtonVerticalPadding)
            .background(
                RoundedRectangle(cornerRadius: Layout.essayHelperButtonCornerRadius, style: .continuous)
                    .fill(AppColors.primaryBlue.opacity(isEnabled ? 0.08 : 0.035))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Layout.essayHelperButtonCornerRadius, style: .continuous)
                    .stroke(AppColors.primaryBlue.opacity(isEnabled ? 0.12 : 0.04), lineWidth: 1)
            )
            .opacity(isEnabled ? 1.0 : 0.62)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}

#Preview {
    EssayHelperToolbarView(
        hintsLeft: 4,
        translateLeft: 5,
        synonymLeft: 5,
        canUseHint: true,
        canUseTranslation: true,
        canUseSynonym: true,
        assistanceUsageText: "Hints: 1/5 · Translations: 1/6 · Synonyms: 0/5 · Sets: 2",
        onHint: {},
        onTranslate: {},
        onSynonym: {},
        setsCount: 2,
        onSets: {}
    )
    .padding()
    .background(AppColors.appBackground)
}
