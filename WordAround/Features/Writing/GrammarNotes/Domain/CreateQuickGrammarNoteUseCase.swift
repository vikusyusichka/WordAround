import Foundation

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

        let finalTitle = trimmedTitle.isEmpty ? "Untitled quick note" : trimmedTitle
        let finalPreview = String(trimmedText.prefix(180))

        let note = GrammarNote(
            id: UUID().uuidString,
            ownerUID: ownerUID,
            topicId: topic.id,
            title: finalTitle,
            previewText: finalPreview,
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
            lastEditedAt: now,
            searchableText: GrammarNoteSearchIndexer.makeSearchableText(
                title: finalTitle,
                previewText: finalPreview,
                tags: [],
                noteType: draft.noteType,
                blocks: contentBlocks,
                plainTextContent: trimmedText
            )
        )

        return try await noteService.createAndReturnNote(note)
    }
}
