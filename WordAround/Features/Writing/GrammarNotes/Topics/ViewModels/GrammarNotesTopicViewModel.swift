import Foundation
import FirebaseFirestore
import Combine

@MainActor
final class GrammarNotesTopicViewModel: ObservableObject {
    enum Filter: String, CaseIterable, Identifiable {
        case all = "All"
        case pinned = "Pinned"
        case favorites = "Favorites"
        case mistakes = "Mistakes"
        case quizzes = "Quizzes"

        var id: String { rawValue }
    }

    @Published private(set) var topic: GrammarNoteTopic
    @Published private(set) var notes: [GrammarNote] = []
    @Published private(set) var filteredNotes: [GrammarNote] = []
    @Published private(set) var pinnedNotes: [GrammarNote] = []
    @Published private(set) var regularNotes: [GrammarNote] = []
    @Published private(set) var topicOption: GrammarQuickTopicOption
    @Published private(set) var isLoading = false
    @Published private(set) var isCreatingNote = false
    @Published private(set) var isCreatingQuickNote = false
    @Published private(set) var isCreatingQuickMistake = false
    @Published private(set) var didLoadNotes = false
    @Published var searchText = ""
    @Published var selectedFilter: Filter = .all
    @Published var errorMessage: String?
    @Published private(set) var quickNoteError: String?
    @Published private(set) var quickMistakeError: String?

    private let ownerUID: String
    private let noteService: GrammarNoteServicing
    private let topicService: GrammarNoteTopicServicing
    private var cancellables = Set<AnyCancellable>()
    private var isRefreshingFromCache = false

    private static let whitespaceRegex = try! NSRegularExpression(pattern: "\\s+")

    var hasNoNotes: Bool            { notes.isEmpty && !isLoading && errorMessage == nil }
    var hasNoMatchingNotes: Bool    { !notes.isEmpty && filteredNotes.isEmpty && !isLoading && errorMessage == nil }

    // MARK: - Init

    init(
        topic: GrammarNoteTopic,
        ownerUID: String,
        noteService: GrammarNoteServicing? = nil,
        topicService: GrammarNoteTopicServicing? = nil,
        previewNotes: [GrammarNote] = []
    ) {
        self.topic = topic
        self.ownerUID = ownerUID
        self.noteService = noteService ?? GrammarNoteService()
        self.topicService = topicService ?? GrammarNoteTopicService()
        self.topicOption = Self.makeTopicOption(from: topic)
        self.notes = Self.sortNotes(previewNotes)
        self.didLoadNotes = !previewNotes.isEmpty
        bindFiltering()
        refreshFiltered()
    }

    // MARK: - Bindings

    private func bindFiltering() {
        $searchText
            .combineLatest($selectedFilter)
            .sink { [weak self] _, _ in
                self?.refreshFiltered()
            }
            .store(in: &cancellables)
    }

    // MARK: - Notes loading

    func loadNotesIfNeeded() async {
        guard !didLoadNotes else { return }
        await loadNotes()
    }

    func loadNotes() async {
        guard !isLoading else { return }
        guard !didLoadNotes else { return }
        guard !ownerUID.isEmpty else {
            errorMessage = "User session is not available. Please sign in again."
            return
        }

        // Phase 1: show cached previews immediately — no spinner needed
        if notes.isEmpty {
            if let cached = try? await noteService.fetchNotePreviews(
                ownerUID: ownerUID, topicId: topic.id, source: .cache
            ), !cached.isEmpty {
                updateNotes(Self.sortNotes(cached))
            }
        }

        // Phase 2: server refresh; show spinner only when cache was empty
        let needsSpinner = notes.isEmpty
        if needsSpinner { isLoading = true }
        defer { isLoading = false }
        errorMessage = nil

        do {
            let loadedNotes = try await noteService.fetchNotePreviews(
                ownerUID: ownerUID,
                topicId: topic.id
            )
            updateNotes(Self.sortNotes(loadedNotes))
            didLoadNotes = true
        } catch {
            if notes.isEmpty {
                errorMessage = readableMessage(for: error)
            }
        }
    }

    /// Silent cache refresh — called on re-appear to pick up edits made in the editor.
    func refreshFromCacheIfNeeded() async {
        guard !isRefreshingFromCache else { return }
        await refreshFromCache()
    }

    func refreshFromCache() async {
        guard !isRefreshingFromCache else { return }
        isRefreshingFromCache = true
        defer { isRefreshingFromCache = false }

        guard let cached = try? await noteService.fetchNotePreviews(
            ownerUID: ownerUID, topicId: topic.id, source: .cache
        ), !cached.isEmpty else { return }

        updateNotes(Self.sortNotes(cached))
    }

    func retryLoading() async {
        didLoadNotes = false
        await loadNotes()
    }

    // MARK: - Full note creation (from CreateGrammarNoteSheet)

