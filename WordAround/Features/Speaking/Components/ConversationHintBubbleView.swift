import SwiftUI

struct ConversationHintBubbleView: View {
    let text: String

    var onDismiss: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .bottom, spacing: Layout.convBubbleSpacing) {
            Spacer(minLength: 44)

            VStack(alignment: .trailing, spacing: 4) {
                header

                bubbleBody
            }
        }
    }

    private var header: some View {
        HStack(spacing: 5) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: Layout.convBubbleTimeSize, weight: .semibold))
            Text("Suggested answer")
                .font(.system(
                    size: Layout.convBubbleTimeSize,
                    weight: .bold,
                    design: .rounded
                ))
        }
        .foregroundColor(AppColors.primaryBlue.opacity(0.85))
    }

    private var bubbleBody: some View {
        Text(text)
            .font(.system(
                size: Layout.convBubbleTextSize,
                weight: .medium,
                design: .rounded
            ))
            .foregroundColor(AppColors.primaryBlueDark.opacity(0.85))
            .padding(.horizontal, Layout.convBubbleInnerPadding)
            .padding(.vertical, Layout.convBubbleInnerPadding - 2)
            .background(
                AppColors.primaryBlue.opacity(0.18)
            )
            .clipShape(
                RoundedRectangle(cornerRadius: Layout.convBubbleCornerRadius, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Layout.convBubbleCornerRadius, style: .continuous)
                    .strokeBorder(
                        AppColors.primaryBlue.opacity(0.45),
                        style: StrokeStyle(lineWidth: 1, dash: [4, 3])
                    )
            )
            .fixedSize(horizontal: false, vertical: true)
            .contentShape(Rectangle())
            .onTapGesture {
                onDismiss?()
            }
    }
}

#Preview {
    VStack(spacing: 14) {
        ConversationMessageBubbleView(
            message: SpeakingConversationMessage(role: .ai, text: "Hi! What would you like to order today?")
        )
        ConversationHintBubbleView(
            text: "Try saying: I would like a coffee, please."
        )
    }
    .padding(20)
    .background(AppColors.appBackground)
}
