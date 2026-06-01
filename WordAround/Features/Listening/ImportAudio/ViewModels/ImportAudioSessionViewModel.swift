import Combine
import Foundation

@MainActor
final class ImportAudioSessionViewModel: ObservableObject {
    let setup: ListeningAudioImportSetup
    let questions: [ListeningQuestion]

    @Published var isPlaying = false
    @Published var progress: Double = 0.22
    @Published var elapsedSeconds = 58
    @Published var selectedAnswers: [String: Int] = [:]
    @Published var hasCheckedAnswers = false
    @Published var showResult = false

    init(
        setup: ListeningAudioImportSetup,
        questions: [ListeningQuestion] = ListeningPlaceholderData.sampleQuestions
    ) {
        self.setup = setup
        self.questions = questions
    }

    var metadataLine: String {
        "\(setup.language.title) • \(setup.level.title) • 1.0x • \(setup.durationText)"
    }

    var timerText: String { formatTime(elapsedSeconds) }

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
