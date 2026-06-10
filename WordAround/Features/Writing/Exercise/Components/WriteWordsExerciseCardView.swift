import SwiftUI

struct WriteWordsExerciseCardView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @ObservedObject var viewModel: WriteWordsViewModel

    let fixedHeight: CGFloat?

    init(viewModel: WriteWordsViewModel, fixedHeight: CGFloat? = nil) {
        self.viewModel = viewModel
        self.fixedHeight = fixedHeight
    }

    private var metrics: ScreenMetrics {
        ScreenMetrics.current(horizontal: horizontalSizeClass, vertical: verticalSizeClass)
    }

    private var cardHeight: CGFloat {
        fixedHeight ?? LayoutConstants.WriteWords.exerciseHeight(metrics)
    }

    var body: some View {
        VStack(spacing: LayoutConstants.WriteWords.exerciseSpacing(metrics)) {

            VStack(spacing: LayoutConstants.WriteWords.exerciseHeaderSpacing(metrics)) {
                Text(viewModel.displayTitle)
                    .font(.system(size: LayoutConstants.Typography.bodySmall(metrics), weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)

                Text(viewModel.displayWord)
                    .font(.system(size: LayoutConstants.WriteWords.exerciseTitleSize(metrics), weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primaryBlueDark)
                    .lineLimit(1)
                    .minimumScaleFactor(0.52)
                    .allowsTightening(true)
            }
            .padding(.top, LayoutConstants.WriteWords.exerciseTopPadding(metrics))

            Spacer(minLength: LayoutConstants.Common.smallSpacing(metrics))

            WriteWordsAnswerInputView(
                text: $viewModel.typedAnswer,
                isCorrect: viewModel.isCorrect,
                hintOverlay: viewModel.hintOverlayText,
                isDisabled: viewModel.isInteractionLocked
            )
            .onChange(of: viewModel.typedAnswer) { _, _ in
                viewModel.validateAnswer()
            }

            Spacer(minLength: LayoutConstants.Common.smallSpacing(metrics))

            feedbackView

            Button {
                viewModel.attemptNext()
            } label: {
                Text(L10n.string("commonNext"))
                    .font(.system(size: LayoutConstants.Typography.body(metrics), weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: LayoutConstants.WriteWords.primaryButtonHeight(metrics))
                    .background(
                        LinearGradient(
                            colors: [AppColors.primaryBlue, Color(red: 0.45, green: 0.39, blue: 1.00)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.WriteWords.primaryButtonCornerRadius(metrics), style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isInteractionLocked)
            .opacity(viewModel.isInteractionLocked ? 0.58 : 1)

            HStack(spacing: LayoutConstants.WriteWords.secondaryButtonSpacing(metrics)) {
                secondaryButton(title: L10n.string("essayHint"), icon: "lightbulb") {
                    viewModel.revealNextHint()
                }
                secondaryButton(title: "Skip", icon: "forward.end") {
                    viewModel.skip()
                }
            }
            .padding(.bottom, LayoutConstants.WriteWords.cardBottomPadding(metrics))
        }
        .padding(.horizontal, LayoutConstants.WriteWords.exerciseHorizontalPadding(metrics))
        .frame(height: cardHeight)
        .background(Color.white.opacity(0.96))
        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.WriteWords.exerciseCornerRadius(metrics), style: .continuous))
        .shadow(color: Color.black.opacity(0.07), radius: Layout.cardCornerRadius + LayoutConstants.Common.hairline * 2, x: 0, y: Layout.topPaddingPhone + LayoutConstants.Common.hairline * 2)
    }

    @ViewBuilder
    private var feedbackView: some View {
        let captionSize = LayoutConstants.Typography.caption(metrics)
        let hPad = LayoutConstants.WriteWords.successHorizontalPadding(metrics)
        let vPad = LayoutConstants.WriteWords.successVerticalPadding(metrics)
        let reservedHeight: CGFloat = vPad * 2 + captionSize * 1.4

        ZStack {
            Color.clear.frame(height: reservedHeight)

            switch viewModel.validationState {
            case .correct:
                Text(L10n.string("writeWordsCorrect"))
                    .font(.system(size: captionSize, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.21, green: 0.57, blue: 0.30))
                    .padding(.horizontal, hPad)
                    .padding(.vertical, vPad)
                    .background(Color(red: 0.88, green: 0.96, blue: 0.88))
                    .clipShape(Capsule())
                    .transition(.scale(scale: 0.85).combined(with: .opacity))

            case .incorrect:
                Text(L10n.string("writeWordsIncorrect"))
                    .font(.system(size: captionSize, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.78, green: 0.15, blue: 0.18))
                    .padding(.horizontal, hPad)
                    .padding(.vertical, vPad)
                    .background(Color(red: 1.00, green: 0.91, blue: 0.91))
                    .clipShape(Capsule())
                    .transition(.scale(scale: 0.85).combined(with: .opacity))

            case .idle:
                EmptyView()
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.validationState)
    }

    private func secondaryButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: LayoutConstants.Common.smallSpacing(metrics)) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.system(size: LayoutConstants.Typography.caption(metrics), weight: .bold, design: .rounded))
            .foregroundColor(AppColors.textSecondary)
            .frame(maxWidth: .infinity)
            .frame(height: LayoutConstants.WriteWords.secondaryButtonHeight(metrics))
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.WriteWords.secondaryButtonCornerRadius(metrics), style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.WriteWords.secondaryButtonCornerRadius(metrics), style: .continuous)
                    .stroke(Color(red: 0.86, green: 0.89, blue: 0.96), lineWidth: LayoutConstants.Common.hairline)
            )
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isInteractionLocked)
        .opacity(viewModel.isInteractionLocked ? 0.58 : 1)
    }
}

#Preview {
    WriteWordsExerciseCardView(viewModel: WriteWordsViewModel())
        .padding()
        .background(AppColors.appBackground)
}
