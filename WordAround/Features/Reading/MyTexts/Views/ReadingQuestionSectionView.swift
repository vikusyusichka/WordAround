import SwiftUI

struct ReadingQuestionSectionView: View {
    let question: ReadingQuestion
    let showVocabularyHints: Bool
    let selectedAnswer: String?
    let accent: Color
    let accentDark: Color
    let onSelect: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Questions")
                .font(.system(size: Layout.homeSectionTitleSize, weight: .bold, design: .rounded))
                .foregroundColor(accentDark)

            VStack(alignment: .leading, spacing: 10) {
                Text(question.title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(accent)
                Text(question.prompt)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(accentDark)
                    .fixedSize(horizontal: false, vertical: true)
                if showVocabularyHints, let explanation = question.explanation {
                    Text(explanation)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.mutedText)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(questionCardBackground)

            ReadingQuestionOptionsGrid {
                ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                    ReadingAnswerOptionCard(
                        label: optionLabel(index),
                        text: option,
                        isSelected: selectedAnswer == option,
                        accent: accent,
                        accentDark: accentDark
                    ) {
                        onSelect(option)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var questionCardBackground: some View {
        RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
            .fill(Color.white.opacity(0.94))
            .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 4)
    }

    private func optionLabel(_ index: Int) -> String {
        ["A", "B", "C", "D", "E", "F"][min(index, 5)]
    }
}
