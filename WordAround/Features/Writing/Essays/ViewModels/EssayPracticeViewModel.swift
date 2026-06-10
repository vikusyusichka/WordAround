import Foundation
import Combine
import FirebaseAuth

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
            guard selectedLanguage != oldValue else { return }
            resetSourceLanguagesIfNeeded()
            clearFeedback()
            clearAssistanceResults()
        }
    }

    @Published var selectedDifficulty: EssayDifficulty {
        didSet {
            guard selectedDifficulty != oldValue else { return }
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
    @Published private(set) var grammarIssueSaveStates: [String: SaveGrammarMistakeConfirmationSheet.SaveState] = [:]

    @Published var pendingMistakeIssue: GrammarIssue? = nil

    @Published private(set) var usedHints: Int = 0
    @Published private(set) var usedTranslations: Int = 0
    @Published private(set) var usedSynonyms: Int = 0
    @Published private(set) var shownHintItems: [EssaySetHintItem] = []

    @Published var isSetSelectionPresented: Bool = false
    @Published var selectedHintSet: FlashcardSet?
    @Published var isSetHintsPresented: Bool = false
    @Published var selectedSetHintItems: [EssaySetHintItem] = []
    @Published var selectedEssaySetHints: [EssaySetHintItem] = []
    @Published private(set) var availableSets: [FlashcardSet] = []
    @Published private(set) var isLoadingSets: Bool = false
    @Published private(set) var setSelectionError: String?

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
    private let flashcardSetService = FlashcardSetService()
    private let grammarMistakeSaveService = GrammarMistakeSaveService()
    private let grammarNotesSettingsStore = GrammarNotesSettingsStore()
    private let statsService: DailyPracticeStatsService

    private var lastRecordedWordCount: Int = 0

    private var didAutoSaveCurrentCheck = false

    private var assistanceTask: Task<Void, Never>?

    init(
        topics: [EssayTopic]? = nil,
        grammarService: GrammarChecking? = nil,
        generationService: EssayGenerationServicing? = nil,
        availableSets: [FlashcardSet] = [],
        selectedLanguage: GrammarLanguage = .english,
        selectedDifficulty: EssayDifficulty = .b1,
        statsService: DailyPracticeStatsService = .shared
    ) {
        let resolvedTopics = topics ?? EssayTopic.predefined
        self.topics = resolvedTopics.isEmpty ? [.fallback] : resolvedTopics
        self.currentTopic = resolvedTopics.randomElement() ?? .fallback
        self.grammarService = grammarService ?? GrammarCheckService()
        self.generationService = generationService ?? EssayGenerationService()
        self.statsService = statsService
        self.availableSets = availableSets.filter { !$0.cards.isEmpty }
        self.selectedLanguage = selectedLanguage
        self.selectedDifficulty = selectedDifficulty
        self.translationSourceLanguage = Self.defaultSourceLanguage(for: selectedLanguage)
        self.assistanceSourceLanguage = Self.defaultSourceLanguage(for: selectedLanguage)
        self.essayText = ""

        updateWritingState()

        if self.availableSets.isEmpty {
            Task { await loadAvailableSets() }
        }
    }

    var canCheckGrammar: Bool {
        !isLoading && validationState.allowsGrammarCheck
    }

    var hintsLimit: Int        { selectedDifficulty.hintsLimit }
    var translationsLimit: Int { selectedDifficulty.translationLimit }
    var synonymsLimit: Int     { selectedDifficulty.synonymLimit }

    var hintsLeft: Int        { max(0, hintsLimit - usedHints) }
    var translateLeft: Int    { max(selectedDifficulty.translationLimit - usedTranslations, 0)}
    var synonymLeft: Int      { max(selectedDifficulty.synonymLimit - usedSynonyms, 0)}
    var translationsLeft: Int { max(0, translationsLimit - usedTranslations) }
    var synonymsLeft: Int     { max(0, synonymsLimit - usedSynonyms) }

    var canUseHint: Bool        { hintsLeft > 0 && !isGeneratingHint }
    var canUseTranslation: Bool { translationsLeft > 0 }
    var canUseSynonym: Bool     { synonymsLeft > 0 }

    var translationWordLimit: Int { selectedDifficulty.translationWordLimit }

    var activeTopicTitle: String {
        if let currentTask { return currentTask.title }
        switch topicMode {
        case .suggested: return currentTopic.title
        case .custom:    return customTopicText.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    var activeTopicTask: String {
        if let currentTask { return currentTask.task }
        switch topicMode {
        case .suggested: return currentTopic.taskDescription
        case .custom:    return customTopicText.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    var assistanceUsageText: String {
        "Hints: \(usedHints)/\(hintsLimit)  ·  Translations: \(usedTranslations)/\(translationsLimit)  ·  Synonyms: \(usedSynonyms)/\(synonymsLimit)  ·  Sets: \(selectedEssaySetHints.count)"
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
            taskGenerationError = "Could not generate a topic. Try again."
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
            taskGenerationError = "Could not generate a topic. Try again."
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
        clearAssistanceResults()
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

            let hintItem = EssaySetHintItem(
                id: UUID().uuidString,
                word: finalHint.category.rawValue.capitalized,
                translation: selectedDifficulty.rawValue,
                example: finalHint.text,
                imageURL: nil
            )
            shownHintItems = [hintItem]

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
            assistanceResultMessage = "Could not generate a hint. Try again."
        }

        isGeneratingHint = false
        isAssistanceLoading = false
    }

    func showHint() {
        Task { await requestHint() }
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

    func selectDifficulty(_ difficulty: EssayDifficulty) {
        guard selectedDifficulty != difficulty else { return }
        selectedDifficulty = difficulty
    }

    func openTranslateModal() {
        cancelAssistanceTaskIfNeeded()
        assistanceInputText = ""
        clearAssistanceResults()
        ensureTranslationSourceLanguageIsValid()
        activeAssistanceModal = .translate
    }

    func selectTranslationSourceLanguage(_ language: GrammarLanguage) {
        guard language != selectedLanguage else {
            assistanceResultMessage = "Choose another input language."
            return
        }
        translationSourceLanguage = language
        clearAssistanceResults()
    }

    func performTranslation() {
        cancelAssistanceTaskIfNeeded()
        assistanceTask = Task { await _performTranslation() }
    }

    func openSynonymModal() {
        cancelAssistanceTaskIfNeeded()
        assistanceInputText = ""
        clearAssistanceResults()
        ensureAssistanceSourceLanguageIsValid()
        activeAssistanceModal = .synonym
    }

    func selectAssistanceSourceLanguage(_ language: GrammarLanguage) {
        guard language != selectedLanguage else {
            assistanceResultMessage = "Choose another input language."
            return
        }
        assistanceSourceLanguage = language
        clearAssistanceResults()
    }

    func performSynonymSearch() {
        cancelAssistanceTaskIfNeeded()
        assistanceTask = Task { await _performSynonymSearch() }
    }

    func closeAssistanceModal() {
        cancelAssistanceTaskIfNeeded()
        activeAssistanceModal = nil
        assistanceInputText = ""
        clearAssistanceResults()
        isAssistanceLoading = false
    }

    func openSetSelection() {
        isSetSelectionPresented = true
        if availableSets.isEmpty && !isLoadingSets {
            Task { await loadAvailableSets() }
        }
    }

    func closeSetSelection() {
        isSetSelectionPresented = false
    }

    func loadAvailableSets() async {
        guard !isLoadingSets else { return }

        guard let uid = Auth.auth().currentUser?.uid else {
            setSelectionError = "Sign in to use words from your sets."
            availableSets = []
            return
        }

        isLoadingSets = true
        setSelectionError = nil

        do {
            let sets = try await flashcardSetService.fetchSets(for: uid)
            availableSets = sets.filter { !$0.cards.isEmpty }
        } catch {
            setSelectionError = "Could not load your sets. Try again."
            availableSets = []
        }

        isLoadingSets = false
    }

    func selectHintSet(_ set: FlashcardSet) {
        selectedHintSet = set
        selectedSetHintItems = set.cards.map { card in
            EssaySetHintItem(
                id: card.id,
                word: card.word,
                translation: card.translation,
                example: card.example,
                imageURL: card.imageURL
            )
        }
        isSetSelectionPresented = false
        isSetHintsPresented = true
    }

    func toggleEssaySetHint(_ item: EssaySetHintItem) {
        if isEssaySetHintSelected(item) {
            removeEssaySetHint(item)
        } else {
            selectedEssaySetHints.append(item)
        }
    }

    func isEssaySetHintSelected(_ item: EssaySetHintItem) -> Bool {
        selectedEssaySetHints.contains { $0.id == item.id }
    }

    func removeEssaySetHint(_ item: EssaySetHintItem) {
        selectedEssaySetHints.removeAll { $0.id == item.id }
    }

    func clearEssaySetHints() {
        selectedEssaySetHints = []
    }

    func resetEssay() {
        essayText = ""
        score = nil
        lastRecordedWordCount = 0
        resetAssistanceUsage()
        clearFeedback()
    }

    func clearFeedback() {
        grammarIssues = []
        grammarIssueSaveStates = [:]
        pendingMistakeIssue = nil
        didAutoSaveCurrentCheck = false
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

        guard selectedLanguage.supportsGrammarCheck else {
            feedbackState = .error("Grammar checking is currently unavailable for this language.")
            return
        }

        isLoading = true
        errorState = nil
        feedbackState = .loading
        didAutoSaveCurrentCheck = false

        do {
            let issues = try await grammarService.check(
                text: essayText,
                language: selectedLanguage.languageToolCode
            )

            grammarIssues = issues
            grammarIssueSaveStates = [:]
            feedbackState = issues.isEmpty ? .emptyResult : .success
            calculateScoreAfterGrammarCheck()
            recordWritingPracticeStats()
            triggerAutoSaveIfEnabled()
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? "Grammar check failed. Try again."
            errorState = message
            feedbackState = .error(message)
        }

        isLoading = false
    }

    private func triggerAutoSaveIfEnabled() {
        guard !didAutoSaveCurrentCheck else { return }
        guard grammarNotesSettingsStore.saveGrammarMistakesAutomatically else { return }
        guard !grammarIssues.isEmpty else { return }
        didAutoSaveCurrentCheck = true
        Task { [weak self] in
            await self?.saveAllGrammarIssuesIfAutoSaveEnabled()
        }
    }

    private func recordWritingPracticeStats() {
        let delta = wordCount - lastRecordedWordCount
        guard delta > 0 else { return }
        lastRecordedWordCount = wordCount
        statsService.record(
            skill: .writing,
            value: delta,
            sourceModeID: "essays"
        )
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

    func saveState(for issue: GrammarIssue) -> SaveGrammarMistakeConfirmationSheet.SaveState {
        grammarIssueSaveStates[issueSaveStateKey(issue)] ?? .idle
    }

    func requestSaveGrammarIssue(_ issue: GrammarIssue) {
        let state = saveState(for: issue)
        guard state != .saving, state != .saved, state != .duplicate else { return }

        if grammarNotesSettingsStore.askBeforeSavingMistakes {
            pendingMistakeIssue = issue
        } else {
            Task { [weak self] in await self?.saveGrammarIssueToNotes(issue) }
        }
    }

    func confirmSavePendingIssue() async {
        guard let issue = pendingMistakeIssue else { return }
        await saveGrammarIssueToNotes(issue)
    }

    func dismissPendingMistakeIssue() {
        pendingMistakeIssue = nil
    }

    func saveGrammarIssueToNotes(_ issue: GrammarIssue) async {
        let key = issueSaveStateKey(issue)
        guard saveState(for: issue) != .saving else { return }
        guard saveState(for: issue) != .saved, saveState(for: issue) != .duplicate else { return }

        guard let ownerUID = Auth.auth().currentUser?.uid, !ownerUID.isEmpty else {
            grammarIssueSaveStates[key] = .failed("Sign in to save this mistake.")
            #if DEBUG
            print("[SaveMistake] failed: ownerUID missing")
            #endif
            return
        }

        grammarIssueSaveStates[key] = .saving

        do {
            let result = try await grammarMistakeSaveService.saveMistake(
                payload: makeMistakeSavePayload(from: issue),
                ownerUID: ownerUID,
                preferredTopic: nil,
                settings: grammarNotesSettingsStore
            )

            switch result {
            case .saved:
                grammarIssueSaveStates[key] = .saved
                #if DEBUG
                print("[SaveMistake] saved key=\(key)")
                #endif
            case .duplicate:
                grammarIssueSaveStates[key] = .duplicate
                #if DEBUG
                print("[SaveMistake] duplicate key=\(key)")
                #endif
            }
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? "Could not save this mistake."
            grammarIssueSaveStates[key] = .failed(message)
            #if DEBUG
            print("[SaveMistake] failed:", error)
            #endif
        }
    }

    func saveAllGrammarIssuesIfAutoSaveEnabled() async {
        guard grammarNotesSettingsStore.saveGrammarMistakesAutomatically else { return }

        for issue in grammarIssues {
            let state = saveState(for: issue)
            guard state != .saving, state != .saved, state != .duplicate else { continue }
            await saveGrammarIssueToNotes(issue)
        }
    }

    func resetAssistanceUsage() {
        usedHints = 0
        usedTranslations = 0
        usedSynonyms = 0
        shownHintItems = []
        generatedHints = []
        hintGenerationError = nil
    }

    static func countWords(in text: String) -> Int {
        text
            .split { $0.isWhitespace || $0.isNewline }
            .filter { !$0.isEmpty }
            .count
    }

    private func _performTranslation() async {
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

        assistanceResultItems = []
        assistanceResultMessage = nil
        isAssistanceLoading = true

        do {
            let translated = try await assistanceService.translate(
                text: text,
                sourceLanguage: translationSourceLanguage,
                targetLanguage: selectedLanguage
            )

            guard !Task.isCancelled else { return }

            assistanceResultItems = [
                EssayAssistanceItem(word: text, result: translated, detail: nil)
            ]
            usedTranslations += 1
            recalculateScoreIfNeeded()
        } catch {
            guard !Task.isCancelled else { return }
            assistanceResultItems = []
            assistanceResultMessage = (error as? LocalizedError)?.errorDescription ?? "Translation failed."
        }

        isAssistanceLoading = false
    }

    private func _performSynonymSearch() async {
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

        assistanceResultItems = []
        assistanceResultMessage = nil
        isAssistanceLoading = true

        do {
            let results = try await assistanceService.synonyms(
                for: word,
                sourceLanguage: assistanceSourceLanguage,
                targetLanguage: selectedLanguage
            )

            guard !Task.isCancelled else { return }

            assistanceResultItems = results
            usedSynonyms += 1
            recalculateScoreIfNeeded()
        } catch {
            guard !Task.isCancelled else { return }
            assistanceResultItems = []
            assistanceResultMessage = (error as? LocalizedError)?.errorDescription ?? "No result found."
        }

        isAssistanceLoading = false
    }

    private func issueSaveStateKey(_ issue: GrammarIssue) -> String {
        [
            selectedLanguage.languageToolCode,
            issue.incorrectText,
            issue.suggestedCorrection ?? "",
            issue.message,
            String(issue.offset),
            String(issue.length)
        ]
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
        .joined(separator: "|")
    }

    private func makeMistakeSavePayload(from issue: GrammarIssue) -> GrammarMistakeSavePayload {
        GrammarMistakeSavePayload(
            originalSentence: issue.incorrectText,
            correctedSentence: issue.suggestedCorrection ?? issue.incorrectText,
            explanation: issue.message,
            languageCode: selectedLanguage.languageToolCode,
            languageName: String(describing: selectedLanguage).capitalized,
            sourceIssueId: issueSaveStateKey(issue),
            ruleId: nil
        )
    }

    private var activeWordRange: ClosedRange<Int> {
        if let currentTask { return currentTask.wordRange }
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
            clearFeedback()
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

        return try await generationService.generateSuggestedTask(
            language: selectedLanguage,
            avoidTitles: usedTaskTitles + [firstTask.title]
        )
    }

    private func appendUsedTaskTitle(_ title: String) {
        let cleaned = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }
        usedTaskTitles.append(cleaned)
        usedTaskTitles = Array(usedTaskTitles.suffix(12))
    }

    private func isDuplicateTitle(_ title: String) -> Bool {
        usedTaskTitles.contains { $0.caseInsensitiveCompare(title) == .orderedSame }
    }

    private func preventDuplicateHint(_ hint: EssayGeneratedHint) -> EssayGeneratedHint {
        let isDuplicate = generatedHints.contains { $0.text.caseInsensitiveCompare(hint.text) == .orderedSame }
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

    private func cancelAssistanceTaskIfNeeded() {
        assistanceTask?.cancel()
        assistanceTask = nil
    }

    private func resetSourceLanguagesIfNeeded() {
        if translationSourceLanguage == selectedLanguage {
            translationSourceLanguage = Self.defaultSourceLanguage(for: selectedLanguage)
        }
        if assistanceSourceLanguage == selectedLanguage {
            assistanceSourceLanguage = Self.defaultSourceLanguage(for: selectedLanguage)
        }
    }

    private func ensureTranslationSourceLanguageIsValid() {
        if translationSourceLanguage == selectedLanguage {
            translationSourceLanguage = Self.defaultSourceLanguage(for: selectedLanguage)
        }
    }

    private func ensureAssistanceSourceLanguageIsValid() {
        if assistanceSourceLanguage == selectedLanguage {
            assistanceSourceLanguage = Self.defaultSourceLanguage(for: selectedLanguage)
        }
    }

    private static func defaultSourceLanguage(for targetLanguage: GrammarLanguage) -> GrammarLanguage {
        targetLanguage == .english ? .spanish : .english
    }
}
