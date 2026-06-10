import SwiftUI

struct FreeSpeakingTranscriptCardView: View {
    let text: String
    var isPlaceholder: Bool = false

    var body: some View {
        HStack(alignment: .bottom, spacing: Layout.convBubbleSpacing) {
            Spacer(minLength: 44)

            VStack(alignment: .trailing, spacing: 4) {
                Text(L10n.string("spkYou"))
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.greenAccent)

                Text(text)
                    .font(.system(
                        size: Layout.convBubbleTextSize,
                        weight: .medium,
                        design: .rounded
                    ))
                    .foregroundColor(.white)
                    .padding(.horizontal, Layout.convBubbleInnerPadding)
                    .padding(.vertical, Layout.convBubbleInnerPadding - 2)
                    .background(AppColors.greenAccent)
                    .clipShape(
                        RoundedRectangle(cornerRadius: Layout.convBubbleCornerRadius, style: .continuous)
                    )
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .opacity(isPlaceholder ? 0.45 : 1.0)
    }
}

#Preview {
    VStack(spacing: 10) {
        FreeSpeakingTranscriptCardView(text: "I wake up at seven in the morning.")
        FreeSpeakingTranscriptCardView(text: "Then I have breakfast.", isPlaceholder: true)
    }
    .padding(20)
    .background(AppColors.appBackground)
}
