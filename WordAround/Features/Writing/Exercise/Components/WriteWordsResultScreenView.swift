import SwiftUI

enum WriteWordsResultType: Equatable {
    case win
    case timeoutLose
    case wrongAnswerLose
}

struct WriteWordsResultScreenView: View {
    let resultType: WriteWordsResultType
    let roundStats: WriteWordsRoundStats
    let loseStats: WriteWordsLoseStats
    let wrongAnswerDetails: WriteWordsWrongAnswerDetails?
    let onTryAgain: () -> Void
    let onBack: () -> Void

    private var isWin: Bool { resultType == .win }
    private var isHardWin: Bool { isWin && roundStats.difficulty == .hard }
    private var isWrongAnswerLose: Bool { resultType == .wrongAnswerLose }

    var body: some View {
        ZStack {
            AppColors.appBackground
                .ignoresSafeArea()

            backgroundBlobs

            VStack(spacing: Layout.writeWordsLoseSectionSpacing) {
                Spacer(minLength: Layout.writeWordsLoseLargeSpacing)

                VStack(spacing: Layout.writeWordsLoseSectionSpacing) {
                    header
                    statsCard
                    actions
                }
                .padding(.horizontal, Layout.writeWordsLoseCardHorizontalPadding)
                .padding(.vertical, Layout.writeWordsLoseCardVerticalPadding)
                .frame(maxWidth: Layout.writeWordsLoseCardMaxWidth)
                .background(Color.white.opacity(0.94))
                .clipShape(RoundedRectangle(
                    cornerRadius: Layout.writeWordsLoseCardCornerRadius,
                    style: .continuous
                ))
                .overlay {
                    RoundedRectangle(
                        cornerRadius: Layout.writeWordsLoseCardCornerRadius,
                        style: .continuous
                    )
                    .stroke(Color.white.opacity(0.92), lineWidth: Layout.writeWordsLoseDividerHeight)
                }
                .shadow(
                    color: Color.black.opacity(0.07),
                    radius: Layout.writeWordsLoseCardShadowRadius,
                    x: 0,
                    y: Layout.writeWordsLoseCardShadowY
                )
                .padding(.horizontal, Layout.writeWordsLoseHorizontalPadding)

                Spacer(minLength: Layout.writeWordsLoseLargeSpacing)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .allowsHitTesting(true)
        .transition(.asymmetric(
            insertion: .scale(scale: 0.96).combined(with: .opacity),
            removal: .scale(scale: 1.02).combined(with: .opacity)
        ))
    }

    private var header: some View {
        VStack(spacing: Layout.writeWordsLoseHeaderSpacing) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: iconGradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(
                        width: Layout.writeWordsLoseIconSize,
                        height: Layout.writeWordsLoseIconSize
                    )

                Image(systemName: iconName)
                    .font(.system(
                        size: Layout.writeWordsLoseIconSymbolSize,
                        weight: .bold
                    ))
                    .foregroundColor(AppColors.primaryBlueDark)
                    .rotationEffect(.degrees(isWin ? -10 : 0))
            }

            Text(title)
                .font(.system(
                    size: Layout.writeWordsLoseTitleSize,
                    weight: .bold,
                    design: .rounded
                ))
                .foregroundColor(AppColors.primaryBlueDark)
                .multilineTextAlignment(.center)

            Text(subtitle)
                .font(.system(
                    size: Layout.writeWordsLoseSubtitleSize,
                    weight: .semibold,
                    design: .rounded
                ))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
        }
    }

    private var statsCard: some View {
        VStack(spacing: Layout.writeWordsLoseStatsSpacing) {
            if isWin {
                winStatsContent
            } else {
                loseStatsContent
            }
        }
        .padding(Layout.writeWordsLoseStatsPadding)
        .background(AppColors.appBackground.opacity(0.72))
        .clipShape(RoundedRectangle(
            cornerRadius: Layout.writeWordsLoseStatsCornerRadius,
            style: .continuous
        ))
        .overlay {
            RoundedRectangle(
                cornerRadius: Layout.writeWordsLoseStatsCornerRadius,
                style: .continuous
            )
            .stroke(Color.white.opacity(0.85), lineWidth: Layout.writeWordsLoseDividerHeight)
        }
    }

    private var winStatsContent: some View {
        Group {
            statRow(title: "Total words", value: "\(roundStats.totalWords)")
            divider
            statRow(title: "Completed words", value: "\(roundStats.completedWords)")
            divider
            statRow(title: "Difficulty", value: roundStats.difficulty.rawValue)

            if isHardWin {
                divider
                hardModeSuccessMessage
            } else {
                divider
                statRow(title: "Skipped words", value: "\(roundStats.skippedWords)")
                divider
                statRow(title: "Hints used", value: "\(roundStats.hintsUsed)")
            }
        }
    }

    private var loseStatsContent: some View {
        Group {
            if isWrongAnswerLose, let wrongAnswerDetails {
                answerDetails(wrongAnswerDetails)
                divider
            }

            statRow(title: "Completed words", value: "\(loseStats.completedWords)")
            divider
            statRow(title: "Streak", value: "\(loseStats.streak)")
            divider
            statRow(title: "Difficulty", value: loseStats.difficulty)
        }
    }

