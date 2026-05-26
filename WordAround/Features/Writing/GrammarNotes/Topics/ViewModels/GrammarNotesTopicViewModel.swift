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
    private let createNoteUseCase: CreateGrammarNoteUseCase
    private let createQuickNoteUseCase: CreateQuickGrammarNoteUseCase
    private let saveQuickMistakeUseCase: SaveQuickGrammarMistakeUseCase
    private var cancellables = Set<AnyCancellable>()
    private var isRefreshingFromCache = false

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
        let resolvedNoteService = noteService ?? GrammarNoteService()
        let resolvedTopicService = topicService ?? GrammarNoteTopicService()
        self.noteService = resolvedNoteService
        self.topicService = resolvedTopicService
        self.createNoteUseCase = CreateGrammarNoteUseCase(noteService: resolvedNoteService)
        self.createQuickNoteUseCase = CreateQuickGrammarNoteUseCase(noteService: resolvedNoteService)
        self.saveQuickMistakeUseCase = SaveQuickGrammarMistakeUseCase(noteService: resolvedNoteService)
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

        isCreatingNote = true
        errorMessage = nil
        defer { isCreatingNote = false }

        do {
            let saved = try await createNoteUseCase.execute(
                CreateGrammarNoteUseCase.Input(
                    ownerUID: ownerUID,
                    topic: topic,
                    title: trimmedTitle,
                    previewText: trimmedPreview,
                    noteType: noteType,
                    tags: cleanedTags,
                    hasQuiz: hasQuiz,
                    template: template
                )
            )
            updateNotes(Self.sortNotes(notes + [saved]))
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

        do {
            let saved = try await createQuickNoteUseCase.execute(
                ownerUID: ownerUID,
                topic: topic,
                draft: draft
            )
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
                if targetTopic.id == topic.id {
                    updateNotes(Self.sortNotes(notes + [saved]))
                }
                return saved
            }
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

    private static func sortNotes(_ notes: [GrammarNote]) -> [GrammarNote] {
        notes.sorted { lhs, rhs in
            if lhs.isPinned   != rhs.isPinned   { return lhs.isPinned   && !rhs.isPinned   }
            if lhs.isFavorite != rhs.isFavorite { return lhs.isFavorite && !rhs.isFavorite }
            return lhs.updatedAt > rhs.updatedAt
        }
    }

    private func readableMessage(for error: Error) -> String {
        GrammarNotesErrorMessages.readable(
            for: error,
            firestorePermission: "Missing Firestore permission for grammar notes. Allow users/{uid}/grammarNoteTopics/{topicId}/notes access."
        )
    }
}
