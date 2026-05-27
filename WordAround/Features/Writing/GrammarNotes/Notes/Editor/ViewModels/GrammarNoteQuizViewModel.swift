import Foundation
import Combine

@MainActor
final class GrammarNoteQuizViewModel: ObservableObject {

    // MARK: - List state
    @Published private(set) var quizzes: [GrammarNoteQuiz] = []
    @Published private(set) var isLoading = false
    @Published private(set) var hasLoaded = false
    @Published var listError: String?

    // MARK: - Session state
    @Published private(set) var activeQuiz: GrammarNoteQuiz?
    @Published private(set) var currentQuestionIndex = 0
    @Published private(set) var sessionAnswers: [String: String] = [:]
    @Published private(set) var sessionFinished = false

    // MARK: - Create state

    enum CreateQuizState: Equatable {
        case idle
        case generating
        case saving
        case failed(String)
        case succeeded

        var isBusy: Bool {
            switch self {
            case .generating, .saving: return true
            default: return false
            }
        }

        var errorMessage: String? {
            if case .failed(let message) = self { return message }
            return nil
        }
    }

    @Published private(set) var createState: CreateQuizState = .idle

    // MARK: - Computed

    var hasAnyQuiz: Bool { !quizzes.isEmpty }

    var currentQuestion: GrammarQuizQuestion? {
        guard let q = activeQuiz, currentQuestionIndex < q.questions.count else { return nil }
        return q.questions[currentQuestionIndex]
    }

    var isLastQuestion: Bool {
        guard let q = activeQuiz else { return false }
        return currentQuestionIndex >= q.questions.count - 1
    }

    var correctCount: Int {
        guard let quiz = activeQuiz else { return 0 }
        return quiz.questions.filter { q in
            guard let answer = sessionAnswers[q.id] else { return false }
            return answer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                == q.correctAnswer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }.count
    }

    var scorePercentage: Int {
        guard let quiz = activeQuiz, !quiz.questions.isEmpty else { return 0 }
        return Int(Double(correctCount) / Double(quiz.questions.count) * 100)
    }

    var answeredQuestions: [GrammarQuizQuestion] {
        guard let quiz = activeQuiz else { return [] }
        return quiz.questions.map { q in
            var copy = q
            copy.userAnswer = sessionAnswers[q.id]
            return copy
        }
    }

    // MARK: - Private

    let ownerUID: String
    let topicId: String
    let noteId: String
    private let service: GrammarNoteQuizServicing

    // MARK: - Init

    init(
        ownerUID: String,
        topicId: String,
        noteId: String,
        service: GrammarNoteQuizServicing = GrammarNoteQuizService()
    ) {
        self.ownerUID = ownerUID
        self.topicId = topicId
        self.noteId = noteId
        self.service = service
    }

    // MARK: - Load

    func loadQuizzes() async {
        guard !isLoading else { return }
        isLoading = true
        listError = nil
        defer { isLoading = false }
        do {
            quizzes = try await service.fetchQuizzes(ownerUID: ownerUID, topicId: topicId, noteId: noteId)
            hasLoaded = true
        } catch {
            listError = error.localizedDescription
            hasLoaded = true
        }
    }

    // MARK: - Create

    /// Creates a quiz using the selected mode and persists it through
    /// `GrammarNoteQuizService`. Returns the saved quiz on success or
    /// `nil` if generation / validation / save failed.
    ///
    /// Updates `createState` so the calling sheet can render a single
    /// loading / error indicator. `note.hasQuiz` is only flipped to
    /// `true` server-side by `GrammarNoteQuizService.createQuiz` after
    /// the Firestore write succeeds — never optimistically here.
    func createQuiz(
        title: String,
        note: GrammarNote,
        mode: GrammarQuizCreationMode,
        questionCount: Int,
        allowedTypes: [GrammarQuizQuestionType],
        manualQuestions: [GrammarQuizQuestion],
        focusInstructions: String?,
        localGenerator: GrammarQuizQuestionGenerating = LocalGrammarQuizQuestionGenerator(),
        aiGenerator: GrammarQuizQuestionGenerating = AIGrammarQuizQuestionGenerator()
    ) async -> GrammarNoteQuiz? {

        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else {
            createState = .failed("Quiz title is required.")
            return nil
        }

        // 1. Produce raw questions per mode.
        let rawQuestions: [GrammarQuizQuestion]
        do {
            switch mode {
            case .manual:
                rawQuestions = manualQuestions
            case .smartLocal:
                createState = .generating
                rawQuestions = try await localGenerator.generateQuestions(
                    from: note,
                    questionCount: questionCount,
                    allowedTypes: allowedTypes,
                    focusInstructions: focusInstructions
                )
            case .aiGenerated:
                createState = .generating
                rawQuestions = try await aiGenerator.generateQuestions(
                    from: note,
                    questionCount: questionCount,
                    allowedTypes: allowedTypes,
                    focusInstructions: focusInstructions
                )
            }
        } catch {
            createState = .failed(error.localizedDescription)
            return nil
        }

        // 2. Validate / normalize.
        let validated: [GrammarQuizQuestion]
        do {
            validated = try GrammarQuizQuestionValidator.validate(rawQuestions)
        } catch {
            createState = .failed(error.localizedDescription)
            return nil
        }

        // 3. Save through Firestore.
        createState = .saving
        let quiz = GrammarNoteQuiz(
            ownerUID: note.ownerUID,
            topicId: note.topicId,
            noteId: note.id,
            title: cleanTitle,
            sourceNoteTitle: note.title,
            questions: validated
        )
        do {
            try await service.createQuiz(quiz)
            quizzes.insert(quiz, at: 0)
            createState = .succeeded
            return quiz
        } catch {
            createState = .failed(error.localizedDescription)
            return nil
        }
    }

    func resetCreateState() {
        createState = .idle
    }

    // MARK: - Delete

    func deleteQuiz(_ quiz: GrammarNoteQuiz) async {
        listError = nil
        do {
            try await service.deleteQuiz(
                id: quiz.id, ownerUID: ownerUID, topicId: topicId, noteId: noteId
            )
            quizzes.removeAll { $0.id == quiz.id }
        } catch {
            listError = error.localizedDescription
        }
    }

    // MARK: - Session

    func startQuiz(_ quiz: GrammarNoteQuiz) {
        activeQuiz = quiz
        currentQuestionIndex = 0
        sessionAnswers = [:]
        sessionFinished = false
    }

    func submitAnswer(_ answer: String) {
        guard let question = currentQuestion else { return }
        sessionAnswers[question.id] = answer
    }

    func nextQuestion() {
        guard let quiz = activeQuiz else { return }
        if currentQuestionIndex < quiz.questions.count - 1 {
            currentQuestionIndex += 1
        }
    }

    func finishQuiz() {
        sessionFinished = true
    }

    func resetSession() {
        guard let quiz = activeQuiz else { return }
        startQuiz(quiz)
    }

    func clearSession() {
        activeQuiz = nil
        currentQuestionIndex = 0
        sessionAnswers = [:]
        sessionFinished = false
    }
}
