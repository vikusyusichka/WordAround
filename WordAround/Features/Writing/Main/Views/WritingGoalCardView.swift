import SwiftUI

struct WritingGoalCardView: View {
    let goal: WritingGoal

    private var isPadLike: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    var body: some View {
        GeometryReader { proxy in
            let isNarrow = proxy.size.width < 430
            let horizontalPadding: CGFloat = isPadLike ? 28 : (isNarrow ? 16 : 20)
            let verticalPadding: CGFloat = isPadLike ? 24 : (isNarrow ? 18 : 20)
            let blobSize = CGSize(
                width: isPadLike ? 160 : (isNarrow ? 108 : 124),
                height: isPadLike ? 135 : (isNarrow ? 98 : 108)
            )
            let iconSize: CGFloat = isPadLike ? 58 : (isNarrow ? 46 : 48)
            let progressWidth: CGFloat = isPadLike ? 190 : (isNarrow ? 132 : 152)

            ZStack(alignment: .trailing) {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.white.opacity(0.94))
                    .shadow(color: Color.black.opacity(0.06), radius: 22, x: 0, y: 12)

                BlobShape()
                    .fill(Color(red: 0.77, green: 0.80, blue: 1.00).opacity(0.45))
                    .frame(width: blobSize.width, height: blobSize.height)
                    .rotationEffect(.degrees(-10))
                    .offset(x: isNarrow ? 34 : 30, y: 2)
                    .clipped()

                HStack(spacing: isNarrow ? 10 : 18) {
                    VStack(alignment: .leading, spacing: isNarrow ? 8 : 10) {
                        Text(goal.title)
                            .font(.system(size: isPadLike ? 20 : (isNarrow ? 16 : 18), weight: .bold, design: .rounded))
                            .foregroundColor(AppColors.primaryBlue)
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)
                            .layoutPriority(2)

                        HStack(alignment: .firstTextBaseline, spacing: 5) {
                            Text("\(goal.currentWords)")
                                .font(.system(size: isPadLike ? 32 : (isNarrow ? 26 : 27), weight: .bold, design: .rounded))
                                .foregroundColor(AppColors.primaryBlue)

                            Text("/ \(goal.targetWords) words")
                                .font(.system(size: isPadLike ? 14 : (isNarrow ? 11 : 12), weight: .semibold, design: .rounded))
                                .foregroundColor(AppColors.textSecondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                        }
                        .layoutPriority(2)

                        GeometryReader { progressProxy in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color(red: 0.88, green: 0.90, blue: 0.96))
                                Capsule()
                                    .fill(AppColors.primaryBlue)
                                    .frame(width: progressProxy.size.width * goal.progress)
                            }
                        }
                        .frame(width: progressWidth, height: 5)

                        Text("\(goal.remainingWords) words left")
                            .font(.system(size: isPadLike ? 13 : 11, weight: .medium, design: .rounded))
                            .foregroundColor(AppColors.primaryBlue)
                            .lineLimit(1)
                    }
                    .layoutPriority(2)

                    Spacer(minLength: 4)

                    Circle()
                        .fill(Color.white)
                        .frame(width: iconSize, height: iconSize)
                        .shadow(color: Color.black.opacity(0.10), radius: 16, x: 0, y: 8)
                        .overlay(
                            Image(systemName: "pencil")
                                .font(.system(size: isPadLike ? 22 : (isNarrow ? 18 : 19), weight: .semibold))
                                .foregroundColor(AppColors.primaryBlue)
                        )
                        .layoutPriority(0)
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, verticalPadding)
            }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .frame(height: isPadLike ? 144 : 118)
    }
}

#Preview {
    WritingGoalCardView(goal: WritingGoal(title: "Today's writing goal", currentWords: 120, targetWords: 200))
        .padding()
        .background(AppColors.appBackground)
}
