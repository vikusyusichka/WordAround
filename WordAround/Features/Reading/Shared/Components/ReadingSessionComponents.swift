import SwiftUI

// MARK: - Session header

struct ReadingSessionHeaderView: View {
    let title: String
    let subtitle: String
    var progressText: String? = nil
    var trailingText: String? = nil
    var accent: Color
    var accentDark: Color
    let onBack: () -> Void

    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: Layout.homeHeaderTitleSize, weight: .bold, design: .rounded))
                    .foregroundColor(accentDark)

                Text(subtitle)
                    .font(.system(size: Layout.homeHeaderSubtitleSize, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.mutedText)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)

                if let progressText {
                    Text(progressText)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(accent)
                        .padding(.top, 2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, Layout.flashcardDetailTopButtonSize + 10)
            .padding(.trailing, trailingText == nil ? 10 : 72)

            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: Layout.flashcardDetailTopButtonIconSize, weight: .bold))
                        .foregroundColor(accentDark)
                        .frame(
                            width: Layout.flashcardDetailTopButtonSize,
                            height: Layout.flashcardDetailTopButtonSize
                        )
                        .background(Color.white.opacity(0.82))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .hoverEffect(.lift)

                Spacer()

                if let trailingText {
                    Text(trailingText)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(accentDark)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(accent.opacity(0.12))
                        .clipShape(Capsule())
                }
            }
        }
    }
}

// MARK: - Progress

struct ReadingProgressBar: View {
    let progress: Double
    var accent: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(accent.opacity(0.14))
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [accent, accent.opacity(0.72)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(8, geo.size.width * min(max(progress, 0), 1)))
            }
        }
        .frame(height: 8)
    }
}

// MARK: - Text card

struct ReadingTextCardView: View {
    var title: String? = nil
    let bodyText: String
    var highlightedWords: [String] = []
    var highlightColor: Color = AppColors.primaryBlue
    var helperButtons: [String] = []
    var legend: String? = nil
    var accent: Color = AppColors.primaryBlue

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let title {
                Text(title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primaryBlueDark)
            }

            if let legend {
                HStack(spacing: 6) {
                    Circle().fill(highlightColor).frame(width: 8, height: 8)
                    Text(legend)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                }
            }

            highlightedText
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.primaryBlueDark)
                .lineSpacing(6)
                .frame(maxWidth: .infinity, alignment: .leading)

            if !helperButtons.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(helperButtons, id: \.self) { label in
                            Button {} label: {
                                HStack(spacing: 5) {
                                    Image(systemName: helperIcon(for: label))
                                        .font(.system(size: 12, weight: .semibold))
                                    Text(label)
                                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                                }
                                .foregroundColor(accent)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(accent.opacity(0.10))
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .padding(18)
        .background(cardBackground)
    }

    private var highlightedText: Text {
        guard !highlightedWords.isEmpty else {
            return Text(bodyText)
        }

        var result = Text("")
        let words = bodyText.split(separator: " ", omittingEmptySubsequences: false)

        for (index, word) in words.enumerated() {
            let cleaned = word.trimmingCharacters(in: .punctuationCharacters)
            let isHighlighted = highlightedWords.contains { $0.caseInsensitiveCompare(cleaned) == .orderedSame }
            let piece = (index == 0 ? "" : " ") + word

            if isHighlighted {
                result = result + Text(piece)
                    .foregroundColor(highlightColor)
                    .bold()
            } else {
                result = result + Text(piece)
            }
        }
        return result
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
            .fill(Color.white.opacity(0.94))
            .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 4)
    }

    private func helperIcon(for label: String) -> String {
        switch label.lowercased() {
        case "translate": return "character.book.closed.fill"
        case "vocabulary": return "text.book.closed.fill"
        case "read aloud": return "speaker.wave.2.fill"
        default: return "sparkles"
        }
    }
}

// MARK: - Question & answers

