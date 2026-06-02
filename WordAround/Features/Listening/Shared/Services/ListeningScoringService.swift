import Foundation

struct ListeningScoringService {
    static let shared = ListeningScoringService()

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

    func allAnswered(questions: [ListeningQuestion], selectedAnswers: [String: Int]) -> Bool {
        guard !questions.isEmpty else { return true }
        return questions.allSatisfy { selectedAnswers[$0.id] != nil }
    }
}
