import Foundation
import FirebaseFirestore
import Combine
import SwiftUI

@MainActor
final class GrammarNotesTopicViewModel: ObservableObject {
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
    @Published var selectedFilter: GrammarNoteFilter = .all
    @Published var selectedNoteType: GrammarNoteType?
    @Published var selectedTag: String?
    @Published private(set) var availableTags: [String] = []
    @Published var errorMessage: String?
    @Published private(set) var quickNoteError: String?
    @Published private(set) var quickMistakeError: String?
    @Published private(set) var searchSnippets: [String: String] = [:]

    private let ownerUID: String
    private let noteService: GrammarNoteServicing
    private let topicService: GrammarNoteTopicServicing
    private let reviewService: GrammarReviewServicing
    private let createNoteUseCase: CreateGrammarNoteUseCase
    private let createQuickNoteUseCase: CreateQuickGrammarNoteUseCase
    private let saveQuickMistakeUseCase: SaveQuickGrammarMistakeUseCase
    private var cancellables = Set<AnyCancellable>()
    private var isRefreshingFromCache = false
    private var didAttemptSearchBackfill = false

    var hasNoNotes: Bool            { notes.isEmpty && !isLoading && errorMessage == nil }
    var hasNoMatchingNotes: Bool    { !notes.isEmpty && filteredNotes.isEmpty && !isLoading && errorMessage == nil }

    var isSearchActive: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var emptyStateTitle: String {
        if hasNoNotes { return GrammarNoteFilter.all.emptyStateTitle }
        if isSearchActive { return "No matching notes" }
        if selectedFilter != .all { return "No notes match this filter" }
        return selectedFilter.emptyStateTitle
    }

    var emptyStateSubtitle: String {
        if hasNoNotes { return GrammarNoteFilter.all.emptyStateSubtitle }
        if isSearchActive { return "Try another keyword." }
        return selectedFilter.emptyStateSubtitle
    }

    var showsEmptyStateAction: Bool { hasNoNotes && selectedFilter == .all }

    init(
        topic: GrammarNoteTopic,
        ownerUID: String,
        noteService: GrammarNoteServicing? = nil,
        topicService: GrammarNoteTopicServicing? = nil,
        reviewService: GrammarReviewServicing? = nil,
        previewNotes: [GrammarNote] = []
    ) {
        self.topic = topic
        self.ownerUID = ownerUID
        let resolvedNoteService = noteService ?? GrammarNoteService()
        let resolvedTopicService = topicService ?? GrammarNoteTopicService()
        self.noteService = resolvedNoteService
        self.topicService = resolvedTopicService
        self.reviewService = reviewService ?? GrammarReviewService()
        self.createNoteUseCase = CreateGrammarNoteUseCase(noteService: resolvedNoteService)
        self.createQuickNoteUseCase = CreateQuickGrammarNoteUseCase(noteService: resolvedNoteService)
        self.saveQuickMistakeUseCase = SaveQuickGrammarMistakeUseCase(noteService: resolvedNoteService)
        self.topicOption = Self.makeTopicOption(from: topic)
        self.notes = Self.sortNotes(previewNotes)
        self.didLoadNotes = !previewNotes.isEmpty
        bindFiltering()
        refreshFiltered()
    }

    private func bindFiltering() {
        Publishers.CombineLatest3($searchText, $selectedFilter, $notes)
            .sink { [weak self] _, _, _ in
                self?.refreshFiltered()
            }
            .store(in: &cancellables)

        Publishers.CombineLatest($selectedNoteType, $selectedTag)
            .sink { [weak self] _, _ in
                self?.refreshFiltered()
            }
            .store(in: &cancellables)

        $selectedFilter
            .sink { [weak self] newValue in
                guard let self else { return }
                if newValue != .types, self.selectedNoteType != nil {
                    self.selectedNoteType = nil
                }
                if newValue != .tags, self.selectedTag != nil {
                    self.selectedTag = nil
                }
            }
            .store(in: &cancellables)
    }

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

