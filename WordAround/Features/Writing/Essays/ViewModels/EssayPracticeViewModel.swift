import Foundation
import Combine

@MainActor
final class EssayPracticeViewModel: ObservableObject {

    enum ValidationState: Equatable {
        case empty
        case belowMinimum(Int)
        case valid
        case aboveMaximum(Int)

        var message: String? {
            switch self {
            case .empty:
                return "Start writing your essay."
            case .belowMinimum(let minimum):
                return "Write at least \(minimum) words before checking grammar."
            case .valid:
                return nil
            case .aboveMaximum(let maximum):
                return "Try to keep your essay under \(maximum) words."
            }
        }

        var allowsGrammarCheck: Bool {
            self == .valid
        }
    }

    enum FeedbackState: Equatable {
        case idle
        case loading
        case success
        case emptyResult
        case error(String)
    }

    @Published var topicMode: EssayTopicMode = .suggested {
        didSet { clearFeedback() }
    }

    @Published var customTopicText: String = "" {
        didSet { clearFeedback() }
    }

    @Published private(set) var currentTopic: EssayTopic
    @Published var currentTask: GeneratedEssayTask?
    @Published var isGeneratingTask = false
    @Published var taskGenerationError: String?
    @Published var generatedHints: [EssayGeneratedHint] = []
    @Published var isGeneratingHint = false
    @Published var hintGenerationError: String?
    @Published var usedTaskTitles: [String] = []

    @Published var essayText: String {
        didSet { updateWritingState() }
    }

    @Published var selectedLanguage: GrammarLanguage {
        didSet {
            if translationSourceLanguage == selectedLanguage {
                translationSourceLanguage = Self.defaultSourceLanguage(for: selectedLanguage)
            }

            if assistanceSourceLanguage == selectedLanguage {
                assistanceSourceLanguage = Self.defaultSourceLanguage(for: selectedLanguage)
            }

            clearFeedback()
            clearAssistanceResults()
        }
    }

    @Published var selectedDifficulty: EssayDifficulty {
        didSet {
            resetAssistanceUsage()
            updateWritingState()
            clearFeedback()
        }
    }

    @Published var translationSourceLanguage: GrammarLanguage
    @Published var assistanceSourceLanguage: GrammarLanguage

    @Published private(set) var wordCount: Int = 0
    @Published private(set) var grammarIssues: [GrammarIssue] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorState: String?
    @Published private(set) var validationState: ValidationState = .empty
    @Published private(set) var feedbackState: FeedbackState = .idle
    @Published private(set) var score: EssayScore?

    @Published private(set) var usedHints: Int = 0
    @Published private(set) var usedTranslations: Int = 0
    @Published private(set) var usedSynonyms: Int = 0
    @Published private(set) var shownHintItems: [EssayHintItem] = []

    @Published var activeAssistanceModal: EssayAssistanceModalType? = nil
    @Published var assistanceInputText: String = ""
    @Published private(set) var assistanceResultItems: [EssayAssistanceItem] = []
    @Published private(set) var assistanceResultMessage: String? = nil
    @Published private(set) var isAssistanceLoading = false

    private let topics: [EssayTopic]
    private let grammarService: GrammarChecking
    private let scoringService = EssayScoringService()
    private let assistanceService = EssayAssistanceService()
    private let generationService: EssayGenerationServicing

    init(
        topics: [EssayTopic] = EssayTopic.predefined,
        grammarService: GrammarChecking = GrammarCheckService(),
        generationService: EssayGenerationServicing = EssayGenerationService(),
        selectedLanguage: GrammarLanguage = .english,
        selectedDifficulty: EssayDifficulty = .b1
    ) {
        self.topics = topics.isEmpty ? [.fallback] : topics
        self.currentTopic = topics.randomElement() ?? .fallback
        self.grammarService = grammarService
        self.generationService = generationService
        self.selectedLanguage = selectedLanguage
        self.selectedDifficulty = selectedDifficulty
        self.translationSourceLanguage = Self.defaultSourceLanguage(for: selectedLanguage)
        self.assistanceSourceLanguage = Self.defaultSourceLanguage(for: selectedLanguage)
        self.essayText = ""

        updateWritingState()
    }

    var canCheckGrammar: Bool {
        !isLoading && validationState.allowsGrammarCheck
    }

    var hintsLimit: Int {
        selectedDifficulty.hintsLimit
    }

    var translationsLimit: Int {
        selectedDifficulty.translationLimit
    }

    var synonymsLimit: Int {
        selectedDifficulty.synonymLimit
    }

