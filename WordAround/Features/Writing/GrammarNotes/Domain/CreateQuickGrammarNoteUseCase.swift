import Foundation

/// Assembles a `GrammarNote` from a `QuickGrammarNoteDraft` + topic and saves
/// it through `GrammarNoteServicing`.
///
/// Single responsibility: take a draft + topic → produce a saved note.
///
/// Callers (ViewModels) keep:
/// - choosing which topic receives the note
/// - updating local UI state after the save
/// - error message localization
@MainActor
struct CreateQuickGrammarNoteUseCase {
    private let noteService: GrammarNoteServicing

    init(noteService: GrammarNoteServicing? = nil) {
        self.noteService = noteService ?? GrammarNoteService()
    }

    func execute(
        ownerUID: String,
        topic: GrammarNoteTopic,
        draft: QuickGrammarNoteDraft
    ) async throws -> GrammarNote {
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

        return try await noteService.createAndReturnNote(note)
    }
}
