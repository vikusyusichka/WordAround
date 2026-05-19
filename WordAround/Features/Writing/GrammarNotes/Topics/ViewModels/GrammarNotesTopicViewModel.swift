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
                || note.tags.contains(where: { $0.lowercased().contains(query) })
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

        isLoading = true
        errorMessage = nil

        do {
            notes = Self.sortNotes(try await noteService.fetchNotes(ownerUID: ownerUID, topicId: topic.id))
            topic.notesCount = notes.count
        } catch {
            errorMessage = readableMessage(for: error)
        }

        isLoading = false
    }

    func retryLoading() async {
        await loadNotes()
    }

    func createNote(
        title: String,
        previewText: String,
        noteType: GrammarNoteType,
        tags: [String],
        hasQuiz: Bool
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
        let note = GrammarNote(
            id: UUID().uuidString,
            ownerUID: ownerUID,
            topicId: topic.id,
            title: trimmedTitle,
            previewText: trimmedPreview,
            languageCode: topic.languageCode,
            languageName: topic.languageName,
            noteType: noteType,
            tags: cleanedTags,
            imageURLs: [],
            isPinned: false,
            isFavorite: false,
            isMistakeNote: noteType == .mistake || topic.isMistakesTopic,
            hasQuiz: hasQuiz,
            createdAt: now,
            updatedAt: now
        )

        isCreatingNote = true
        errorMessage = nil

        do {
            try await noteService.createNote(note)
            notes = Self.sortNotes(notes + [note])
            topic.notesCount = notes.count
            isCreatingNote = false
            return true
        } catch {
            isCreatingNote = false
            errorMessage = readableMessage(for: error)
            return false
        }
    }

    func deleteNote(_ note: GrammarNote) async {
        do {
            try await noteService.deleteNote(id: note.id, ownerUID: ownerUID, topicId: topic.id)
            notes.removeAll { $0.id == note.id }
            topic.notesCount = notes.count
            errorMessage = nil
        } catch {
            errorMessage = readableMessage(for: error)
        }
    }

    func togglePinned(_ note: GrammarNote) async {
        do {
            try await noteService.togglePinned(note: note)
            replace(note) { $0.isPinned.toggle(); $0.updatedAt = Date() }
            errorMessage = nil
        } catch {
            errorMessage = readableMessage(for: error)
        }
    }

    func toggleFavorite(_ note: GrammarNote) async {
        do {
            try await noteService.toggleFavorite(note: note)
            replace(note) { $0.isFavorite.toggle(); $0.updatedAt = Date() }
            errorMessage = nil
        } catch {
            errorMessage = readableMessage(for: error)
        }
    }

    private func replace(_ note: GrammarNote, mutate: (inout GrammarNote) -> Void) {
        guard let index = notes.firstIndex(where: { $0.id == note.id }) else { return }
        var updatedNote = notes[index]
        mutate(&updatedNote)
        notes[index] = updatedNote
        notes = Self.sortNotes(notes)
    }

    private static func sortNotes(_ notes: [GrammarNote]) -> [GrammarNote] {
        notes.sorted { lhs, rhs in
            if lhs.isPinned != rhs.isPinned { return lhs.isPinned && !rhs.isPinned }
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
