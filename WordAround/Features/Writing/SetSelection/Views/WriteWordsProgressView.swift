import SwiftUI

struct WriteWordsProgressView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    let progress: CGFloat
    let text: String

    private var metrics: ScreenMetrics {
        ScreenMetrics.current(horizontal: horizontalSizeClass, vertical: verticalSizeClass)
    }

    var body: some View {
        HStack(spacing: LayoutConstants.WriteWords.progressSpacing(metrics)) {
            GeometryReader { proxy in
                let segmentCount = LayoutConstants.WriteWords.progressSegmentCount(metrics)
                let spacing = LayoutConstants.WriteWords.progressSegmentSpacing(metrics)
                let width = (proxy.size.width - CGFloat(segmentCount - 1) * spacing) / CGFloat(segmentCount)

                HStack(spacing: spacing) {
                    ForEach(0..<segmentCount, id: \.self) { index in
                        Capsule()
                            .fill(index < filledSegments(segmentCount) ? AppColors.primaryBlue : Color(red: 0.90, green: 0.92, blue: 0.97))
                            .frame(width: width, height: LayoutConstants.WriteWords.progressHeight(metrics))
                    }
                }
            }
            .frame(height: LayoutConstants.WriteWords.progressHeight(metrics))

            Text(text)
                .font(.system(size: LayoutConstants.Typography.caption(metrics), weight: .bold, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
                .frame(width: LayoutConstants.WriteWords.progressTextWidth(metrics), alignment: .trailing)
        }
    }

    private func filledSegments(_ count: Int) -> Int {
        max(1, min(count, Int(ceil(progress * CGFloat(count)))))
    }
}

#Preview {
    WriteWordsProgressView(progress: 0.25, text: "5 / 20")
        .padding()
        .background(AppColors.appBackground)
}