    private func answerDetails(_ details: WriteWordsWrongAnswerDetails) -> some View {
        VStack(spacing: Layout.writeWordsLoseStatsSpacing) {
            statRow(title: "Word", value: details.word)
            divider
            statRow(title: "Your answer", value: details.userAnswer.isEmpty ? "—" : details.userAnswer)
            divider
            statRow(title: "Correct answer", value: details.correctAnswer)
        }
    }

    private var hardModeSuccessMessage: some View {
        VStack(spacing: 6) {
            Text("Perfect round!")
                .font(.system(
                    size: Layout.writeWordsLoseCaptionSize,
                    weight: .bold,
                    design: .rounded
                ))
                .foregroundColor(AppColors.primaryBlueDark)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("You completed Hard Mode without mistakes.\nNo skips. No hints. Just skill.")
                .font(.system(
                    size: Layout.writeWordsLoseCaptionSize,
                    weight: .semibold,
                    design: .rounded
                ))
                .foregroundColor(AppColors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineSpacing(2)
        }
    }

    private var actions: some View {
        VStack(spacing: Layout.writeWordsLoseActionsSpacing) {
            Button(action: onTryAgain) {
                Text("Try again")
                    .font(.system(
                        size: Layout.writeWordsLoseBodyTextSize,
                        weight: .bold,
                        design: .rounded
                    ))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: Layout.writeWordsLosePrimaryButtonHeight)
                    .background(
                        LinearGradient(
                            colors: [
                                AppColors.primaryBlue,
                                Color(red: 0.45, green: 0.39, blue: 1.00)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(
                        cornerRadius: Layout.writeWordsLoseButtonCornerRadius,
                        style: .continuous
                    ))
            }
            .buttonStyle(.plain)

            Button(action: onBack) {
                Text("Back")
                    .font(.system(
                        size: Layout.writeWordsLoseBodyTextSize,
                        weight: .bold,
                        design: .rounded
                    ))
                    .foregroundColor(AppColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: Layout.writeWordsLoseSecondaryButtonHeight)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(
                        cornerRadius: Layout.writeWordsLoseButtonCornerRadius,
                        style: .continuous
                    ))
                    .overlay {
                        RoundedRectangle(
                            cornerRadius: Layout.writeWordsLoseButtonCornerRadius,
                            style: .continuous
                        )
                        .stroke(
                            Color(red: 0.86, green: 0.89, blue: 0.96),
                            lineWidth: Layout.writeWordsLoseDividerHeight
                        )
                    }
            }
            .buttonStyle(.plain)
        }
    }

    private func statRow(title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(title)
                .font(.system(
                    size: Layout.writeWordsLoseCaptionSize,
                    weight: .semibold,
                    design: .rounded
                ))
                .foregroundColor(AppColors.textSecondary)

            Spacer(minLength: 12)

            Text(value)
                .font(.system(
                    size: Layout.writeWordsLoseCaptionSize,
                    weight: .bold,
                    design: .rounded
                ))
                .foregroundColor(AppColors.primaryBlueDark)
                .multilineTextAlignment(.trailing)
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(Color(red: 0.86, green: 0.89, blue: 0.96))
            .frame(height: Layout.writeWordsLoseDividerHeight)
    }

    private var backgroundBlobs: some View {
        ZStack {
            Circle()
                .fill(AppColors.primaryBlue.opacity(isWin ? 0.10 : 0.08))
                .frame(
                    width: Layout.writeWordsLoseBlobSize,
                    height: Layout.writeWordsLoseBlobSize
                )
                .offset(
                    x: -Layout.writeWordsLoseBlobSize * 0.45,
                    y: -Layout.writeWordsLoseBlobSize * 0.55
                )

            Circle()
                .fill(Color(red: 0.45, green: 0.39, blue: 1.00).opacity(isWin ? 0.10 : 0.08))
                .frame(
                    width: Layout.writeWordsLoseBlobSize * 0.78,
                    height: Layout.writeWordsLoseBlobSize * 0.78
                )
                .offset(
                    x: Layout.writeWordsLoseBlobSize * 0.44,
                    y: Layout.writeWordsLoseBlobSize * 0.56
                )
        }
        .blur(radius: 2)
        .allowsHitTesting(false)
    }

    private var iconName: String {
        switch resultType {
        case .win:
            return "party.popper.fill"
        case .timeoutLose:
            return "hourglass"
        case .wrongAnswerLose:
            return "xmark"
        }
    }

    private var title: String {
        switch resultType {
        case .win:
            return "Round completed!"
        case .timeoutLose:
            return "Time’s up"
        case .wrongAnswerLose:
            return "Wrong answer"
        }
    }

    private var subtitle: String {
        switch resultType {
        case .win:
            return "Great work. You finished this writing round. Here is your result."
        case .timeoutLose:
            return "The hard mode timer reached zero. Try again from the first word."
        case .wrongAnswerLose:
            return "One mistake ends the round in Hard Mode."
        }
    }

    private var iconGradientColors: [Color] {
        switch resultType {
        case .win:
            return [
                AppColors.primaryBlue.opacity(0.18),
                Color(red: 0.45, green: 0.39, blue: 1.00).opacity(0.14)
            ]
        case .timeoutLose, .wrongAnswerLose:
            return [
                AppColors.primaryBlue.opacity(0.16),
                Color(red: 0.45, green: 0.39, blue: 1.00).opacity(0.12)
            ]
        }
    }
}
