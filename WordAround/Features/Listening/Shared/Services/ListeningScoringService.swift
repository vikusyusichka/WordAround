import Foundation

/// Pure scoring logic shared by every listening mode. Keeps answer-checking and
/// result building out of the view models.
struct ListeningScoringService {
    static let shared = ListeningScoringService()

    /// Builds a result from the answered questions.
    ///
    /// - Parameters:
    ///   - questions: the questions presented.
    ///   - selectedAnswers: questionID -> chosen option index.
    ///   - listeningTimeSeconds: accumulated listening time.
    ///   - speedLabel: e.g. "1.0x".
    ///   - hasQuestions: pass `false` for watch-only sessions so no fake score
    ///     is produced.
    func makeResult(
        sessionId: String,
        questions: [ListeningQuestion],
        selectedAnswers: [String: Int],
        listeningTimeSeconds: Int,
        speedLabel: String,
        hasQuestions: Bool = true
    ) -> ListeningResult {
        guard hasQuestions, !questions.isEmpty else {
            return ListeningResult(
                id: sessionId,
                comprehensionPercent: 0,
                correctAnswers: 0,
                totalQuestions: 0,
                listeningTimeSeconds: listeningTimeSeconds,
                speedLabel: speedLabel,
                mistakes: [],
                hasQuestions: false
            )
        }

        let total = questions.count
        var correct = 0
        var mistakes: [ListeningMistake] = []

        for question in questions {
            let selected = selectedAnswers[question.id]
            if selected == question.correctIndex {
                correct += 1
            } else {
                let selectedText = selected.flatMap { idx in
                    question.options.indices.contains(idx) ? question.options[idx] : nil
                } ?? "No answer"
                mistakes.append(
                    ListeningMistake(
                        id: question.id,
                        prompt: question.prompt,
                        selectedAnswer: selectedText,
                        correctAnswer: question.correctAnswer,
                        explanation: question.explanation,
                        questionType: question.type
                    )
                )
            }
        }

        let percent = total > 0 ? Int((Double(correct) / Double(total) * 100).rounded()) : 0

        return ListeningResult(
            id: sessionId,
            comprehensionPercent: percent,
            correctAnswers: correct,
            totalQuestions: total,
            listeningTimeSeconds: listeningTimeSeconds,
            speedLabel: speedLabel,
            mistakes: mistakes,
            hasQuestions: true
        )
    }

    /// Whether every presented question has an answer selected — used to gate
    /// the "Check answers" / "Finish" button.
    func allAnswered(questions: [ListeningQuestion], selectedAnswers: [String: Int]) -> Bool {
        guard !questions.isEmpty else { return true }
        return questions.allSatisfy { selectedAnswers[$0.id] != nil }
    }
}
