import SwiftUI
// MARK: - Backward Compatible Lose Wrapper

struct WriteWordsLoseScreenView: View {
    let stats: WriteWordsLoseStats
    let onTryAgain: () -> Void
    let onBack: () -> Void

    var body: some View {
        WriteWordsResultScreenView(
            resultType: .timeoutLose,
            roundStats: WriteWordsRoundStats(
                totalWords: stats.completedWords,
                completedWords: stats.completedWords,
                skippedWords: 0,
                hintsUsed: 0,
                difficulty: WriteWordsDifficulty(rawValue: stats.difficulty) ?? .hard
            ),
            loseStats: stats,
            wrongAnswerDetails: nil,
            onTryAgain: onTryAgain,
            onBack: onBack
        )
    }
}

#Preview("Win Easy") {
    WriteWordsResultScreenView(
        resultType: .win,
        roundStats: WriteWordsRoundStats(
            totalWords: 12,
            completedWords: 10,
            skippedWords: 2,
            hintsUsed: 4,
            difficulty: .easy
        ),
        loseStats: WriteWordsLoseStats(
            completedWords: 10,
            streak: 5,
            difficulty: "Easy"
        ),
        wrongAnswerDetails: nil,
        onTryAgain: {},
        onBack: {}
    )
}

#Preview("Win Hard") {
    WriteWordsResultScreenView(
        resultType: .win,
        roundStats: WriteWordsRoundStats(
            totalWords: 8,
            completedWords: 8,
            skippedWords: 0,
            hintsUsed: 0,
            difficulty: .hard
        ),
        loseStats: WriteWordsLoseStats(
            completedWords: 8,
            streak: 8,
            difficulty: "Hard"
        ),
        wrongAnswerDetails: nil,
        onTryAgain: {},
        onBack: {}
    )
}

#Preview("Timeout Lose") {
    WriteWordsLoseScreenView(
        stats: WriteWordsLoseStats(
            completedWords: 4,
            streak: 3,
            difficulty: "Hard"
        ),
        onTryAgain: {},
        onBack: {}
    )
}

#Preview("Wrong Answer Lose") {
    WriteWordsResultScreenView(
        resultType: .wrongAnswerLose,
        roundStats: WriteWordsRoundStats(
            totalWords: 8,
            completedWords: 3,
            skippedWords: 0,
            hintsUsed: 0,
            difficulty: .hard
        ),
        loseStats: WriteWordsLoseStats(
            completedWords: 3,
            streak: 3,
            difficulty: "Hard"
        ),
        wrongAnswerDetails: WriteWordsWrongAnswerDetails(
            word: "manzana",
            userAnswer: "банан",
            correctAnswer: "яблуко"
        ),
        onTryAgain: {},
        onBack: {}
    )
}
