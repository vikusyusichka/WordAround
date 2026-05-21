import SwiftUI

struct CustomEssayTopicInputView: View {
    @Binding var topicText: String

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.essayCustomTopicSpacing) {
            HStack(spacing: 8) {
                Image(systemName: "pencil.line")
                    .font(.system(size: Layout.essayCustomTopicIconSize, weight: .semibold))
                    .foregroundColor(AppColors.primaryBlue)

                Text("Your topic")
                    .font(.system(size: Layout.essayCustomTopicTitleSize, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primaryBlueDark)

                Spacer(minLength: 0)
            }

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: Layout.essayCustomTopicCornerRadius, style: .continuous)
                    .fill(Color.white.opacity(0.92))
                    .overlay(
                        RoundedRectangle(cornerRadius: Layout.essayCustomTopicCornerRadius, style: .continuous)
                            .stroke(AppColors.primaryBlue.opacity(0.08), lineWidth: 1)
                    )

                if topicText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("Write your own essay topic...")
                        .font(.system(size: Layout.essayCustomTopicTextSize, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.textSecondary.opacity(0.65))
                        .padding(.horizontal, Layout.essayCustomTopicInnerPadding)
                        .padding(.vertical, Layout.essayCustomTopicInnerPadding)
                }

                TextField("", text: $topicText, axis: .vertical)
                    .font(.system(size: Layout.essayCustomTopicTextSize, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.primaryBlueDark)
                    .padding(Layout.essayCustomTopicInnerPadding)
                    .lineLimit(2...4)
            }
            .frame(minHeight: Layout.essayCustomTopicMinHeight)
        }
        .padding(Layout.essayCardPadding)
        .background(Color.white.opacity(0.70))
        .clipShape(RoundedRectangle(cornerRadius: Layout.essayCardCornerRadius, style: .continuous))
        .shadow(color: Color.black.opacity(0.035), radius: 14, x: 0, y: 8)
    }
}

#Preview {
    CustomEssayTopicInputView(topicText: .constant("How technology helps language learning"))
        .padding()
        .background(AppColors.appBackground)
}