        if notes.isEmpty {
            if let cached = try? await noteService.fetchNotePreviews(
                ownerUID: ownerUID, topicId: topic.id, source: .cache
            ), !cached.isEmpty {
                updateNotes(Self.sortNotes(cached))
            }
        }

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
            backfillSearchableTextForLoadedNotesIfNeeded()
        } catch {
            if notes.isEmpty {
                errorMessage = readableMessage(for: error)
            }
        }
    }

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

    private func backfillSearchableTextForLoadedNotesIfNeeded() {
        guard !didAttemptSearchBackfill else { return }
        didAttemptSearchBackfill = true

        let candidates: [(id: String, indexed: String)] = notes.compactMap { note in
            guard note.searchableText.isEmpty else { return nil }
            let rebuilt = GrammarNoteSearchIndexer.makeSearchableText(for: note)
            guard !rebuilt.isEmpty else { return nil }
            return (note.id, rebuilt)
        }
        guard !candidates.isEmpty else { return }

        let owner = ownerUID
        let topicId = topic.id
        let service = noteService

        Task.detached(priority: .utility) {
            for candidate in candidates {
                do {
                    try await service.setSearchableText(
                        id: candidate.id,
                        ownerUID: owner,
                        topicId: topicId,
                        searchableText: candidate.indexed
                    )
                } catch {
                    #if DEBUG
                    print("[SearchBackfill] failed for \(candidate.id):", error)
                    #endif
                }
            }
        }

        let updates = Dictionary(uniqueKeysWithValues: candidates.map { ($0.id, $0.indexed) })
        let patched = notes.map { note -> GrammarNote in
            guard let indexed = updates[note.id] else { return note }
            var copy = note
            copy.searchableText = indexed
            return copy
        }
        if patched != notes {
            notes = patched
            refreshFiltered()
        }
    }

    func createNote(
        title: String,
        previewText: String,
        noteType: GrammarNoteType,
        tags: [String],
        hasQuiz: Bool,
        template: GrammarNoteTemplate? = nil
    ) async -> GrammarNote? {
        guard !isCreatingNote else { return nil }

        isCreatingNote = true
        errorMessage = nil
        defer { isCreatingNote = false }

        await Task.yield()

        guard !ownerUID.isEmpty else {
            errorMessage = "User session is not available. Please sign in again."
            #if DEBUG
            print("[CreateNote] failed: ownerUID is empty")
            #endif
            return nil
        }

        let trimmedTitle   = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPreview = previewText.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedTags    = tags.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }

        guard !trimmedTitle.isEmpty else { errorMessage = "Note title is required.";                    return nil }
        guard trimmedTitle.count <= 60 else { errorMessage = "Note title must be under 60 characters.";    return nil }
        guard trimmedPreview.count <= 180 else { errorMessage = "Preview must be under 180 characters.";   return nil }

        #if DEBUG
        print("[CreateNote] saving to users/\(ownerUID)/grammarNoteTopics/\(topic.id)/notes")
        #endif

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
            #if DEBUG
            print("[CreateNote] saved id=\(saved.id)")
            #endif
            return saved
        } catch {
            errorMessage = readableMessage(for: error)
            #if DEBUG
            print("[CreateNote] failed:", error)
            #endif
            return nil
        }
    }

    func createQuickNote(draft: QuickGrammarNoteDraft) async -> GrammarNote? {
        guard !isCreatingQuickNote else { return nil }

        isCreatingQuickNote = true
        quickNoteError = nil
        defer { isCreatingQuickNote = false }

        await Task.yield()

        guard !ownerUID.isEmpty else {
            quickNoteError = "User session is not available. Please sign in again."
            #if DEBUG
            print("[QuickNote/Topic] save failed: ownerUID is empty")
            #endif
            return nil
        }

        #if DEBUG
        print("[QuickNote/Topic] saving to users/\(ownerUID)/grammarNoteTopics/\(topic.id)/notes")
        #endif

        do {
            let saved = try await createQuickNoteUseCase.execute(
                ownerUID: ownerUID,
                topic: topic,
                draft: draft
            )
            updateNotes(Self.sortNotes(notes + [saved]))
            #if DEBUG
            print("[QuickNote/Topic] saved id=\(saved.id)")
            #endif
            return saved
        } catch {
            quickNoteError = readableMessage(for: error)
            #if DEBUG
            print("[QuickNote/Topic] save failed:", error)
            #endif
            return nil
        }
    }

    func createQuickMistake(
        draft: QuickGrammarMistakeDraft,
        settings: GrammarNotesSettingsStore
    ) async -> GrammarNote? {
        guard !isCreatingQuickMistake else { return nil }

        isCreatingQuickMistake = true
        quickMistakeError = nil
        defer { isCreatingQuickMistake = false }

        await Task.yield()

        guard !ownerUID.isEmpty else {
            quickMistakeError = "User session is not available. Please sign in again."
            #if DEBUG
            print("[QuickMistake/Topic] save failed: ownerUID is empty")
            #endif
            return nil
        }

        let targetTopic: GrammarNoteTopic = topic

        #if DEBUG
        print("[QuickMistake/Topic] saving to users/\(ownerUID)/grammarNoteTopics/\(targetTopic.id)/notes")
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
                print("[QuickMistake/Topic] duplicate id=\(duplicate.id)")
                #endif
                return duplicate
            case .created(let saved):
                if targetTopic.id == topic.id {
                    updateNotes(Self.sortNotes(notes + [saved]))
                }
                #if DEBUG
                print("[QuickMistake/Topic] saved id=\(saved.id)")
                #endif
                return saved
            }
        } catch {
            quickMistakeError = readableMessage(for: error)
            #if DEBUG
            print("[QuickMistake/Topic] save failed:", error)
            #endif
            return nil
        }
    }

    func deleteNote(_ note: GrammarNote) async {
        do {
            try await noteService.deleteNote(id: note.id, ownerUID: ownerUID, topicId: topic.id)
            updateNotes(notes.filter { $0.id != note.id })
            errorMessage = nil
            purgeReviewItems(for: note)
        } catch {
            errorMessage = readableMessage(for: error)
        }
    }

    private func purgeReviewItems(for note: GrammarNote) {
        let service = reviewService
        let owner = ownerUID
        let noteId = note.id
        let topicId = topic.id
        Task.detached(priority: .utility) {
            try? await service.deleteReviewItem(
                id: GrammarReviewItem.id(forNoteTopicId: topicId, noteId: noteId),
                ownerUID: owner
            )
            try? await service.deleteReviewItem(
                id: GrammarReviewItem.id(forMistakeTopicId: topicId, noteId: noteId),
                ownerUID: owner
            )
        }
    }

    func removeNoteLocally(_ note: GrammarNote) {
        updateNotes(notes.filter { $0.id != note.id })
    }

    func saveTopicAsTemplate() {
        let template = GrammarTopicTemplate.userTemplate(from: topic, notes: notes)
        GrammarUserTemplateStore.shared.saveTopicTemplate(template)
    }

    func moveNotes(from source: IndexSet, to destination: Int) {
        var reordered = notes
        reordered.move(fromOffsets: source, toOffset: destination)

        for (offset, _) in reordered.enumerated() {
            reordered[offset].sortIndex = offset
        }

        updateNotes(reordered)
        persistNoteOrder(reordered)
    }

    private func persistNoteOrder(_ orderedNotes: [GrammarNote]) {
        guard !ownerUID.isEmpty else { return }
        let indices = orderedNotes.enumerated().map { (id: $1.id, sortIndex: $0) }
        let service = noteService
        let owner = ownerUID
        let topicId = topic.id
        Task.detached(priority: .utility) {
            do {
                try await service.updateNoteSortIndices(
                    ownerUID: owner,
                    topicId: topicId,
                    indices: indices
                )
            } catch {
                #if DEBUG
                print("[ReorderNotes] persist failed:", error)
                #endif
            }
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

    private func refreshFiltered() {
        let rawQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let filtered = notes.filter { note in
            let matchesFilter: Bool
            switch selectedFilter {
            case .all:
                matchesFilter = true
            case .types:
                matchesFilter = selectedNoteType.map { note.noteType == $0 } ?? true
            case .favorites:
                matchesFilter = note.isFavorite
            case .tags:
                matchesFilter = selectedTag.map { note.tags.contains($0) } ?? true
            }
            guard matchesFilter else { return false }
            guard !rawQuery.isEmpty else { return true }

            return GrammarNoteSearchIndexer.matchesFallback(query: rawQuery, note: note)
        }

        filteredNotes = filtered
        pinnedNotes = filtered.filter { $0.isPinned }
        regularNotes = filtered.filter { !$0.isPinned }

        availableTags = Array(Set(notes.flatMap { $0.tags })).sorted(by: { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending })

        if rawQuery.isEmpty {
            searchSnippets = [:]
        } else {
            var next: [String: String] = [:]
            for note in filtered {
                if let snippet = GrammarNoteSearchIndexer.snippet(for: note, query: rawQuery) {
                    next[note.id] = snippet
                }
            }
            searchSnippets = next
        }
    }

    func searchSnippet(for note: GrammarNote) -> String? {
        searchSnippets[note.id]
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
            switch (lhs.sortIndex, rhs.sortIndex) {
            case let (l?, r?):
                if l != r { return l < r }
                return lhs.updatedAt > rhs.updatedAt
            case (nil, nil): return lhs.updatedAt > rhs.updatedAt
            case (_?, nil):  return false
            case (nil, _?):  return true
            }
        }
    }

    private func readableMessage(for error: Error) -> String {
        GrammarNotesErrorMessages.readable(
            for: error,
            firestorePermission: "Missing Firestore permission for grammar notes. Allow users/{uid}/grammarNoteTopics/{topicId}/notes access."
        )
    }
}