struct ReadingQuestionCardView: View {
    let title: String
    let question: String
    var showsFindInText: Bool = false
    var accent: Color = AppColors.primaryBlue

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(accent)
                Spacer()
                if showsFindInText {
                    Button {} label: {
                        Label("Find in text", systemImage: "text.magnifyingglass")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(accent)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(accent.opacity(0.10))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }

            Text(question)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.primaryBlueDark)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.94))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous)
                .stroke(accent.opacity(0.14), lineWidth: 1)
        )
    }
}

struct ReadingAnswerOptionCard: View {
    let label: String
    let text: String
    var isSelected: Bool
    var accent: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(label)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(isSelected ? .white : accent)
                    .frame(width: 32, height: 32)
                    .background(isSelected ? accent : accent.opacity(0.12))
                    .clipShape(Circle())

                Text(text)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.primaryBlueDark)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 0)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous)
                    .fill(Color.white.opacity(0.94))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous)
                    .stroke(isSelected ? accent : accent.opacity(0.14), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Bottom action bar

struct ReadingBottomActionBar: View {
    var leadingTitle: String? = nil
    var centerTitle: String
    var trailingTitle: String? = nil
    var accent: Color
    var accentDark: Color
    var onLeading: (() -> Void)? = nil
    let onCenter: () -> Void
    var onTrailing: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 10) {
            if let leadingTitle, let onLeading {
                secondaryButton(leadingTitle, action: onLeading)
            } else {
                Color.clear.frame(maxWidth: .infinity)
            }

            Button(action: onCenter) {
                Text(centerTitle)
                    .font(.system(size: Layout.convSetupStartButtonTextSize - 1, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: Layout.convSetupStartButtonHeight - 4)
                    .background(
                        LinearGradient(colors: [accent, accentDark], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: Layout.convSetupStartButtonCornerRadius, style: .continuous))
            }
            .buttonStyle(.plain)

            if let trailingTitle, let onTrailing {
                secondaryButton(trailingTitle, action: onTrailing)
            } else {
                Color.clear.frame(maxWidth: .infinity)
            }
        }
    }

    private func secondaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(accentDark)
                .frame(maxWidth: .infinity)
                .frame(height: Layout.convSetupStartButtonHeight - 4)
                .background(accent.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: Layout.convSetupStartButtonCornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct ReadingContinueButton: View {
    let title: String
    var icon: String? = nil
    var accent: Color
    var accentDark: Color
    let action: () -> Void

    var body: some View {
        ReadingPrimaryButton(title: title, icon: icon, accent: accent, accentDark: accentDark, action: action)
    }
}

// MARK: - Word chip & choice card

struct ReadingWordChip: View {
    let word: String
    var isSelected: Bool = false
    var isTappable: Bool = true
    var accent: Color = AppColors.greenAccent
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(word)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(isSelected ? .white : accent)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(isSelected ? accent : accent.opacity(isTappable ? 0.12 : 0.06))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(accent.opacity(isTappable ? 0.22 : 0.08), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .disabled(!isTappable)
    }
}

struct ReadingChoiceCard: View {
    let icon: String
    let title: String
    let hint: String
    var isSelected: Bool
    var accent: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(accent.opacity(isSelected ? 0.22 : 0.12))
                        .frame(width: 48, height: 48)
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(accent)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.primaryBlueDark)
                    Text(hint)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                }

                Spacer(minLength: 0)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(isSelected ? accent : AppColors.mutedText)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous)
                    .fill(Color.white.opacity(0.94))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous)
                    .stroke(isSelected ? accent : accent.opacity(0.14), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Timer & pace

struct ReadingTimerCard: View {
    let timeText: String
    var label: String = "Remaining"
    var accent: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(timeText)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(accent)
            Text(label)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.94))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(accent.opacity(0.16), lineWidth: 1)
        )
    }
}

