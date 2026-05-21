import SwiftUI

struct GrammarNotesEmptyStateView: View {
    let title: String
    let message: String
    let buttonTitle: String
    let systemImage: String
    var tint: Color = AppColors.primaryBlue
    let action: () -> Void

    var body: some View {
        VStack(spacing: Layout.grammarEmptyStateSpacing) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.10))
                    .frame(width: Layout.grammarEmptyStateOuterIconSize, height: Layout.grammarEmptyStateOuterIconSize)

                Circle()
                    .fill(Color.white.opacity(0.72))
                    .frame(width: Layout.grammarEmptyStateInnerIconSize, height: Layout.grammarEmptyStateInnerIconSize)

                Image(systemName: systemImage)
                    .font(.system(size: Layout.grammarEmptyStateIconSize, weight: .bold))
                    .foregroundStyle(tint)
                    .rotationEffect(.degrees(-4))
            }
            .overlay(alignment: .topTrailing) {
                Image(systemName: "sparkle")
                    .font(.system(size: Layout.grammarEmptyStateSparkleSize, weight: .bold))
                    .foregroundStyle(tint.opacity(0.70))
                    .offset(x: Layout.isPadLike ? 10 : 8, y: Layout.isPadLike ? 2 : 0)
            }

            VStack(spacing: 7) {
                Text(title)
                    .font(.system(size: Layout.grammarEmptyStateTitleSize, weight: .black, design: .rounded))
                    .foregroundStyle(AppColors.primaryBlueDark)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.system(size: Layout.grammarEmptyStateMessageSize, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)
                    .lineSpacing(3)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: Layout.grammarEmptyStateTextMaxWidth)
            }

            Button(action: action) {
                Label(buttonTitle, systemImage: "plus")
                    .font(.system(size: Layout.grammarEmptyStateButtonTextSize, weight: .black, design: .rounded))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, Layout.grammarEmptyStateButtonHorizontalPadding)
                    .frame(height: Layout.grammarEmptyStateButtonHeight)
                    .background(tint)
                    .clipShape(RoundedRectangle(cornerRadius: Layout.grammarEmptyStateButtonCornerRadius, style: .continuous))
                    .shadow(color: tint.opacity(0.24), radius: 14, x: 0, y: 8)
            }
            .buttonStyle(GrammarNotesScaleButtonStyle())
        }
        .padding(Layout.grammarEmptyStatePadding)
        .frame(maxWidth: .infinity)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: Layout.grammarEmptyStateCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Layout.grammarEmptyStateCornerRadius, style: .continuous)
                .stroke(Color.white.opacity(0.64), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.045), radius: 18, x: 0, y: 10)
    }

    private var background: some View {
        ZStack(alignment: .topTrailing) {
            Color.white.opacity(0.86)

            BlobShape()
                .fill(tint.opacity(0.10))
                .frame(width: Layout.grammarEmptyStateBlobWidth, height: Layout.grammarEmptyStateBlobHeight)
                .rotationEffect(.degrees(-12))
                .offset(x: Layout.grammarEmptyStateBlobOffsetX, y: Layout.grammarEmptyStateBlobOffsetY)
        }
    }
}

extension GrammarNotesEmptyStateView {
    static func noTopics(action: @escaping () -> Void) -> GrammarNotesEmptyStateView {
        GrammarNotesEmptyStateView(
            title: "No grammar topics yet",
            message: "Create your first topic and keep rules, examples, and annoying little language traps in one place.",
            buttonTitle: "Create your first topic",
            systemImage: "folder.badge.plus",
            tint: AppColors.primaryBlue,
            action: action
        )
    }

    static func noNotes(action: @escaping () -> Void) -> GrammarNotesEmptyStateView {
        GrammarNotesEmptyStateView(
            title: "No notes in this topic",
            message: "Quickly save grammar mistakes while learning, then polish them later in the full editor.",
            buttonTitle: "Quickly save a note",
            systemImage: "square.and.pencil",
            tint: GrammarNoteType.mistake.tintColor,
            action: action
        )
    }
}

#Preview("No topics") {
    GrammarNotesEmptyStateView.noTopics(action: {})
        .padding()
        .background(AppColors.appBackground)
}

#Preview("No notes") {
    GrammarNotesEmptyStateView.noNotes(action: {})
        .padding()
        .background(AppColors.appBackground)
}
