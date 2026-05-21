import Foundation

struct GrammarMistakeSavePayload: Equatable {
    var originalSentence: String
    var correctedSentence: String
    var explanation: String
    var languageCode: String
    var languageName: String
    var sourceIssueId: String?
    var ruleId: String?

    init(
        originalSentence: String,
        correctedSentence: String,
        explanation: String,
        languageCode: String,
        languageName: String,
        sourceIssueId: String? = nil,
        ruleId: String? = nil
    ) {
        self.originalSentence = originalSentence
        self.correctedSentence = correctedSentence
        self.explanation = explanation
        self.languageCode = languageCode
        self.languageName = languageName
        self.sourceIssueId = sourceIssueId
        self.ruleId = ruleId
    }
}

enum GrammarMistakeSaveResult: Equatable {
    case saved(GrammarNote)
    case duplicate(GrammarNote)
}

final class GrammarMistakeSaveService {
    private let noteService: GrammarNoteServicing
    private let topicService: GrammarNoteTopicServicing

    init(
        noteService: GrammarNoteServicing = GrammarNoteService(),
        topicService: GrammarNoteTopicServicing = GrammarNoteTopicService()
    ) {
        self.noteService = noteService
        self.topicService = topicService
    }

    @MainActor
    func saveMistake(
        payload: GrammarMistakeSavePayload,
        ownerUID: String,
        preferredTopic: GrammarNoteTopic?,
        settings: GrammarNotesSettingsStore
    ) async throws -> GrammarMistakeSaveResult {
        let targetTopic: GrammarNoteTopic
        if settings.groupMistakesByTopic, let preferredTopic {
            targetTopic = preferredTopic
        } else {
            targetTopic = try await topicService.ensureDefaultMistakesTopic(ownerUID: ownerUID)
        }

        let savedIssueKey = Self.makeSavedIssueKey(
            original: payload.originalSentence,
            corrected: payload.correctedSentence,
            explanation: payload.explanation,
            languageCode: payload.languageCode,
            sourceIssueId: payload.sourceIssueId,
            ruleId: payload.ruleId
        )

        if let existing = try await noteService.fetchNoteBySavedIssueKey(
            ownerUID: ownerUID,
            topicId: targetTopic.id,
            savedIssueKey: savedIssueKey
        ) {
            return .duplicate(existing)
        }

        let now = Date()
        let original = payload.originalSentence.trimmingCharacters(in: .whitespacesAndNewlines)
        let corrected = payload.correctedSentence.trimmingCharacters(in: .whitespacesAndNewlines)
        let explanation = payload.explanation.trimmingCharacters(in: .whitespacesAndNewlines)
        let blocks = Self.makeBlocks(
            original: original,
            corrected: corrected,
            explanation: explanation,
            settings: settings,
            date: now
        )

        let titleSource = original.isEmpty ? corrected : original
        let previewSource: String
        if settings.includeCorrectedSentence, !corrected.isEmpty {
            previewSource = corrected
        } else if !explanation.isEmpty {
            previewSource = explanation
        } else {
            previewSource = original
        }

        let note = GrammarNote(
            id: UUID().uuidString,
            ownerUID: ownerUID,
            topicId: targetTopic.id,
            title: String(titleSource.prefix(50)),
            previewText: String(previewSource.prefix(180)),
            languageCode: payload.languageCode,
            languageName: payload.languageName,
            noteType: .mistake,
            tags: Self.makeTags(payload: payload),
            imageURLs: [],
            isPinned: false,
            isFavorite: false,
            isMistakeNote: true,
            savedIssueKey: savedIssueKey,
            hasQuiz: false,
            contentBlocks: blocks,
            plainTextContent: Self.makePlainText(from: blocks),
            coverImageURL: nil,
            localImagePaths: [],
            templateId: nil,
            createdAt: now,
            updatedAt: now,
            lastEditedAt: now
        )

        let saved = try await noteService.createAndReturnNote(note)
        return .saved(saved)
    }

    static func makeSavedIssueKey(
        original: String,
        corrected: String,
        explanation: String,
        languageCode: String,
        sourceIssueId: String? = nil,
        ruleId: String? = nil
    ) -> String {
        let stableParts = [
            languageCode,
            sourceIssueId ?? "",
            ruleId ?? "",
            original,
            corrected,
            explanation
        ]

        return stableParts
            .map { normalize($0) }
            .joined(separator: "|")
    }

    private static func normalize(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }

    @MainActor
    private static func makeBlocks(
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

        if settings.includeOriginalSentence, !original.isEmpty {
            blocks.append(GrammarNoteBlock(type: .quote, text: original, order: order, createdAt: date, updatedAt: date))
            order += 1
        }

        if settings.includeCorrectedSentence, !corrected.isEmpty {
            blocks.append(GrammarNoteBlock(type: .example, text: corrected, order: order, createdAt: date, updatedAt: date))
            order += 1
        }

        if settings.createMistakeNotesWithExplanation, !explanation.isEmpty {
            blocks.append(GrammarNoteBlock(type: .paragraph, text: explanation, order: order, createdAt: date, updatedAt: date))
        }

        return blocks
    }

    private static func makePlainText(from blocks: [GrammarNoteBlock]) -> String {
        blocks.flatMap { block -> [String] in
            var parts: [String] = []
            if !block.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { parts.append(block.text) }
            if let secondary = block.secondaryText,
               !secondary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                parts.append(secondary)
            }
            parts.append(contentsOf: block.items.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
            return parts
        }
        .joined(separator: "\n")
    }

    private static func makeTags(payload: GrammarMistakeSavePayload) -> [String] {
        var tags = ["mistake", payload.languageName]
        if let ruleId = payload.ruleId, !ruleId.isEmpty { tags.append(ruleId) }
        if let sourceIssueId = payload.sourceIssueId, !sourceIssueId.isEmpty { tags.append(sourceIssueId) }
        return tags
    }
}
