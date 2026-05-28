import SwiftUI

struct ConversationMessageBubbleView: View {
    let message: SpeakingConversationMessage

    private var isAI: Bool { message.role == .ai }

    var body: some View {
        HStack(alignment: .bottom, spacing: Layout.convBubbleSpacing) {
            if isAI {
                aiAvatar
                bubbleContent
                Spacer(minLength: 44)
            } else {
                Spacer(minLength: 44)
                bubbleContent
            }
        }
    }

    private var aiAvatar: some View {
        ZStack {
            Circle()
                .fill(AppColors.primaryBlue.opacity(0.10))
                .frame(
                    width: Layout.convBubbleAvatarSize,
                    height: Layout.convBubbleAvatarSize
                )

            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(
                    size: Layout.convBubbleAvatarSize * 0.38,
                    weight: .medium
                ))
                .foregroundColor(AppColors.primaryBlue)
        }
    }

    private var bubbleContent: some View {
        VStack(alignment: isAI ? .leading : .trailing, spacing: 4) {
            Text(message.text)
                .font(.system(
                    size: Layout.convBubbleTextSize,
                    weight: .medium,
                    design: .rounded
                ))
                .foregroundColor(isAI ? AppColors.primaryBlueDark : .white)
                .padding(.horizontal, Layout.convBubbleInnerPadding)
                .padding(.vertical, Layout.convBubbleInnerPadding - 2)
                .background(
                    isAI
                    ? Color(red: 0.93, green: 0.95, blue: 1.0)
                    : AppColors.primaryBlue
                )
                .clipShape(
                    RoundedRectangle(cornerRadius: Layout.convBubbleCornerRadius, style: .continuous)
                )
                .fixedSize(horizontal: false, vertical: true)

            Text(message.timeString)
                .font(.system(
                    size: Layout.convBubbleTimeSize,
                    weight: .medium,
                    design: .rounded
                ))
                .foregroundColor(AppColors.mutedText)
        }
    }
}

#Preview {
    VStack(spacing: Layout.convMessageGroupSpacing) {
        ConversationMessageBubbleView(
            message: SpeakingConversationMessage(role: .ai, text: "Hi! What would you like to order?")
        )
        ConversationMessageBubbleView(
            message: SpeakingConversationMessage(role: .user, text: "I would like a coffee, please.")
        )
    }
    .padding(20)
    .background(AppColors.appBackground)
}
