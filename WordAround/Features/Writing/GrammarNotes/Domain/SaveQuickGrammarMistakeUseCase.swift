import Foundation

/// Assembles a mistake `GrammarNote` from a `QuickGrammarMistakeDraft` + target
/// topic + user settings, checks for an existing duplicate via `savedIssueKey`,
/// and saves a new note when there isn't one.
///
/// Single responsibility: take a draft + target topic → produce either a
/// freshly created note or surface a pre-existing duplicate.
///
/// Callers (ViewModels) keep:
/// - resolving which topic should receive the mistake (Home looks up in
///   `topics`, Topic uses its own `topic`)
/// - updating local UI state after the save
/// - error message localization
@MainActor
struct SaveQuickGrammarMistakeUseCase {
    enum Outcome: Equatable {
        case created(GrammarNote)
        case duplicate(GrammarNote)
    }

    private let noteService: GrammarNoteServicing

    init(noteService: GrammarNoteServicing? = nil) {
        self.noteService = noteService ?? GrammarNoteService()
    }

    func execute(
        ownerUID: String,
        targetTopic: GrammarNoteTopic,
        draft: QuickGrammarMistakeDraft,
        settings: GrammarNotesSettingsStore
    ) async throws -> Outcome {
        let now = Date()
        let original    = draft.originalSentence.trimmingCharacters(in: .whitespacesAndNewlines)
        let corrected   = draft.correctedSentence.trimmingCharacters(in: .whitespacesAndNewlines)
        let explanation = draft.explanation.trimmingCharacters(in: .whitespacesAndNewlines)

        let blocks = Self.makeMistakeBlocks(
            original: original,
            corrected: corrected,
            explanation: explanation,
            settings: settings,
            date: now
        )

        let rawTitle = !original.isEmpty ? original : corrected
        let title    = String(rawTitle.prefix(50))

        let previewText: String
        if settings.includeCorrectedSentence && !corrected.isEmpty {
            previewText = String(corrected.prefix(180))
        } else if !explanation.isEmpty {
            previewText = String(explanation.prefix(180))
        } else {
            previewText = String(original.prefix(180))
        }

        let savedIssueKey = Self.makeSavedIssueKey(
            original: original,
            corrected: corrected,
            explanation: explanation,
            languageCode: draft.language.rawValue
        )

        if let duplicate = try await noteService.fetchNoteBySavedIssueKey(
            ownerUID: ownerUID,
            topicId: targetTopic.id,
            savedIssueKey: savedIssueKey
        ) {
            return .duplicate(duplicate)
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

        let saved = try await noteService.createAndReturnNote(note)
        return .created(saved)
    }

    // MARK: - Helpers (consolidated from both ViewModels)

    private static let whitespaceRegex = try! NSRegularExpression(pattern: "\\s+")

    private static func makeMistakeBlocks(
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
}
