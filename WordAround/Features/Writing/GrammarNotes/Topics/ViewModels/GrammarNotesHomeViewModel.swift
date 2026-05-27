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

        // Flip the loading flag FIRST so the sheet's spinner always observes
        // a true → false transition, even on early validation bail-out.
        // Otherwise an early `return false` would never publish a state
        // change and the parent button could appear "stuck" to the user.
        isCreatingTopic = true
        errorMessage = nil
        defer { isCreatingTopic = false }

        await Task.yield()

        guard !ownerUID.isEmpty else {
            errorMessage = "User session is not available. Please sign in again."
            #if DEBUG
            print("[CreateTopic] failed: ownerUID is empty")
            #endif
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

        #if DEBUG
        print("[CreateTopic] saving to users/\(ownerUID)/grammarNoteTopics/\(topic.id)")
        #endif

        do {
            try await service.createTopic(topic)
            updateTopics(sortTopics(topics + [topic]))
            #if DEBUG
            print("[CreateTopic] saved id=\(topic.id)")
            #endif
            return true
        } catch {
            errorMessage = readableMessage(for: error)
            #if DEBUG
            print("[CreateTopic] failed:", error)
            #endif
            return false
        }
    }

    // MARK: - Topic from template

    /// Creates a topic from a `GrammarTopicTemplate` together with all its
    /// starter notes. Reuses `isCreatingTopic` so the existing
    /// `CreateGrammarTopicSheet` spinner / disabled-button logic and the
    /// double-tap guard apply unchanged.
    ///
    /// Behavior:
    /// - Honors `allowQuickQuizzes`: quiz blocks are stripped before any write.
    /// - Creates one topic doc, then per-note docs sequentially (Firestore
    ///   service handles best-effort topic counter increments).
    /// - Locally updates the topics list with the correct `notesCount` so the
    ///   home screen reflects the result without a global reload.
    /// - Returns the created topic on success, `nil` on failure.
    func createTopicFromTemplate(
        _ template: GrammarTopicTemplate,
        settings: GrammarNotesSettingsStore
    ) async -> GrammarNoteTopic? {
        guard !isCreatingTopic else { return nil }

        isCreatingTopic = true
        errorMessage = nil
        defer { isCreatingTopic = false }

        await Task.yield()

        guard !ownerUID.isEmpty else {
            errorMessage = "User session is not available. Please sign in again."
            #if DEBUG
            print("[CreateTopicFromTemplate] failed: ownerUID empty")
            #endif
            return nil
        }

        let effectiveTemplate = settings.allowQuickQuizzes
            ? template
            : template.withoutQuizBlocks()

        let now = Date()
        let topicID = UUID().uuidString
        let topic = GrammarNoteTopic(
            id: topicID,
            ownerUID: ownerUID,
            title: effectiveTemplate.title,
            description: effectiveTemplate.description,
            languageCode: effectiveTemplate.languageCode ?? "",
            languageName: effectiveTemplate.languageName ?? "",
            icon: effectiveTemplate.icon,
            colorHex: effectiveTemplate.colorHex,
            notesCount: 0,
            isPinned: false,
            isMistakesTopic: false,
            createdAt: now,
            updatedAt: now
        )

        #if DEBUG
        print("[CreateTopicFromTemplate] writing topic \(topicID) with \(effectiveTemplate.noteTemplates.count) notes")
        #endif

        // 1. Topic document.
        do {
            try await service.createTopic(topic)
        } catch {
            errorMessage = readableMessage(for: error)
            #if DEBUG
            print("[CreateTopicFromTemplate] topic write failed:", error)
            #endif
            return nil
        }

        // 2. Note documents — sequential awaits keep ordering deterministic
        //    and avoid hammering Firestore. Each note write is best-effort:
        //    a single note failure won't roll back the topic.
        var savedCount = 0
        for (index, noteTemplate) in effectiveTemplate.noteTemplates.enumerated() {
            let blocks = noteTemplate.blocks.enumerated().map { i, block -> GrammarNoteBlock in
                var copy = block
                copy.id = UUID().uuidString
                copy.order = i
                copy.createdAt = now
                copy.updatedAt = now
                return copy
            }
            let plainText = Self.plainText(from: blocks)
            let previewText = Self.previewText(from: blocks, fallback: noteTemplate.description)

            let note = GrammarNote(
                id: UUID().uuidString,
                ownerUID: ownerUID,
                topicId: topicID,
                title: noteTemplate.title,
                previewText: previewText,
                languageCode: effectiveTemplate.languageCode ?? noteTemplate.languageCode ?? "",
                languageName: effectiveTemplate.languageName ?? "",
                noteType: noteTemplate.noteType,
                tags: noteTemplate.tags,
                imageURLs: [],
                isPinned: false,
                isFavorite: false,
                isMistakeNote: noteTemplate.noteType == .mistake,
                savedIssueKey: nil,
                hasQuiz: blocks.contains { $0.type == .quiz },
                contentBlocks: blocks,
                plainTextContent: plainText,
                coverImageURL: nil,
                localImagePaths: [],
                templateId: noteTemplate.id,
                createdAt: now,
                updatedAt: now,
                lastEditedAt: now,
                searchableText: GrammarNoteSearchIndexer.makeSearchableText(
                    title: noteTemplate.title,
                    previewText: previewText,
                    tags: noteTemplate.tags,
                    noteType: noteTemplate.noteType,
                    blocks: blocks,
                    plainTextContent: plainText
                )
            )

            do {
                try await noteService.createNote(note)
                savedCount += 1
                #if DEBUG
                print("[CreateTopicFromTemplate] note \(index + 1)/\(effectiveTemplate.noteTemplates.count) saved")
                #endif
            } catch {
                #if DEBUG
                print("[CreateTopicFromTemplate] note \(index + 1) failed (continuing):", error)
                #endif
                // Continue — partial success is better than rolling everything back.
            }
        }

        // 3. Local state — reflect the correct count without a full reload.
        var localTopic = topic
        localTopic.notesCount = savedCount
        updateTopics(sortTopics(topics + [localTopic]))

        return localTopic
    }

    // MARK: - Static helpers (topic-template path)

    private static func plainText(from blocks: [GrammarNoteBlock]) -> String {
        blocks.flatMap { block -> [String] in
            var parts: [String] = []
            if !block.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { parts.append(block.text) }
            if let s = block.secondaryText,
               !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { parts.append(s) }
            parts.append(contentsOf: block.items.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
            return parts
        }
        .joined(separator: "\n")
    }

    private static func previewText(from blocks: [GrammarNoteBlock], fallback: String) -> String {
        let first = blocks
            .flatMap { [$0.text, $0.secondaryText ?? ""] + $0.items }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty } ?? fallback
        return String(first.prefix(180))
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

        // 1. Flip the loading flag FIRST so the sheet always observes a
        //    true → false transition (even if we bail out early below).
        //    Without this, an early `return nil` would leave `didSubmitSave`
        //    stuck `true` in the sheet and the spinner would never clear.
        isCreatingQuickNote = true
        quickNoteError = nil
        defer { isCreatingQuickNote = false }

        // Let SwiftUI render the spinner state before any synchronous bail-out.
        await Task.yield()

        // 2. Validate required inputs.
        guard !ownerUID.isEmpty else {
            quickNoteError = "User session is not available. Please sign in again."
            #if DEBUG
            print("[QuickNote] save failed: ownerUID is empty")
            #endif
            return nil
        }
        guard let matchedTopic = topics.first(where: { $0.id == draft.topic.id }) else {
            quickNoteError = "Selected topic not found. Please reload and try again."
            #if DEBUG
            print("[QuickNote] save failed: topic \(draft.topic.id) not found in \(topics.count) topics")
            #endif
            return nil
        }

        // 3. Save.
        #if DEBUG
        print("[QuickNote] saving to users/\(ownerUID)/grammarNoteTopics/\(matchedTopic.id)/notes")
        #endif

        do {
            let saved = try await createQuickNoteUseCase.execute(
                ownerUID: ownerUID,
                topic: matchedTopic,
                draft: draft
            )
            incrementNotesCount(for: matchedTopic.id)
            #if DEBUG
            print("[QuickNote] saved id=\(saved.id)")
            #endif
            return saved
        } catch {
            quickNoteError = readableMessage(for: error)
            #if DEBUG
            print("[QuickNote] save failed:", error)
            #endif
            return nil
        }
    }

    // MARK: - Quick Mistake creation

    func createQuickMistake(
        draft: QuickGrammarMistakeDraft,
        settings: GrammarNotesSettingsStore
    ) async -> GrammarNote? {
        guard !isCreatingQuickMistake else { return nil }

        // Set the loading flag immediately so the sheet always observes the
        // true → false transition, even on early validation bail-out.
        isCreatingQuickMistake = true
        quickMistakeError = nil
        defer { isCreatingQuickMistake = false }

        await Task.yield()

        guard !ownerUID.isEmpty else {
            quickMistakeError = "User session is not available. Please sign in again."
            #if DEBUG
            print("[QuickMistake] save failed: ownerUID is empty")
            #endif
            return nil
        }

        // Resolve target topic
        let targetTopic: GrammarNoteTopic
        if settings.groupMistakesByTopic,
           let found = topics.first(where: { $0.id == draft.topic.id }) {
            targetTopic = found
        } else {
            guard let mistakes = await getOrCreateMistakesTopic() else {
                quickMistakeError = "Could not find or create Common Mistakes topic."
                #if DEBUG
                print("[QuickMistake] save failed: could not resolve mistakes topic")
                #endif
                return nil
            }
            targetTopic = mistakes
        }

        #if DEBUG
        print("[QuickMistake] saving to users/\(ownerUID)/grammarNoteTopics/\(targetTopic.id)/notes")
        #endif

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
                #if DEBUG
                print("[QuickMistake] duplicate detected id=\(duplicate.id)")
                #endif
                return duplicate
            case .created(let saved):
                incrementNotesCount(for: targetTopic.id)
                #if DEBUG
                print("[QuickMistake] saved id=\(saved.id)")
                #endif
                return saved
            }
        } catch {
            quickMistakeError = readableMessage(for: error)
            #if DEBUG
            print("[QuickMistake] save failed:", error)
            #endif
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
