import SwiftUI

struct DescribePictureTranscriptCardView: View {
    let text: String
    var isPlaceholder: Bool = false

    var body: some View {
        HStack(alignment: .bottom, spacing: Layout.convBubbleSpacing) {
            Spacer(minLength: 44)

            VStack(alignment: .trailing, spacing: 4) {
                Text("You")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.orangeAccent)

                Text(text)
                    .font(.system(
                        size: Layout.convBubbleTextSize,
                        weight: .medium,
                        design: .rounded
                    ))
                    .foregroundColor(.white)
                    .padding(.horizontal, Layout.convBubbleInnerPadding)
                    .padding(.vertical, Layout.convBubbleInnerPadding - 2)
                    .background(AppColors.orangeAccent)
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
        DescribePictureTranscriptCardView(text: "In this picture I can see a busy city street.")
        DescribePictureTranscriptCardView(text: "There are several people walking.", isPlaceholder: true)
    }
    .padding(20)
    .background(AppColors.appBackground)
}
