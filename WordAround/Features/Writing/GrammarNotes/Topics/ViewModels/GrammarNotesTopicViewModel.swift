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
    @Published private(set) var isLoading = false
    @Published private(set) var isCreatingNote = false
    @Published var searchText = ""
    @Published var selectedFilter: Filter = .all
    @Published var errorMessage: String?

    private let ownerUID: String
    private let noteService: GrammarNoteServicing

    var filteredNotes: [GrammarNote] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        return notes.filter { note in
            let matchesFilter: Bool

            switch selectedFilter {
            case .all:
                matchesFilter = true
            case .pinned:
                matchesFilter = note.isPinned
            case .favorites:
                matchesFilter = note.isFavorite
            case .mistakes:
                matchesFilter = note.isMistakeNote
            case .quizzes:
                matchesFilter = note.hasQuiz
            }

            guard matchesFilter else { return false }
            guard !query.isEmpty else { return true }

            return note.title.lowercased().contains(query)
                || note.previewText.lowercased().contains(query)
                || note.tags.contains { $0.lowercased().contains(query) }
                || note.noteType.title.lowercased().contains(query)
        }
    }

    var pinnedNotes: [GrammarNote] {
        filteredNotes.filter { $0.isPinned }
    }

    var regularNotes: [GrammarNote] {
        filteredNotes.filter { !$0.isPinned }
    }

    var hasNoNotes: Bool {
        notes.isEmpty && !isLoading && errorMessage == nil
    }

    var hasNoMatchingNotes: Bool {
        !notes.isEmpty && filteredNotes.isEmpty && !isLoading && errorMessage == nil
    }

    init(
        topic: GrammarNoteTopic,
        ownerUID: String,
        noteService: GrammarNoteServicing = GrammarNoteService(),
        previewNotes: [GrammarNote] = []
    ) {
        self.topic = topic
        self.ownerUID = ownerUID
        self.noteService = noteService
        self.notes = Self.sortNotes(previewNotes)
    }

    func loadNotes() async {
        guard !ownerUID.isEmpty else {
            errorMessage = "User session is not available. Please sign in again."
            return
        }

        // Phase 1: show cached previews immediately — no spinner needed
        if notes.isEmpty {
            if let cached = try? await noteService.fetchNotePreviews(
                ownerUID: ownerUID, topicId: topic.id, source: .cache
            ), !cached.isEmpty {
                notes = Self.sortNotes(cached)
                topic.notesCount = notes.count
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
            notes = Self.sortNotes(loadedNotes)
            topic.notesCount = notes.count
        } catch {
            if notes.isEmpty {
                errorMessage = readableMessage(for: error)
            }
        }
    }

    /// Silent cache refresh — called on re-appear to pick up edits made in the editor.
    func refreshFromCache() async {
        guard let cached = try? await noteService.fetchNotePreviews(
            ownerUID: ownerUID, topicId: topic.id, source: .cache
        ), !cached.isEmpty else { return }
        notes = Self.sortNotes(cached)
        topic.notesCount = notes.count
    }

    func retryLoading() async {
        await loadNotes()
    }

    func createNote(
        title: String,
        previewText: String,
        noteType: GrammarNoteType,
        tags: [String],
        hasQuiz: Bool,
        template: GrammarNoteTemplate? = nil
    ) async -> Bool {
        guard !ownerUID.isEmpty else {
            errorMessage = "User session is not available. Please sign in again."
            return false
        }

        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPreview = previewText.trimmingCharacters(in: .whitespacesAndNewlines)

        let cleanedTags = tags
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !trimmedTitle.isEmpty else {
            errorMessage = "Note title is required."
            return false
        }

        guard trimmedTitle.count <= 60 else {
            errorMessage = "Note title must be under 60 characters."
            return false
        }

        guard trimmedPreview.count <= 180 else {
            errorMessage = "Preview must be under 180 characters."
            return false
        }

        let now = Date()

        let templateBlocks: [GrammarNoteBlock] = makeBlocks(
            from: template,
            date: now
        )

        let generatedPlainText = makePlainText(from: templateBlocks)

        let generatedPreview: String
        if !trimmedPreview.isEmpty {
            generatedPreview = trimmedPreview
        } else if let templateDescription = template?.description, !templateDescription.isEmpty {
            generatedPreview = templateDescription
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
            notes = Self.sortNotes(notes + [note])
            topic.notesCount = notes.count
            return true
        } catch {
            errorMessage = readableMessage(for: error)
            return false
        }
    }

    func deleteNote(_ note: GrammarNote) async {
        do {
            try await noteService.deleteNote(
                id: note.id,
                ownerUID: ownerUID,
                topicId: topic.id
            )

            notes.removeAll { $0.id == note.id }
            topic.notesCount = notes.count
            errorMessage = nil
        } catch {
            errorMessage = readableMessage(for: error)
        }
    }

    func togglePinned(_ note: GrammarNote) async {
        // Optimistic update — apply locally first for instant feedback
        replace(note) {
            $0.isPinned.toggle()
            $0.updatedAt = Date()
        }
        do {
            try await noteService.setNotePinned(
                id: note.id,
                ownerUID: ownerUID,
                topicId: topic.id,
                isPinned: !note.isPinned
            )
            errorMessage = nil
        } catch {
            // Revert on failure
            replace(note) {
                $0.isPinned  = note.isPinned
                $0.updatedAt = note.updatedAt
            }
            errorMessage = readableMessage(for: error)
        }
    }

    func toggleFavorite(_ note: GrammarNote) async {
        // Optimistic update — apply locally first for instant feedback
        replace(note) {
            $0.isFavorite.toggle()
            $0.updatedAt = Date()
        }
        do {
            try await noteService.setNoteFavorite(
                id: note.id,
                ownerUID: ownerUID,
                topicId: topic.id,
                isFavorite: !note.isFavorite
            )
            errorMessage = nil
        } catch {
            // Revert on failure
            replace(note) {
                $0.isFavorite = note.isFavorite
                $0.updatedAt  = note.updatedAt
            }
            errorMessage = readableMessage(for: error)
        }
    }

    private func replace(
        _ note: GrammarNote,
        mutate: (inout GrammarNote) -> Void
    ) {
        guard let index = notes.firstIndex(where: { $0.id == note.id }) else { return }

        var updatedNote = notes[index]
        mutate(&updatedNote)

        notes[index] = updatedNote
        notes = Self.sortNotes(notes)
    }

    private func makeBlocks(
        from template: GrammarNoteTemplate?,
        date: Date
    ) -> [GrammarNoteBlock] {
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
        blocks
            .flatMap { block -> [String] in
                var parts: [String] = []

                if !block.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    parts.append(block.text)
                }

                if let secondaryText = block.secondaryText,
                   !secondaryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    parts.append(secondaryText)
                }

                parts.append(contentsOf: block.items.filter {
                    !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                })

                return parts
            }
            .joined(separator: "\n")
    }

    private func makePreviewText(from blocks: [GrammarNoteBlock]) -> String {
        let text = makePlainText(from: blocks)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !text.isEmpty else {
            return "No preview yet"
        }

        return String(text.prefix(180))
    }

    private static func sortNotes(_ notes: [GrammarNote]) -> [GrammarNote] {
        notes.sorted { lhs, rhs in
            if lhs.isPinned != rhs.isPinned {
                return lhs.isPinned && !rhs.isPinned
            }

            if lhs.isFavorite != rhs.isFavorite {
                return lhs.isFavorite && !rhs.isFavorite
            }

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
