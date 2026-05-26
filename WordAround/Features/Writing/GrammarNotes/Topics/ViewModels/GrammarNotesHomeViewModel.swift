import Foundation
import FirebaseFirestore
import Combine

@MainActor
final class GrammarNotesHomeViewModel: ObservableObject {
    @Published private(set) var topics: [GrammarNoteTopic] = []
    @Published private(set) var filteredTopics: [GrammarNoteTopic] = []
    @Published private(set) var topicOptions: [GrammarQuickTopicOption] = []
    @Published private(set) var regularTopicOptions: [GrammarQuickTopicOption] = []
    @Published private(set) var mistakesTopicOption: GrammarQuickTopicOption?
    @Published private(set) var isLoading = false
    @Published private(set) var isCreatingTopic = false
    @Published private(set) var isCreatingQuickNote = false
    @Published private(set) var isCreatingQuickMistake = false
    @Published var searchText = ""
    @Published var errorMessage: String?
    @Published private(set) var quickNoteError: String?
    @Published private(set) var quickMistakeError: String?

    private let ownerUID: String
    private let service: GrammarNoteTopicServicing
    private let noteService: GrammarNoteServicing
    private let createQuickNoteUseCase: CreateQuickGrammarNoteUseCase
    private let saveQuickMistakeUseCase: SaveQuickGrammarMistakeUseCase
    private var isEnsuringDefaultTopic = false
    private var cancellables = Set<AnyCancellable>()

    var hasOnlyMistakesTopic: Bool {
        topics.filter { !$0.isMistakesTopic }.isEmpty
    }

    // MARK: - Init

    init(
        ownerUID: String,
        service: GrammarNoteTopicServicing? = nil,
        noteService: GrammarNoteServicing? = nil,
        previewTopics: [GrammarNoteTopic] = []
    ) {
        self.ownerUID = ownerUID
        let resolvedTopicService = service ?? GrammarNoteTopicService()
        let resolvedNoteService = noteService ?? GrammarNoteService()
        self.service = resolvedTopicService
        self.noteService = resolvedNoteService
        self.createQuickNoteUseCase = CreateQuickGrammarNoteUseCase(noteService: resolvedNoteService)
        self.saveQuickMistakeUseCase = SaveQuickGrammarMistakeUseCase(noteService: resolvedNoteService)
        updateTopics(previewTopics)
        bindSearch()
    }

    // MARK: - Topic loading

    func loadTopics() async {
        guard !ownerUID.isEmpty else {
            errorMessage = "User session is not available. Please sign in again."
            return
        }

        // Phase 1: show cached topics immediately — no spinner needed
        if topics.isEmpty {
            if let cached = try? await service.fetchTopics(for: ownerUID, source: .cache),
               !cached.isEmpty {
                updateTopics(sortTopics(cached))
            }
        }

        // Phase 2: server refresh; show spinner only when cache was empty
        let needsSpinner = topics.isEmpty
        if needsSpinner { isLoading = true }
        defer { isLoading = false }
        errorMessage = nil

        do {
            var loadedTopics = try await service.fetchTopics(for: ownerUID)
            loadedTopics = try await ensureCommonMistakesTopicExists(in: loadedTopics)
            updateTopics(sortTopics(loadedTopics))
        } catch {
            if topics.isEmpty {
                errorMessage = readableMessage(for: error)
            }
        }
    }

    // MARK: - Topic creation

    func createTopic(
        title: String,
        description: String,
        languageCode: String,
        languageName: String,
        icon: String,
        colorHex: String
    ) async -> Bool {
        guard !isCreatingTopic else { return false }
        guard !ownerUID.isEmpty else {
            errorMessage = "User session is not available. Please sign in again."
            return false
        }

        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTitle.isEmpty else {
            errorMessage = "Topic title is required."
            return false
        }
        guard trimmedTitle.count <= 40 else {
            errorMessage = "Topic title must be under 40 characters."
            return false
        }
        guard trimmedDescription.count <= 120 else {
            errorMessage = "Description must be under 120 characters."
            return false
        }

        let now = Date()
        let topic = GrammarNoteTopic(
            id: UUID().uuidString,
            ownerUID: ownerUID,
            title: trimmedTitle,
            description: trimmedDescription,
            languageCode: languageCode,
            languageName: languageName,
            icon: icon,
            colorHex: colorHex,
            notesCount: 0,
            isPinned: false,
            isMistakesTopic: false,
            createdAt: now,
            updatedAt: now
        )

        isCreatingTopic = true
        errorMessage = nil
        defer { isCreatingTopic = false }

        do {
            try await service.createTopic(topic)
            updateTopics(sortTopics(topics + [topic]))
            return true
        } catch {
            errorMessage = readableMessage(for: error)
            return false
        }
    }

    func deleteTopic(_ topic: GrammarNoteTopic) async {
        guard !topic.isMistakesTopic else { return }
        do {
            try await service.deleteTopic(id: topic.id, ownerUID: ownerUID)
            updateTopics(topics.filter { $0.id != topic.id })
            errorMessage = nil
        } catch {
            errorMessage = readableMessage(for: error)
        }
    }

    // MARK: - Quick Note creation

