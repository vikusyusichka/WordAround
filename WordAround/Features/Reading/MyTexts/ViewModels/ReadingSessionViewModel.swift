import Foundation
import Combine

@MainActor
final class ReadingSessionViewModel: ObservableObject {
    @Published private(set) var session: ReadingSession
    @Published var currentPhase: ReadingSessionPhase = .reading
    @Published var currentQuestionIndex = 0
    @Published var selectedAnswers: [String: String] = [:]
    @Published private(set) var elapsedSeconds = 0
    @Published private(set) var result: ReadingResult?
    @Published var errorMessage: String?
    @Published var navigateToResult = false

    private var timerCancellable: AnyCancellable?
    private let sessionService: ReadingSessionServicing
    private let analyzer: ReadingTextAnalyzing

    init(
        userText: ReadingUserText,
        focus: ReadingFocus? = nil,
        sessionService: ReadingSessionServicing = ReadingSessionService.shared,
        analyzer: ReadingTextAnalyzing = ReadingTextAnalyzerService.shared
    ) {
        self.sessionService = sessionService
        self.analyzer = analyzer
        let focusValue = focus ?? .mainIdea
        let maxQuestions = focusValue == .vocabulary ? 6 : 5
        let questions = ReadingLocalQuestionService.shared.generateQuestions(
            for: userText,
            focus: focusValue,
            maxQuestions: maxQuestions
        )
        self.session = ReadingSession(
            textId: userText.id,
            title: userText.title,
            content: userText.content,
            language: userText.language,
            level: userText.level,
            wordCount: userText.wordCount,
            questions: questions,
            focus: focusValue
        )
        ReadingTextStorageService.shared.markOpened(textId: userText.id)
    }

    var formattedTime: String {
        let minutes = elapsedSeconds / 60
        let seconds = elapsedSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var readingProgress: Double {
        switch currentPhase {
        case .reading:
            let estimate = analyzer.estimatedReadingTimeSeconds(wordCount: session.wordCount)
            return min(0.45, Double(elapsedSeconds) / Double(max(estimate, 1)))
        case .questions:
            guard !session.questions.isEmpty else { return 0.6 }
            let questionProgress = Double(currentQuestionIndex + 1) / Double(session.questions.count)
            return 0.45 + (questionProgress * 0.45)
        case .completed:
            return 1
        }
    }

    var progressText: String {
        switch currentPhase {
        case .reading:
            return "Reading • \(formattedTime)"
        case .questions:
            guard !session.questions.isEmpty else { return "Questions" }
            return "Question \(currentQuestionIndex + 1) / \(session.questions.count)"
        case .completed:
            return "Complete"
        }
    }

    var currentQuestion: ReadingQuestion? {
        guard currentPhase == .questions,
              currentQuestionIndex < session.questions.count else { return nil }
        return session.questions[currentQuestionIndex]
    }

    var isLastQuestion: Bool {
        currentQuestionIndex >= session.questions.count - 1
    }

    var hasQuestions: Bool { !session.questions.isEmpty }

    var phase: ReadingSessionPhase { currentPhase }

    var selectedAnswer: String? {
        guard let question = currentQuestion else { return nil }
        return selectedAnswers[question.id]
    }

    func onAppear() { startTimer() }

    func onDisappear() {
        stopTimer()
        if currentPhase != .completed {
            Task {
                await sessionService.savePartialProgress(
                    textId: session.textId,
                    progress: readingProgress,
                    lastReadCharacterIndex: Int(Double(session.content.count) * readingProgress)
                )
            }
        }
    }

    func startQuestions() {
        currentPhase = .questions
        currentQuestionIndex = 0
        Task {
            await sessionService.savePartialProgress(
                textId: session.textId,
                progress: 0.5,
                lastReadCharacterIndex: session.content.count / 2
            )
        }
    }

    func selectAnswer(question: ReadingQuestion, answer: String) {
        selectedAnswers[question.id] = answer
    }

    func selectAnswer(_ answer: String) {
        guard let question = currentQuestion else { return }
        selectAnswer(question: question, answer: answer)
    }

    func answer(for question: ReadingQuestion) -> String? {
        selectedAnswers[question.id]
    }

    func isAnswered(question: ReadingQuestion) -> Bool {
        selectedAnswers[question.id] != nil
    }

    func goToNextQuestion() {
        guard let question = currentQuestion else { return }
        recordAnswer(for: question)
        guard currentQuestionIndex < session.questions.count - 1 else { return }
        currentQuestionIndex += 1
    }

    func finishSession() {
        if currentPhase == .questions, let question = currentQuestion {
            recordAnswer(for: question)
        }
        stopTimer()
        session.readingTimeSeconds = elapsedSeconds

        let answers = buildAnswers()
        Task {
            let scored = await sessionService.completeSession(
                session,
                answers: answers,
                readingTimeSeconds: elapsedSeconds
            )
            result = scored
            session.result = scored
            currentPhase = .completed
            navigateToResult = true
        }
    }

    private func recordAnswer(for question: ReadingQuestion) {
        guard let selected = selectedAnswers[question.id] else { return }
        let answer = ReadingAnswer(
            questionId: question.id,
            selectedAnswer: selected,
            isCorrect: normalize(selected) == normalize(question.correctAnswer)
        )
        session.answers.removeAll { $0.questionId == question.id }
        session.answers.append(answer)
    }

    private func buildAnswers() -> [ReadingAnswer] {
        session.questions.compactMap { question in
            guard let selected = selectedAnswers[question.id] else { return nil }
            return ReadingAnswer(
                questionId: question.id,
                selectedAnswer: selected,
                isCorrect: normalize(selected) == normalize(question.correctAnswer)
            )
        }
    }

    private func startTimer() {
        guard timerCancellable == nil else { return }
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.elapsedSeconds += 1
            }
    }

    private func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    private func normalize(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}

private extension ReadingTextAnalyzing {
    func estimatedReadingTimeSeconds(wordCount: Int) -> Int {
        max(30, estimatedReadingMinutes(wordCount: wordCount) * 60)
    }
}
