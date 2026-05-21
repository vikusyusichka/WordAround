import SwiftUI

struct EssayScoreCardView: View {
    let score: EssayScore
    let wordCount: Int
    let issues: [GrammarIssue]
    let usedHints: Int
    let usedTranslations: Int
    let usedSynonyms: Int

    private var vocabularyIssueCount: Int {
        issues.filter { $0.category == .vocabulary || $0.category == .style }.count
    }

    private var grammarIssueCount: Int {
        issues.filter { $0.category == .grammar }.count
    }

    private var statColumns: [GridItem] {
        let count = Layout.isPadLike ? 6 : 3
        return Array(
            repeating: GridItem(.flexible(), spacing: 10),
            count: count
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.essayScoreCardSpacing) {
            header
            scoreBreakdown
            statistics
        }
        .padding(Layout.essayScoreCardPadding)
        .background(Color.white.opacity(0.94))
        .clipShape(RoundedRectangle(cornerRadius: Layout.essayScoreCardCornerRadius, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 16, x: 0, y: 9)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: Layout.essayScoreHeaderSpacing) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Essay score")
                    .font(.system(size: Layout.essayScoreTitleSize, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primaryBlueDark)

                Text(score.qualityLabel)
                    .font(.system(size: Layout.essayScoreQualitySize, weight: .bold, design: .rounded))
                    .foregroundColor(scoreTint)
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(score.total)/100")
                    .font(.system(size: Layout.essayScoreValueSize, weight: .black, design: .rounded))
                    .foregroundColor(scoreTint)

                Text(score.cefrLevel)
                    .font(.system(size: Layout.essayScoreLevelSize, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primaryBlue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(AppColors.primaryBlue.opacity(0.08))
                    .clipShape(Capsule())
            }
        }
    }

    private var scoreBreakdown: some View {
        VStack(spacing: Layout.essayScoreBreakdownSpacing) {
            scoreRow(title: "Grammar", value: score.grammar)
            scoreRow(title: "Vocabulary", value: score.vocabulary)
            scoreRow(title: "Length", value: score.length)
            scoreRow(title: "Complexity", value: score.complexity)
            scoreRow(title: "Relevance", value: score.relevance)
            scoreRow(title: "Independence", value: score.independence)
        }
    }

    private func scoreRow(title: String, value: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.system(size: Layout.essayScoreRowTitleSize, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)

                Spacer(minLength: 0)

                Text("\(value)")
                    .font(.system(size: Layout.essayScoreRowValueSize, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primaryBlueDark)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppColors.primaryBlue.opacity(0.08))

                    Capsule()
                        .fill(AppColors.primaryBlue.opacity(0.78))
                        .frame(width: max(0, proxy.size.width * CGFloat(value) / 100))
                }
            }
            .frame(height: Layout.essayScoreProgressHeight)
        }
    }

    private var statistics: some View {
        LazyVGrid(columns: statColumns, spacing: 10) {
            statistic(title: "Words", value: "\(wordCount)")
            statistic(title: "Grammar", value: "\(grammarIssueCount)")
            statistic(title: "Vocab/style", value: "\(vocabularyIssueCount)")
            statistic(title: "Hints", value: "\(usedHints)")
            statistic(title: "Translations", value: "\(usedTranslations)")
            statistic(title: "Synonyms", value: "\(usedSynonyms)")
        }
    }

    private func statistic(title: String, value: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: Layout.essayScoreStatValueSize, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.primaryBlueDark)

            Text(title)
                .font(.system(size: Layout.essayScoreStatTitleSize, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .frame(maxWidth: .infinity)
        .frame(height: Layout.isPadLike ? 70 : 66)
        .background(AppColors.primaryBlue.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: Layout.essayScoreStatCornerRadius, style: .continuous))
    }

    private var scoreTint: Color {
        switch score.qualityColor {
        case .excellent:
            return AppColors.primaryBlue
        case .veryGood:
            return Color(red: 0.31, green: 0.55, blue: 0.82)
        case .good:
            return Color(red: 0.72, green: 0.57, blue: 0.27)
        case .needsWork:
            return Color(red: 0.73, green: 0.34, blue: 0.32)
        }
    }
}

#Preview {
    EssayScoreCardView(
        score: EssayScore(
            total: 41,
            grammar: 71,
            vocabulary: 78,
            length: 91,
            complexity: 84,
            relevance: 18,
            independence: 51,
            cefrLevel: "A1",
            qualityLabel: "Needs work"
        ),
        wordCount: 108,
        issues: [],
        usedHints: 7,
        usedTranslations: 3,
        usedSynonyms: 2
    )
    .padding()
    .background(AppColors.appBackground)
}
