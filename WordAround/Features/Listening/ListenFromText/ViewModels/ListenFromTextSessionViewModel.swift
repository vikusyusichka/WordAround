import Combine
import Foundation

@MainActor
final class ListenFromTextSessionViewModel: ObservableObject {
    let setup: ListeningSessionSetup
    let questions: [ListeningQuestion]

    @Published var isPlaying = false
    @Published var progress: Double = 0.35
    @Published var elapsedSeconds = 82
    @Published var selectedAnswers: [String: Int] = [:]
    @Published var hasCheckedAnswers = false
    @Published var showResult = false

    init(
        setup: ListeningSessionSetup,
        questions: [ListeningQuestion] = ListeningPlaceholderData.sampleQuestions
    ) {
        self.setup = setup
        self.questions = questions
    }

    var durationSeconds: Int { setup.estimatedMinutes * 60 }

    var timerText: String { formatTime(elapsedSeconds) }

    var currentTimeText: String {
        formatTime(Int(Double(durationSeconds) * progress))
    }

    var durationText: String { formatTime(durationSeconds) }

    var bottomButtonTitle: String {
        if setup.addQuestions {
            return hasCheckedAnswers ? "Finish Practice" : "Check Answers"
        }
        return "Finish Practice"
    }

    var bottomButtonIcon: String {
        if setup.addQuestions && !hasCheckedAnswers {
            return "checkmark.circle.fill"
        }
        return "flag.checkered"
    }

    func selectAnswer(questionID: String, optionIndex: Int) {
        guard !hasCheckedAnswers else { return }
        selectedAnswers[questionID] = optionIndex
    }

    func handleBottomAction() {
        if setup.addQuestions && !hasCheckedAnswers {
            hasCheckedAnswers = true
        } else {
            showResult = true
        }
    }

    func formatTime(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}
