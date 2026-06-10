import SwiftUI

struct ReadingResultView: View {
    @StateObject private var viewModel: ReadingResultViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    let onReadAgain: () -> Void
    let onBackToLibrary: () -> Void
    private let readAgainTitle: String
    private let backButtonTitle: String

    private let accent: Color
    private let accentDark: Color

    private var contentMaxWidth: CGFloat {
        horizontalSizeClass == .regular ? Layout.convContentMaxWidth : .infinity
    }

    init(
        result: ReadingResult,
        title: String,
        levelTitle: String = "",
        focusTitle: String = "",
        accent: Color = ReadingMyTextsTheme.accent,
        accentDark: Color = ReadingMyTextsTheme.accentDark,
        readAgainTitle: String = L10n.string("readingActionReadAgain"),
        backButtonTitle: String = L10n.string("readingBackToMyTexts"),
        onReadAgain: @escaping () -> Void,
        onBackToLibrary: @escaping () -> Void
    ) {
        _viewModel = StateObject(wrappedValue: ReadingResultViewModel(
            result: result,
            title: title,
            levelTitle: levelTitle,
            focusTitle: focusTitle
        ))
        self.accent = accent
        self.accentDark = accentDark
        self.readAgainTitle = readAgainTitle
        self.backButtonTitle = backButtonTitle
        self.onReadAgain = onReadAgain
        self.onBackToLibrary = onBackToLibrary
    }

    var body: some View {
        ZStack {
            AppColors.appBackground.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: Layout.homeContentSpacing) {
                    resultHeader
                    summaryCard

                    if viewModel.hasMistakes {
                        sectionTitle(L10n.string("notesMistakesBadge"))
                        ForEach(viewModel.result.mistakes) { mistake in
                            mistakeCard(mistake)
                        }
                    }

                    actions
                }
                .frame(maxWidth: contentMaxWidth)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, Layout.homeHorizontalPadding)
                .padding(.top, Layout.homeTopSpacing)
                .padding(.bottom, Layout.homeBottomSafeSpacing)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var resultHeader: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.14))
                    .frame(width: 64, height: 64)
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(accent)
            }

            Text(L10n.string("readingPracticeComplete"))
                .font(.system(size: Layout.homeHeaderTitleSize, weight: .bold, design: .rounded))
                .foregroundColor(accentDark)

            Text(viewModel.title)
                .font(.system(size: Layout.homeHeaderSubtitleSize, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.mutedText)
                .multilineTextAlignment(.center)

            if viewModel.showMetadata {
                HStack(spacing: 6) {
                    if !viewModel.levelTitle.isEmpty {
                        ReadingMetadataChip(text: viewModel.levelTitle, accent: accent)
                    }
                    if !viewModel.focusTitle.isEmpty {
                        ReadingMetadataChip(text: viewModel.focusTitle, accent: accent)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var summaryCard: some View {
        VStack(spacing: 18) {
            ReadingScoreCardView(
                comprehensionPercent: viewModel.comprehensionPercent,
                accent: accent
            )

            ReadingStatisticsCardView(
                correctAnswers: viewModel.result.correctAnswers,
                totalQuestions: viewModel.result.totalQuestions,
                formattedTime: viewModel.formattedTime,
                wordsPerMinute: viewModel.result.wordsPerMinute,
                mistakeCount: viewModel.result.mistakes.count,
                accentDark: accentDark
            )
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.94))
                .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 4)
        )
    }

    private var actions: some View {
        VStack(spacing: 10) {
            ReadingPrimaryButton(
                title: readAgainTitle,
                icon: "arrow.clockwise",
                accent: accent,
                accentDark: accentDark,
                action: onReadAgain
            )

            Button(action: onBackToLibrary) {
                Text(backButtonTitle)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(accentDark)
                    .frame(maxWidth: .infinity)
                    .frame(height: Layout.convSetupStartButtonHeight)
                    .background(accent.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: Layout.convSetupStartButtonCornerRadius, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: Layout.homeSectionTitleSize, weight: .bold, design: .rounded))
            .foregroundColor(accentDark)
    }

    private func mistakeCard(_ mistake: ReadingMistake) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(mistake.prompt)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(accentDark)
            HStack(spacing: 6) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(Color(red: 0.95, green: 0.42, blue: 0.40))
                Text(mistake.selectedAnswer)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
            }
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(accent)
                Text(mistake.correctAnswer)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(accent)
            }
            if let explanation = mistake.explanation {
                Text(explanation)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.mutedText)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.94))
        )
    }
}

#Preview {
    ReadingResultView(
        result: ReadingResult(
            sessionId: "s1",
            textId: "t1",
            comprehensionPercent: 80,
            correctAnswers: 4,
            totalQuestions: 5,
            readingTimeSeconds: 125,
            wordsPerMinute: 142,
            mistakes: []
        ),
        title: ReadingMyTextsPreviewData.mediumText.title,
        onReadAgain: {},
        onBackToLibrary: {}
    )
}