    var hintsLeft: Int {
        max(0, hintsLimit - usedHints)
    }

    var translationsLeft: Int {
        max(0, translationsLimit - usedTranslations)
    }

    var synonymsLeft: Int {
        max(0, synonymsLimit - usedSynonyms)
    }

    var canUseHint: Bool {
        hintsLeft > 0 && !isGeneratingHint
    }

    var canUseTranslation: Bool {
        translationsLeft > 0
    }

    var translationWordLimit: Int {
        selectedDifficulty.translationWordLimit
    }

    var canUseSynonym: Bool {
        synonymsLeft > 0
    }

    var activeTopicTitle: String {
        if let currentTask {
            return currentTask.title
        }

        switch topicMode {
        case .suggested:
            return currentTopic.title
        case .custom:
            return customTopicText.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    var activeTopicTask: String {
        if let currentTask {
            return currentTask.task
        }

        switch topicMode {
        case .suggested:
            return currentTopic.taskDescription
        case .custom:
            return customTopicText.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    var assistanceUsageText: String {
        "Hints: \(usedHints)/\(hintsLimit)  ·  Translations: \(usedTranslations)/\(translationsLimit)  ·  Synonyms: \(usedSynonyms)/\(synonymsLimit)"
    }

    var privacyNoticeText: String {
        "Essays are sent securely to LanguageTool for grammar checking. Do not include private information."
    }

    var availableTranslationSourceLanguages: [GrammarLanguage] {
        GrammarLanguage.allCases.filter { $0 != selectedLanguage }
    }

    var availableAssistanceSourceLanguages: [GrammarLanguage] {
        GrammarLanguage.allCases.filter { $0 != selectedLanguage }
    }

    func generateSuggestedTask() async {
        guard !isGeneratingTask else { return }

        isGeneratingTask = true
        taskGenerationError = nil

        do {
            let task = try await generateSuggestedTaskAvoidingDuplicates()
            applyGeneratedTask(task)
        } catch {
            taskGenerationError = Self.displayMessage(
                from: error,
                fallback: "Could not generate a topic. Try again."
            )
        }

        isGeneratingTask = false
    }

    func generateTaskFromCustomTopic() async {
        guard !isGeneratingTask else { return }

        let topic = customTopicText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !topic.isEmpty else {
            taskGenerationError = "Enter a topic first."
            return
        }

        isGeneratingTask = true
        taskGenerationError = nil

        do {
            let task = try await generationService.generateTaskFromCustomTopic(
                topic: topic,
                language: selectedLanguage
            )
            applyGeneratedTask(task)
        } catch {
            taskGenerationError = Self.displayMessage(
                from: error,
                fallback: "Could not generate a topic. Try again."
            )
        }

        isGeneratingTask = false
    }

    func requestHint() async {
        guard canUseHint else {
            hintGenerationError = "No hints are left for this level."
            return
        }

        isGeneratingHint = true
        isAssistanceLoading = true
        hintGenerationError = nil
        assistanceResultItems = []
        assistanceResultMessage = nil
        activeAssistanceModal = .hint

        do {
            let hint = try await generationService.generateHint(
                language: selectedLanguage,
                level: selectedDifficulty,
                topicTitle: activeTopicTitle,
                task: activeTopicTask,
                essayText: essayText,
                previousHints: generatedHints.map(\.text)
            )

            let finalHint = preventDuplicateHint(hint)
            generatedHints.append(finalHint)
            usedHints += 1
            shownHintItems = [
                EssayHintItem(
                    word: finalHint.category.rawValue.capitalized,
                    translation: selectedDifficulty.rawValue,
                    example: finalHint.text
                )
            ]
            assistanceResultItems = [
                EssayAssistanceItem(
                    word: finalHint.category.rawValue,
                    result: finalHint.text,
                    detail: finalHint.category.rawValue.capitalized
                )
            ]
            recalculateScoreIfNeeded()
        } catch {
            hintGenerationError = "Could not generate a hint. Try again."
            assistanceResultItems = []
            assistanceResultMessage = "Could not generate a hint. Try again."
        }

        isGeneratingHint = false
        isAssistanceLoading = false
    }

    func selectRandomTopic() {
        currentTask = nil
        let nextTopic = topics
            .filter { $0.id != currentTopic.id }
            .randomElement() ?? topics.randomElement() ?? .fallback

        currentTopic = nextTopic
        resetEssay()
    }

    func selectTopicMode(_ mode: EssayTopicMode) {
        guard topicMode != mode else { return }
        topicMode = mode
        currentTask = nil
        taskGenerationError = nil
        updateWritingState()

        if mode == .suggested {
            Task { await generateSuggestedTask() }
        }
    }

    func updateCustomTopic(_ text: String) {
        customTopicText = text
        currentTask = nil
        taskGenerationError = nil
        updateWritingState()
    }

    func selectLanguage(_ language: GrammarLanguage) {
        guard selectedLanguage != language else { return }
        selectedLanguage = language
    }

    func selectTranslationSourceLanguage(_ language: GrammarLanguage) {
        guard language != selectedLanguage else {
            assistanceResultMessage = "Choose another input language."
            return
        }

        translationSourceLanguage = language
        clearAssistanceResults()
    }

    func selectAssistanceSourceLanguage(_ language: GrammarLanguage) {
        guard language != selectedLanguage else {
            assistanceResultMessage = "Choose another input language."
            return
        }

        assistanceSourceLanguage = language
        clearAssistanceResults()
    }

    func selectDifficulty(_ difficulty: EssayDifficulty) {
        guard selectedDifficulty != difficulty else { return }
        selectedDifficulty = difficulty
    }

    func resetEssay() {
        essayText = ""
        score = nil
        resetAssistanceUsage()
        clearFeedback()
    }

    func clearFeedback() {
        grammarIssues = []
        errorState = nil
        feedbackState = .idle
        score = nil
    }

    func retryGrammarCheck() async {
        await checkGrammar()
    }

    func checkGrammar() async {
        updateWritingState()

        guard validationState.allowsGrammarCheck else {
            feedbackState = validationState == .empty
                ? .error("Write something before checking grammar.")
                : .error(validationState.message ?? "Check the word count first.")
            return
        }

        isLoading = true
        errorState = nil
        feedbackState = .loading

        do {
            let issues = try await grammarService.check(
                text: essayText,
                language: selectedLanguage.languageToolCode
            )

            grammarIssues = issues
            feedbackState = issues.isEmpty ? .emptyResult : .success
            calculateScoreAfterGrammarCheck()
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? "Grammar check failed. Try again."
            errorState = message
            feedbackState = .error(message)
        }

        isLoading = false
    }

    func calculateScoreAfterGrammarCheck() {
        let input = EssayScoringInput(
            text: essayText,
            topic: activeTopicTitle,
            wordRange: activeWordRange,
            grammarIssues: grammarIssues,
            usedHints: usedHints,
            usedTranslations: usedTranslations,
            usedSynonyms: usedSynonyms,
            difficulty: selectedDifficulty
        )

        score = scoringService.score(input: input)
    }

    func showHint() {
        Task { await requestHint() }
    }

    func openTranslateModal() {
        assistanceInputText = ""
        clearAssistanceResults()

        if translationSourceLanguage == selectedLanguage {
            translationSourceLanguage = Self.defaultSourceLanguage(for: selectedLanguage)
        }

        activeAssistanceModal = .translate
    }

    func performTranslation() async {
        let text = assistanceInputText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !text.isEmpty else {
            assistanceResultMessage = "Enter a word or short phrase."
            return
        }

        guard canUseTranslation else {
            assistanceResultMessage = "Translation is not available for this level."
            return
        }

        let wordsCount = Self.countWords(in: text)

        if translationWordLimit > 0 && wordsCount > translationWordLimit {
            assistanceResultMessage = "Use up to \(translationWordLimit) words."
            return
        }

        guard translationSourceLanguage != selectedLanguage else {
            assistanceResultMessage = "Choose another input language."
            return
        }

        isAssistanceLoading = true
        clearAssistanceResults()

        do {
            let translated = try await assistanceService.translate(
                text: text,
                sourceLanguage: translationSourceLanguage,
                targetLanguage: selectedLanguage
            )

            assistanceResultItems = [
                EssayAssistanceItem(
                    word: text,
                    result: translated,
                    detail: nil
                )
            ]

            usedTranslations += 1
            recalculateScoreIfNeeded()
        } catch {
            assistanceResultItems = []
            assistanceResultMessage = (error as? LocalizedError)?.errorDescription ?? "Translation failed."
        }

        isAssistanceLoading = false
    }

    func openSynonymModal() {
        assistanceInputText = ""
        clearAssistanceResults()

        if assistanceSourceLanguage == selectedLanguage {
            assistanceSourceLanguage = Self.defaultSourceLanguage(for: selectedLanguage)
        }

        activeAssistanceModal = .synonym
    }

    func performSynonymSearch() async {
        let word = assistanceInputText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !word.isEmpty else {
            assistanceResultMessage = "Enter a word."
            return
        }

        guard canUseSynonym else {
            assistanceResultMessage = "No synonym helpers are left for this level."
            return
        }

        guard assistanceSourceLanguage != selectedLanguage else {
            assistanceResultMessage = "Choose another input language."
            return
        }

        isAssistanceLoading = true
        clearAssistanceResults()

        do {
            let results = try await assistanceService.synonyms(
                for: word,
                sourceLanguage: assistanceSourceLanguage,
                targetLanguage: selectedLanguage
            )

            assistanceResultItems = results
            usedSynonyms += 1
            recalculateScoreIfNeeded()
        } catch {
            assistanceResultItems = []
            assistanceResultMessage = (error as? LocalizedError)?.errorDescription ?? "No result found."
        }

        isAssistanceLoading = false
    }

    func closeAssistanceModal() {
        activeAssistanceModal = nil
        assistanceInputText = ""
        clearAssistanceResults()
        isAssistanceLoading = false
    }

    func registerHintUsage() {
        guard canUseHint else { return }
        usedHints += 1
        recalculateScoreIfNeeded()
    }

    func registerTranslationUsage() {
        guard canUseTranslation else { return }
        usedTranslations += 1
        recalculateScoreIfNeeded()
    }

    func resetAssistanceUsage() {
        usedHints = 0
        usedTranslations = 0
        usedSynonyms = 0
        shownHintItems = []
        generatedHints = []
        hintGenerationError = nil
    }

    private var activeWordRange: ClosedRange<Int> {
        if let currentTask {
            return currentTask.wordRange
        }

        return topicMode == .suggested ? currentTopic.wordRange : 60...300
    }

    private func updateWritingState() {
        wordCount = Self.countWords(in: essayText)
        let range = activeWordRange

        if essayText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationState = .empty
        } else if wordCount < range.lowerBound {
            validationState = .belowMinimum(range.lowerBound)
        } else if wordCount > range.upperBound {
            validationState = .aboveMaximum(range.upperBound)
        } else {
            validationState = .valid
        }

        if !grammarIssues.isEmpty || errorState != nil || score != nil {
            grammarIssues = []
            errorState = nil
            feedbackState = .idle
            score = nil
        }
    }

    private func applyGeneratedTask(_ task: GeneratedEssayTask) {
        currentTask = task
        selectedDifficulty = task.detectedLevel
        appendUsedTaskTitle(task.title)
        resetEssay()
        updateWritingState()
    }

    private func generateSuggestedTaskAvoidingDuplicates() async throws -> GeneratedEssayTask {
        let firstTask = try await generationService.generateSuggestedTask(
            language: selectedLanguage,
            avoidTitles: usedTaskTitles
        )

        guard isDuplicateTitle(firstTask.title) else {
            return firstTask
        }

        let retryTask = try await generationService.generateSuggestedTask(
            language: selectedLanguage,
            avoidTitles: usedTaskTitles + [firstTask.title]
        )

        return retryTask
    }

    private func appendUsedTaskTitle(_ title: String) {
        let cleaned = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }

        usedTaskTitles.append(cleaned)
        usedTaskTitles = Array(usedTaskTitles.suffix(12))
    }

    private func isDuplicateTitle(_ title: String) -> Bool {
        usedTaskTitles.contains { existing in
            existing.caseInsensitiveCompare(title) == .orderedSame
        }
    }

    private func preventDuplicateHint(_ hint: EssayGeneratedHint) -> EssayGeneratedHint {
        let isDuplicate = generatedHints.contains { existing in
            existing.text.caseInsensitiveCompare(hint.text) == .orderedSame
        }

        guard isDuplicate else { return hint }
        return EssayGeneratedHint(text: "Add one clear supporting example.", category: .structure)
    }

    private func clearAssistanceResults() {
        assistanceResultItems = []
        assistanceResultMessage = nil
    }

    private func recalculateScoreIfNeeded() {
        guard score != nil else { return }
        calculateScoreAfterGrammarCheck()
    }

    private static func defaultSourceLanguage(for targetLanguage: GrammarLanguage) -> GrammarLanguage {
        switch targetLanguage {
        case .english:
            return .spanish
        case .spanish, .french, .german:
            return .english
        }
    }

    private static func displayMessage(from error: Error, fallback: String) -> String {
        (error as? LocalizedError)?.errorDescription ?? fallback
    }

    static func countWords(in text: String) -> Int {
        text
            .split { $0.isWhitespace || $0.isNewline }
            .filter { !$0.isEmpty }
            .count
    }
}