    func createQuickNote(draft: QuickGrammarNoteDraft) async -> GrammarNote? {
        guard !isCreatingQuickNote else { return nil }
        guard let matchedTopic = topics.first(where: { $0.id == draft.topic.id }) else {
            quickNoteError = "Selected topic not found. Please reload and try again."
            return nil
        }

        isCreatingQuickNote = true
        quickNoteError = nil
        defer { isCreatingQuickNote = false }

        do {
            let saved = try await createQuickNoteUseCase.execute(
                ownerUID: ownerUID,
                topic: matchedTopic,
                draft: draft
            )
            incrementNotesCount(for: matchedTopic.id)
            return saved
        } catch {
            quickNoteError = readableMessage(for: error)
            return nil
        }
    }

    // MARK: - Quick Mistake creation

    func createQuickMistake(
        draft: QuickGrammarMistakeDraft,
        settings: GrammarNotesSettingsStore
    ) async -> GrammarNote? {
        guard !isCreatingQuickMistake else { return nil }
        isCreatingQuickMistake = true
        quickMistakeError = nil
        defer { isCreatingQuickMistake = false }

        // Resolve target topic
        let targetTopic: GrammarNoteTopic
        if settings.groupMistakesByTopic,
           let found = topics.first(where: { $0.id == draft.topic.id }) {
            targetTopic = found
        } else {
            guard let mistakes = await getOrCreateMistakesTopic() else {
                quickMistakeError = "Could not find or create Common Mistakes topic."
                return nil
            }
            targetTopic = mistakes
        }

        do {
            let outcome = try await saveQuickMistakeUseCase.execute(
                ownerUID: ownerUID,
                targetTopic: targetTopic,
                draft: draft,
                settings: settings
            )

            switch outcome {
            case .duplicate(let duplicate):
                quickMistakeError = nil
                return duplicate
            case .created(let saved):
                incrementNotesCount(for: targetTopic.id)
                return saved
            }
        } catch {
            quickMistakeError = readableMessage(for: error)
            return nil
        }
    }

    // MARK: - Private helpers

    private func getOrCreateMistakesTopic() async -> GrammarNoteTopic? {
        if let existing = topics.first(where: { $0.isMistakesTopic }) { return existing }
        do {
            let topic = try await service.ensureDefaultMistakesTopic(ownerUID: ownerUID)
            if !topics.contains(where: { $0.id == topic.id }) {
                updateTopics(sortTopics(topics + [topic]))
            }
            return topic
        } catch {
            return nil
        }
    }

    private func ensureCommonMistakesTopicExists(in loadedTopics: [GrammarNoteTopic]) async throws -> [GrammarNoteTopic] {
        guard !loadedTopics.contains(where: { $0.isMistakesTopic }) else { return loadedTopics }
        guard !isEnsuringDefaultTopic else { return loadedTopics }
        isEnsuringDefaultTopic = true
        defer { isEnsuringDefaultTopic = false }

        let mistakesTopic = try await service.ensureDefaultMistakesTopic(ownerUID: ownerUID)
        return loadedTopics.contains(where: { $0.id == mistakesTopic.id }) ? loadedTopics : loadedTopics + [mistakesTopic]
    }

    private func bindSearch() {
        $searchText
            .sink { [weak self] _ in
                self?.refreshFilteredTopics()
            }
            .store(in: &cancellables)
    }

    private func updateTopics(_ newTopics: [GrammarNoteTopic]) {
        guard newTopics != topics else {
            refreshFilteredTopics()
            refreshTopicOptions()
            return
        }
        topics = newTopics
        refreshFilteredTopics()
        refreshTopicOptions()
    }

    private func refreshFilteredTopics() {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else {
            filteredTopics = topics
            return
        }
        filteredTopics = topics.filter { topic in
            topic.title.lowercased().contains(query)
            || topic.description.lowercased().contains(query)
            || topic.languageName.lowercased().contains(query)
        }
    }

    private func refreshTopicOptions() {
        let mapped = topics.map { Self.topicOption(for: $0) }
        topicOptions = mapped
        regularTopicOptions = mapped.filter { option in
            topics.first(where: { $0.id == option.id })?.isMistakesTopic == false
        }
        mistakesTopicOption = mapped.first { option in
            topics.first(where: { $0.id == option.id })?.isMistakesTopic == true
        }
    }

    private func incrementNotesCount(for topicID: String) {
        guard let index = topics.firstIndex(where: { $0.id == topicID }) else { return }
        var updatedTopics = topics
        updatedTopics[index].notesCount += 1
        updatedTopics[index].updatedAt = Date()
        updateTopics(sortTopics(updatedTopics))
    }

    private static func topicOption(for topic: GrammarNoteTopic) -> GrammarQuickTopicOption {
        let tint = CreateSetTheme.theme(forHex: topic.colorHex).accent
        return GrammarQuickTopicOption(
            id: topic.id,
            title: topic.title,
            subtitle: "\(topic.notesCount) notes",
            tint: tint,
            systemImage: topic.icon
        )
    }

    private func sortTopics(_ topics: [GrammarNoteTopic]) -> [GrammarNoteTopic] {
        topics.sorted { lhs, rhs in
            if lhs.isPinned != rhs.isPinned { return lhs.isPinned && !rhs.isPinned }
            if lhs.isMistakesTopic != rhs.isMistakesTopic { return lhs.isMistakesTopic && !rhs.isMistakesTopic }
            return lhs.updatedAt > rhs.updatedAt
        }
    }

    private func readableMessage(for error: Error) -> String {
        GrammarNotesErrorMessages.readable(
            for: error,
            firestorePermission: "Missing Firestore permission for grammar note topics. Update Firestore rules for users/{uid}/grammarNoteTopics."
        )
    }
}
