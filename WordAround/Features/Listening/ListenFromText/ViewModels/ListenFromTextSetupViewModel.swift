import Combine
import Foundation

@MainActor
final class ListenFromTextSetupViewModel: ObservableObject {
    @Published var selectedLanguage: GrammarLanguage = .english
    @Published var selectedLevel: EssayDifficulty = .b1
    @Published var voiceSpeed: ListeningVoiceSpeed = .normal
    @Published var voiceType: ListeningVoiceType = .default
    @Published var showTextWhileListening = false
    @Published var addQuestions = true
    @Published var questionCount = 5
    @Published var questionTypes: Set<ListeningQuestionType> = Set(ListeningQuestionType.allCases)
    @Published var optionalTitle = ""
    @Published var textBody = ""
    @Published var validationMessage: String?
    @Published var showSession = false

    func startListening() {
        let trimmed = textBody.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            validationMessage = "Add some text to start listening."
            return
        }
        let wordCount = trimmed.split(whereSeparator: \.isWhitespace).count
        if addQuestions && wordCount < 40 {
            validationMessage = "Text is too short for good questions."
            return
        }
        validationMessage = nil
        showSession = true
    }

    func makeSetup() -> ListeningSessionSetup {
        let trimmed = textBody.trimmingCharacters(in: .whitespacesAndNewlines)
        let wordCount = max(trimmed.split(whereSeparator: \.isWhitespace).count, 1)
        let title = optionalTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "Listening Practice"
            : optionalTitle.trimmingCharacters(in: .whitespacesAndNewlines)

        return ListeningSessionSetup(
            modeID: "listen-from-text",
            language: selectedLanguage,
            level: selectedLevel,
            title: title,
            text: trimmed,
            voiceSpeed: voiceSpeed,
            voiceType: voiceType,
            showTextWhileListening: showTextWhileListening,
            addQuestions: addQuestions,
            questionCount: questionCount,
            questionTypes: questionTypes,
            estimatedMinutes: max(1, wordCount / 40)
        )
    }
}
