import Foundation
import FirebaseFirestore
import Combine

@MainActor
final class GrammarNotesHomeViewModel: ObservableObject {
    @Published private(set) var topics: [GrammarNoteTopic] = []
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
    private var isEnsuringDefaultTopic = false

    // MARK: - Computed

    var filteredTopics: [GrammarNoteTopic] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return topics }
        return topics.filter { topic in
            topic.title.lowercased().contains(query)
            || topic.description.lowercased().contains(query)
            || topic.languageName.lowercased().contains(query)
        }
    }

    var hasOnlyMistakesTopic: Bool {
        topics.filter { !$0.isMistakesTopic }.isEmpty
    }

    /// All topics as picker-friendly options (for quick note / quick mistake sheets).
    var topicOptions: [GrammarQuickTopicOption] {
        topics.map { topicOption(for: $0) }
    }

    /// Only regular (non-mistakes) topics for quick note picker.
    var regularTopicOptions: [GrammarQuickTopicOption] {
        topics.filter { !$0.isMistakesTopic }.map { topicOption(for: $0) }
    }

    /// The Common Mistakes topic as a picker option, if it exists.
    var mistakesTopicOption: GrammarQuickTopicOption? {
        topics.first(where: { $0.isMistakesTopic }).map { topicOption(for: $0) }
    }

    // MARK: - Init

    init(
        ownerUID: String,
        service: GrammarNoteTopicServicing = GrammarNoteTopicService(),
        noteService: GrammarNoteServicing = GrammarNoteService(),
        previewTopics: [GrammarNoteTopic] = []
    ) {
        self.ownerUID = ownerUID
        self.service = service
        self.noteService = noteService
        self.topics = previewTopics
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
                topics = sortTopics(cached)
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
            topics = sortTopics(loadedTopics)
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
            topics = sortTopics(topics + [topic])
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
            topics.removeAll { $0.id == topic.id }
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

        let now = Date()
        let trimmedTitle = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedText  = draft.text.trimmingCharacters(in: .whitespacesAndNewlines)

        var contentBlocks: [GrammarNoteBlock] = []
        if !trimmedText.isEmpty {
            contentBlocks = [GrammarNoteBlock(
                type: .paragraph,
                text: trimmedText,
                order: 0,
                createdAt: now,
                updatedAt: now
            )]
        }

        let note = GrammarNote(
            id: UUID().uuidString,
            ownerUID: ownerUID,
            topicId: matchedTopic.id,
            title: trimmedTitle.isEmpty ? "Untitled quick note" : trimmedTitle,
            previewText: String(trimmedText.prefix(180)),
            languageCode: matchedTopic.languageCode,
            languageName: matchedTopic.languageName,
            noteType: draft.noteType,
            tags: [],
            imageURLs: [],
            isPinned: false,
            isFavorite: false,
            isMistakeNote: false,
            savedIssueKey: nil,
            hasQuiz: false,
            contentBlocks: contentBlocks,
            plainTextContent: trimmedText,
            coverImageURL: nil,
            localImagePaths: [],
            templateId: nil,
            createdAt: now,
            updatedAt: now,
            lastEditedAt: now
        )

        do {
            let saved = try await noteService.createAndReturnNote(note)
            if let idx = topics.firstIndex(where: { $0.id == matchedTopic.id }) {
                topics[idx].notesCount += 1
            }
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

        let now = Date()
        let trimmedOriginal     = draft.originalSentence.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCorrected    = draft.correctedSentence.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedExplanation  = draft.explanation.trimmingCharacters(in: .whitespacesAndNewlines)

        let blocks = buildMistakeBlocks(
            original: trimmedOriginal,
            corrected: trimmedCorrected,
            explanation: trimmedExplanation,
            settings: settings,
            date: now
        )

        let rawTitle = !trimmedOriginal.isEmpty ? trimmedOriginal : trimmedCorrected
        let title    = String(rawTitle.prefix(50))

        let previewText: String
        if settings.includeCorrectedSentence && !trimmedCorrected.isEmpty {
            previewText = String(trimmedCorrected.prefix(180))
        } else if !trimmedExplanation.isEmpty {
            previewText = String(trimmedExplanation.prefix(180))
        } else {
            previewText = String(trimmedOriginal.prefix(180))
        }

        let savedIssueKey = Self.makeSavedIssueKey(
            original: trimmedOriginal,
            corrected: trimmedCorrected,
            explanation: trimmedExplanation,
            languageCode: draft.language.rawValue
        )

        do {
            if let duplicate = try await noteService.fetchNoteBySavedIssueKey(
                ownerUID: ownerUID,
                topicId: targetTopic.id,
                savedIssueKey: savedIssueKey
            ) {
                quickMistakeError = nil
                return duplicate
            }
        } catch {
            quickMistakeError = readableMessage(for: error)
            return nil
        }

        let note = GrammarNote(
            id: UUID().uuidString,
            ownerUID: ownerUID,
            topicId: targetTopic.id,
            title: title,
            previewText: previewText,
            languageCode: draft.language.rawValue,
            languageName: draft.language.title,
            noteType: .mistake,
            tags: ["mistake", draft.language.title],
            imageURLs: [],
            isPinned: false,
            isFavorite: false,
            isMistakeNote: true,
            savedIssueKey: savedIssueKey,
            hasQuiz: false,
            contentBlocks: blocks,
            plainTextContent: GrammarNoteEditorViewModel.makePlainText(from: blocks),
            coverImageURL: nil,
            localImagePaths: [],
            templateId: nil,
            createdAt: now,
            updatedAt: now,
            lastEditedAt: now
        )

        do {
            let saved = try await noteService.createAndReturnNote(note)
            if let idx = topics.firstIndex(where: { $0.id == targetTopic.id }) {
                topics[idx].notesCount += 1
            }
            return saved
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
                topics = sortTopics(topics + [topic])
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

    private func topicOption(for topic: GrammarNoteTopic) -> GrammarQuickTopicOption {
        let tint = CreateSetTheme.theme(forHex: topic.colorHex).accent
        return GrammarQuickTopicOption(
            id: topic.id,
            title: topic.title,
            subtitle: "\(topic.notesCount) notes",
            tint: tint,
            systemImage: topic.icon
        )
    }

    private static func buildMistakeBlocks(
        original: String,
        corrected: String,
        explanation: String,
        settings: GrammarNotesSettingsStore,
        date: Date
    ) -> [GrammarNoteBlock] {
        var blocks: [GrammarNoteBlock] = []
        var order = 0

        blocks.append(GrammarNoteBlock(type: .heading, text: "Mistake", order: order, createdAt: date, updatedAt: date))
        order += 1

        if settings.includeOriginalSentence && !original.isEmpty {
            blocks.append(GrammarNoteBlock(type: .quote, text: original, order: order, createdAt: date, updatedAt: date))
            order += 1
        }
        if settings.includeCorrectedSentence && !corrected.isEmpty {
            blocks.append(GrammarNoteBlock(type: .example, text: corrected, order: order, createdAt: date, updatedAt: date))
            order += 1
        }
        if settings.createMistakeNotesWithExplanation && !explanation.isEmpty {
            blocks.append(GrammarNoteBlock(type: .paragraph, text: explanation, order: order, createdAt: date, updatedAt: date))
            order += 1
        }

        return blocks
    }

    private static func makeSavedIssueKey(
        original: String,
        corrected: String,
        explanation: String,
        languageCode: String
    ) -> String {
        [languageCode, original, corrected, explanation]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .joined(separator: "|")
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }

    // Non-static wrapper so it can call buildMistakeBlocks
    private func buildMistakeBlocks(
        original: String,
        corrected: String,
        explanation: String,
        settings: GrammarNotesSettingsStore,
        date: Date
    ) -> [GrammarNoteBlock] {
        Self.buildMistakeBlocks(
            original: original,
            corrected: corrected,
            explanation: explanation,
            settings: settings,
            date: date
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
        let nsError = error as NSError
        if nsError.domain == FirestoreErrorDomain,
           nsError.code == FirestoreErrorCode.permissionDenied.rawValue {
            return "Missing Firestore permission for grammar note topics. Update Firestore rules for users/{uid}/grammarNoteTopics."
        }
        return error.localizedDescription
    }
}