struct ReadingPaceCard: View {
    let currentWPM: Int
    let targetWPM: Int
    let status: String
    var accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Current pace")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.textSecondary)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(currentWPM)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(accent)
                Text("WPM")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.mutedText)
            }

            HStack {
                Text("Target: \(targetWPM) WPM")
                Spacer()
                Text(status)
            }
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundColor(AppColors.textSecondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.94))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous)
                .stroke(accent.opacity(0.14), lineWidth: 1)
        )
    }
}

// MARK: - Result components

struct ReadingResultHeaderView: View {
    let icon: String
    let title: String
    let subtitle: String
    var accent: Color
    var accentDark: Color

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.14))
                    .frame(width: 64, height: 64)
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(accent)
            }

            Text(title)
                .font(.system(size: Layout.homeHeaderTitleSize, weight: .bold, design: .rounded))
                .foregroundColor(accentDark)

            Text(subtitle)
                .font(.system(size: Layout.homeHeaderSubtitleSize, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.mutedText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ReadingResultSummaryCard: View {
    let primaryValue: String
    let primaryLabel: String
    let secondaryMetrics: [(value: String, label: String)]
    var accent: Color

    var body: some View {
        VStack(spacing: 18) {
            VStack(spacing: 4) {
                Text(primaryValue)
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundColor(accent)
                Text(primaryLabel)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
            }

            HStack(spacing: 0) {
                ForEach(Array(secondaryMetrics.enumerated()), id: \.offset) { index, metric in
                    if index > 0 {
                        Divider().frame(height: 36)
                    }
                    VStack(spacing: 4) {
                        Text(metric.value)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(AppColors.primaryBlueDark)
                        Text(metric.label)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.94))
        )
        .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 4)
    }
}

struct ReadingVocabularyReviewCard: View {
    let word: String
    let translation: String
    let example: String
    var status: String? = nil
    var accent: Color = AppColors.primaryBlue

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(word)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primaryBlueDark)
                Spacer()
                if let status {
                    Text(status)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(accent.opacity(0.12))
                        .clipShape(Capsule())
                }
            }

            Text(translation)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(accent)

            Text(example)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
                .italic()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.94))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous)
                .stroke(accent.opacity(0.12), lineWidth: 1)
        )
    }
}

typealias ReadingVocabularyCard = ReadingVocabularyReviewCard

struct ReadingMistakeReviewCard: View {
    let question: String
    let yourAnswer: String
    let correctAnswer: String
    var accent: Color = AppColors.primaryBlue

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(question)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.primaryBlueDark)

            HStack(spacing: 8) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(Color(red: 0.95, green: 0.42, blue: 0.40))
                Text(yourAnswer)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
            }

            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(accent)
                Text(correctAnswer)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(accentDark(from: accent))
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.94))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous)
                .stroke(Color(red: 0.95, green: 0.42, blue: 0.40).opacity(0.18), lineWidth: 1)
        )
    }
}

typealias ReadingMistakeCard = ReadingMistakeReviewCard

private func accentDark(from accent: Color) -> Color {
    accent.opacity(0.85)
}

struct ReadingSectionTitle: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: Layout.homeSectionTitleSize, weight: .bold, design: .rounded))
            .foregroundColor(AppColors.primaryBlueDark)
    }
}

struct ReadingResultActions: View {
    let primaryTitle: String
    let secondaryTitle: String
    var primaryIcon: String? = "arrow.clockwise"
    var accent: Color
    var accentDark: Color
    let onPrimary: () -> Void
    let onSecondary: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            ReadingPrimaryButton(
                title: primaryTitle,
                icon: primaryIcon,
                accent: accent,
                accentDark: accentDark,
                action: onPrimary
            )
            Button(action: onSecondary) {
                Text(secondaryTitle)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(accentDark)
                    .frame(maxWidth: .infinity)
                    .frame(height: Layout.convResultActionHeight)
                    .background(accent.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: Layout.convResultActionCornerRadius, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }
}
