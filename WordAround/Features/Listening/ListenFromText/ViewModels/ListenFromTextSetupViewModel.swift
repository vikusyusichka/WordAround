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

    static let minCharacters = 40
    static let maxCharacters = 5000
    static let minWordsForQuestions = 40

    private var trimmedText: String {
        textBody.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var wordCount: Int {
        trimmedText.split(whereSeparator: \.isWhitespace).count
    }

    func startListening() {
        let trimmed = trimmedText

        if trimmed.isEmpty {
            validationMessage = "Add some text to start listening."
            return
        }
        if trimmed.count < Self.minCharacters {
            validationMessage = "Add at least \(Self.minCharacters) characters to start listening."
            return
        }
        if trimmed.count > Self.maxCharacters {
            validationMessage = "That text is too long. Please keep it under \(Self.maxCharacters) characters."
            return
        }
        if addQuestions && wordCount < Self.minWordsForQuestions {
            validationMessage = "Add a bit more text (about \(Self.minWordsForQuestions)+ words) so we can create good questions."
            return
        }

        validationMessage = nil
        showSession = true
    }

    func makeSetup() -> ListeningSessionSetup {
        let trimmed = trimmedText
        let words = max(wordCount, 1)
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
            estimatedMinutes: max(1, words / 130)
        )
    }
}
