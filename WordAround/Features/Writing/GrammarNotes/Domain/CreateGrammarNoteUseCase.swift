import Foundation

/// Assembles a `GrammarNote` from a fully-validated input (topic, title,
/// optional template, etc.) and saves it through `GrammarNoteServicing`.
///
/// Single responsibility: take a validated draft → produce a saved note.
///
/// Callers (ViewModels) keep:
/// - input validation (title/preview length, required fields)
/// - `@Published` UI state (`isCreatingNote`, `errorMessage`)
/// - updating the local notes list after the save
/// - error message localization
@MainActor
struct CreateGrammarNoteUseCase {
    struct Input {
        let ownerUID: String
        let topic: GrammarNoteTopic
        let title: String        // already trimmed by caller
        let previewText: String  // already trimmed by caller
        let noteType: GrammarNoteType
        let tags: [String]       // already cleaned by caller
        let hasQuiz: Bool
        let template: GrammarNoteTemplate?
    }

    private let noteService: GrammarNoteServicing

    init(noteService: GrammarNoteServicing? = nil) {
        self.noteService = noteService ?? GrammarNoteService()
    }

    func execute(_ input: Input) async throws -> GrammarNote {
        let now = Date()
        let templateBlocks = Self.makeBlocks(from: input.template, date: now)
        let generatedPlainText = Self.makePlainText(from: templateBlocks)

        let generatedPreview: String
        if !input.previewText.isEmpty {
            generatedPreview = input.previewText
        } else if let desc = input.template?.description, !desc.isEmpty {
            generatedPreview = desc
        } else {
            generatedPreview = Self.makePreviewText(from: templateBlocks)
        }

        let note = GrammarNote(
            id: UUID().uuidString,
            ownerUID: input.ownerUID,
            topicId: input.topic.id,
            title: input.title,
            previewText: generatedPreview,
            languageCode: input.topic.languageCode,
            languageName: input.topic.languageName,
            noteType: input.noteType,
            tags: input.tags,
            imageURLs: [],
            isPinned: false,
            isFavorite: false,
            isMistakeNote: input.noteType == .mistake || input.topic.isMistakesTopic,
            savedIssueKey: nil,
            hasQuiz: input.hasQuiz || templateBlocks.contains { $0.type == .quiz },
            contentBlocks: templateBlocks,
            plainTextContent: generatedPlainText,
            coverImageURL: nil,
            localImagePaths: [],
            templateId: input.template?.id,
            createdAt: now,
            updatedAt: now,
            lastEditedAt: now,
            searchableText: GrammarNoteSearchIndexer.makeSearchableText(
                title: input.title,
                previewText: generatedPreview,
                tags: input.tags,
                noteType: input.noteType,
                blocks: templateBlocks,
                plainTextContent: generatedPlainText
            )
        )

        try await noteService.createNote(note)
        return note
    }

    // MARK: - Helpers (moved verbatim from GrammarNotesTopicViewModel)

    /// Builds fresh blocks from a template, assigning new ids and contiguous order.
    private static func makeBlocks(from template: GrammarNoteTemplate?, date: Date) -> [GrammarNoteBlock] {
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

    /// Joins non-empty text/secondaryText/item lines with newlines. Matches the
    /// existing `GrammarNotesTopicViewModel` behavior exactly (notably it does
    /// NOT include `imageCaption`, to preserve saved-field semantics).
    private static func makePlainText(from blocks: [GrammarNoteBlock]) -> String {
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

    private static func makePreviewText(from blocks: [GrammarNoteBlock]) -> String {
        let text = makePlainText(from: blocks).trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? "No preview yet" : String(text.prefix(180))
    }
}