    func createNote(
        title: String,
        previewText: String,
        noteType: GrammarNoteType,
        tags: [String],
        hasQuiz: Bool,
        template: GrammarNoteTemplate? = nil
    ) async -> Bool {
        guard !isCreatingNote else { return false }
        guard !ownerUID.isEmpty else {
            errorMessage = "User session is not available. Please sign in again."
            return false
        }

        let trimmedTitle   = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPreview = previewText.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedTags    = tags.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }

        guard !trimmedTitle.isEmpty else { errorMessage = "Note title is required."; return false }
        guard trimmedTitle.count <= 60 else { errorMessage = "Note title must be under 60 characters."; return false }
        guard trimmedPreview.count <= 180 else { errorMessage = "Preview must be under 180 characters."; return false }

        let now = Date()
        let templateBlocks: [GrammarNoteBlock] = makeBlocks(from: template, date: now)
        let generatedPlainText = makePlainText(from: templateBlocks)

        let generatedPreview: String
        if !trimmedPreview.isEmpty {
            generatedPreview = trimmedPreview
        } else if let desc = template?.description, !desc.isEmpty {
            generatedPreview = desc
        } else {
            generatedPreview = makePreviewText(from: templateBlocks)
        }

        let note = GrammarNote(
            id: UUID().uuidString,
            ownerUID: ownerUID,
            topicId: topic.id,
            title: trimmedTitle,
            previewText: generatedPreview,
            languageCode: topic.languageCode,
            languageName: topic.languageName,
            noteType: noteType,
            tags: cleanedTags,
            imageURLs: [],
            isPinned: false,
            isFavorite: false,
            isMistakeNote: noteType == .mistake || topic.isMistakesTopic,
            savedIssueKey: nil,
            hasQuiz: hasQuiz || templateBlocks.contains { $0.type == GrammarNoteBlockType.quiz },
            contentBlocks: templateBlocks,
            plainTextContent: generatedPlainText,
            coverImageURL: nil,
            localImagePaths: [],
            templateId: template?.id,
            createdAt: now,
            updatedAt: now,
            lastEditedAt: now
        )

        isCreatingNote = true
        errorMessage = nil
        defer { isCreatingNote = false }

        do {
            try await noteService.createNote(note)
            updateNotes(Self.sortNotes(notes + [note]))
            return true
        } catch {
            errorMessage = readableMessage(for: error)
            return false
        }
    }

    // MARK: - Quick Note creation

    func createQuickNote(draft: QuickGrammarNoteDraft) async -> GrammarNote? {
        guard !isCreatingQuickNote else { return nil }
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
            topicId: topic.id,
            title: trimmedTitle.isEmpty ? "Untitled quick note" : trimmedTitle,
            previewText: String(trimmedText.prefix(180)),
            languageCode: topic.languageCode,
            languageName: topic.languageName,
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
            updateNotes(Self.sortNotes(notes + [saved]))
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

        // Resolve target topic: respect groupMistakesByTopic setting
        let targetTopic: GrammarNoteTopic
        if settings.groupMistakesByTopic {
            targetTopic = topic
        } else {
            guard let mistakes = await getOrCreateMistakesTopic() else {
                quickMistakeError = "Could not find or create Common Mistakes topic."
                return nil
            }
            targetTopic = mistakes
        }

        let now = Date()
        let trimmedOriginal    = draft.originalSentence.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCorrected   = draft.correctedSentence.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedExplanation = draft.explanation.trimmingCharacters(in: .whitespacesAndNewlines)

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
            if targetTopic.id == topic.id {
                updateNotes(Self.sortNotes(notes + [saved]))
            }
            return saved
        } catch {
            quickMistakeError = readableMessage(for: error)
            return nil
        }
    }

    // MARK: - Note actions

    func deleteNote(_ note: GrammarNote) async {
        do {
            try await noteService.deleteNote(id: note.id, ownerUID: ownerUID, topicId: topic.id)
            updateNotes(notes.filter { $0.id != note.id })
            errorMessage = nil
        } catch {
            errorMessage = readableMessage(for: error)
        }
    }

    func togglePinned(_ note: GrammarNote) async {
        replace(note) { $0.isPinned.toggle(); $0.updatedAt = Date() }
        do {
            try await noteService.setNotePinned(
                id: note.id, ownerUID: ownerUID, topicId: topic.id, isPinned: !note.isPinned
            )
            errorMessage = nil
        } catch {
            replace(note) { $0.isPinned = note.isPinned; $0.updatedAt = note.updatedAt }
            errorMessage = readableMessage(for: error)
        }
    }

    func toggleFavorite(_ note: GrammarNote) async {
        replace(note) { $0.isFavorite.toggle(); $0.updatedAt = Date() }
        do {
            try await noteService.setNoteFavorite(
                id: note.id, ownerUID: ownerUID, topicId: topic.id, isFavorite: !note.isFavorite
            )
            errorMessage = nil
        } catch {
            replace(note) { $0.isFavorite = note.isFavorite; $0.updatedAt = note.updatedAt }
            errorMessage = readableMessage(for: error)
        }
    }

    // MARK: - Private helpers

    private func getOrCreateMistakesTopic() async -> GrammarNoteTopic? {
        if topic.isMistakesTopic { return topic }
        do {
            return try await topicService.ensureDefaultMistakesTopic(ownerUID: ownerUID)
        } catch {
            return nil
        }
    }

    private func buildMistakeBlocks(
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
        let joined = [languageCode, original, corrected, explanation]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .joined(separator: "|")

        let range = NSRange(joined.startIndex..., in: joined)
        return whitespaceRegex.stringByReplacingMatches(
            in: joined,
            range: range,
            withTemplate: " "
        )
    }

    private func refreshFiltered() {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let filtered = notes.filter { note in
            let matchesFilter: Bool
            switch selectedFilter {
            case .all:       matchesFilter = true
            case .pinned:    matchesFilter = note.isPinned
            case .favorites: matchesFilter = note.isFavorite
            case .mistakes:  matchesFilter = note.isMistakeNote
            case .quizzes:   matchesFilter = note.hasQuiz
            }
            guard matchesFilter else { return false }
            guard !query.isEmpty else { return true }
            return note.title.lowercased().contains(query)
                || note.previewText.lowercased().contains(query)
                || note.tags.contains { $0.lowercased().contains(query) }
                || note.noteType.title.lowercased().contains(query)
        }

        filteredNotes = filtered
        pinnedNotes = filtered.filter { $0.isPinned }
        regularNotes = filtered.filter { !$0.isPinned }
    }

    private func updateNotes(_ newNotes: [GrammarNote]) {
        guard newNotes != notes else {
            updateTopicNotesCountIfNeeded(newNotes.count)
            return
        }
        notes = newNotes
        updateTopicNotesCountIfNeeded(newNotes.count)
        refreshFiltered()
    }

    private func updateTopicNotesCountIfNeeded(_ count: Int) {
        guard topic.notesCount != count else { return }
        topic.notesCount = count
        refreshTopicOption()
    }

    private func refreshTopicOption() {
        let option = Self.makeTopicOption(from: topic)
        guard option != topicOption else { return }
        topicOption = option
    }

    private static func makeTopicOption(from topic: GrammarNoteTopic) -> GrammarQuickTopicOption {
        let tint = CreateSetTheme.theme(forHex: topic.colorHex).accent
        return GrammarQuickTopicOption(
            id: topic.id,
            title: topic.title,
            subtitle: "\(topic.notesCount) notes",
            tint: tint,
            systemImage: topic.icon
        )
    }

    private func replace(_ note: GrammarNote, mutate: (inout GrammarNote) -> Void) {
        guard let index = notes.firstIndex(where: { $0.id == note.id }) else { return }
        var updatedNote = notes[index]
        mutate(&updatedNote)
        var updatedNotes = notes
        updatedNotes[index] = updatedNote
        updateNotes(Self.sortNotes(updatedNotes))
    }

    private func makeBlocks(from template: GrammarNoteTemplate?, date: Date) -> [GrammarNoteBlock] {
        guard let template else { return [] }
        return template.blocks.enumerated().map { index, block in
            GrammarNoteBlock(
                id: UUID().uuidString,
                type: block.type,
                text: block.text,
                secondaryText: block.secondaryText,
                imageURL: block.imageURL,
                imageCaption: block.imageCaption,
                items: block.items,
                order: index,
                createdAt: date,
                updatedAt: date
            )
        }
    }

    private func makePlainText(from blocks: [GrammarNoteBlock]) -> String {
        blocks.flatMap { block -> [String] in
            var parts: [String] = []
            if !block.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { parts.append(block.text) }
            if let secondary = block.secondaryText,
               !secondary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { parts.append(secondary) }
            parts.append(contentsOf: block.items.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
            return parts
        }
        .joined(separator: "\n")
    }

    private func makePreviewText(from blocks: [GrammarNoteBlock]) -> String {
        let text = makePlainText(from: blocks).trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? "No preview yet" : String(text.prefix(180))
    }

    private static func sortNotes(_ notes: [GrammarNote]) -> [GrammarNote] {
        notes.sorted { lhs, rhs in
            if lhs.isPinned   != rhs.isPinned   { return lhs.isPinned   && !rhs.isPinned   }
            if lhs.isFavorite != rhs.isFavorite { return lhs.isFavorite && !rhs.isFavorite }
            return lhs.updatedAt > rhs.updatedAt
        }
    }

    private func readableMessage(for error: Error) -> String {
        let nsError = error as NSError
        if nsError.domain == FirestoreErrorDomain,
           nsError.code == FirestoreErrorCode.permissionDenied.rawValue {
            return "Missing Firestore permission for grammar notes. Allow users/{uid}/grammarNoteTopics/{topicId}/notes access."
        }
        return error.localizedDescription
    }
}
