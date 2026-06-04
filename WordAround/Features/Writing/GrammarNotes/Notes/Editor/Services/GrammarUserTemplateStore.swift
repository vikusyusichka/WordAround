import Foundation
import Combine
import SwiftUI

@MainActor
final class GrammarUserTemplateStore: ObservableObject {
    static let shared = GrammarUserTemplateStore()

    @Published private(set) var noteTemplates: [GrammarNoteTemplate] = []
    @Published private(set) var topicTemplates: [GrammarTopicTemplate] = []

    private let noteKey = "grammarNotes.userNoteTemplates.v1"
    private let topicKey = "grammarNotes.userTopicTemplates.v1"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    var hasNoteTemplates: Bool { !noteTemplates.isEmpty }
    var hasTopicTemplates: Bool { !topicTemplates.isEmpty }

    func isUserNoteTemplate(id: String) -> Bool { noteTemplates.contains { $0.id == id } }
    func isUserTopicTemplate(id: String) -> Bool { topicTemplates.contains { $0.id == id } }

    // MARK: - Note templates

    @discardableResult
    func saveNoteTemplate(_ template: GrammarNoteTemplate) -> GrammarNoteTemplate {
        if let index = noteTemplates.firstIndex(where: { $0.id == template.id }) {
            noteTemplates[index] = template
        } else {
            noteTemplates.insert(template, at: 0)
        }
        persistNotes()
        return template
    }

    func deleteNoteTemplate(id: String) {
        noteTemplates.removeAll { $0.id == id }
        persistNotes()
    }

    // MARK: - Topic templates

    @discardableResult
    func saveTopicTemplate(_ template: GrammarTopicTemplate) -> GrammarTopicTemplate {
        if let index = topicTemplates.firstIndex(where: { $0.id == template.id }) {
            topicTemplates[index] = template
        } else {
            topicTemplates.insert(template, at: 0)
        }
        persistTopics()
        return template
    }

    func deleteTopicTemplate(id: String) {
        topicTemplates.removeAll { $0.id == id }
        persistTopics()
    }

    // MARK: - Persistence

    private func load() {
        if let data = defaults.data(forKey: noteKey),
           let decoded = try? JSONDecoder().decode([GrammarNoteTemplate].self, from: data) {
            noteTemplates = decoded
        }
        if let data = defaults.data(forKey: topicKey),
           let decoded = try? JSONDecoder().decode([GrammarTopicTemplate].self, from: data) {
            topicTemplates = decoded
        }
    }

    private func persistNotes() {
        guard let data = try? JSONEncoder().encode(noteTemplates) else { return }
        defaults.set(data, forKey: noteKey)
    }

    private func persistTopics() {
        guard let data = try? JSONEncoder().encode(topicTemplates) else { return }
        defaults.set(data, forKey: topicKey)
    }
}

// MARK: - Builders

extension GrammarNoteTemplate {
    static func userTemplate(
        from note: GrammarNote,
        blocks: [GrammarNoteBlock]
    ) -> GrammarNoteTemplate {
        let ordered = blocks
            .sorted { $0.order < $1.order }
            .enumerated()
            .map { index, block in
                GrammarNoteBlock(
                    type: block.type,
                    text: block.text,
                    secondaryText: block.secondaryText,
                    imageURL: nil,
                    imageCaption: block.imageCaption,
                    items: block.items,
                    order: index
                )
            }

        let trimmedTitle = note.title.trimmingCharacters(in: .whitespacesAndNewlines)

        return GrammarNoteTemplate(
            id: "user-note-" + UUID().uuidString,
            title: trimmedTitle.isEmpty ? "Custom note template" : trimmedTitle,
            description: deriveDescription(from: ordered, fallback: note.previewText),
            noteType: note.noteType,
            languageCode: note.languageCode.isEmpty ? nil : note.languageCode,
            tags: note.tags,
            blocks: ordered,
            estimatedMinutes: max(1, ordered.count * 2),
            difficulty: "A1"
        )
    }

    private static func deriveDescription(
        from blocks: [GrammarNoteBlock],
        fallback: String
    ) -> String {
        let candidate = blocks
            .flatMap { [$0.text, $0.secondaryText ?? ""] + $0.items }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty }
            ?? fallback.trimmingCharacters(in: .whitespacesAndNewlines)
        let base = candidate.isEmpty ? "Saved from your note." : candidate
        return String(base.prefix(120))
    }
}

extension GrammarTopicTemplate {
    static func userTemplate(
        from topic: GrammarNoteTopic,
        notes: [GrammarNote]
    ) -> GrammarTopicTemplate {
        let noteTemplates = notes.map {
            GrammarNoteTemplate.userTemplate(from: $0, blocks: $0.contentBlocks)
        }

        let trimmedTitle = topic.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = topic.description.trimmingCharacters(in: .whitespacesAndNewlines)

        return GrammarTopicTemplate(
            id: "user-topic-" + UUID().uuidString,
            title: trimmedTitle.isEmpty ? "Custom topic template" : trimmedTitle,
            description: trimmedDescription.isEmpty ? "Saved from your topic." : trimmedDescription,
            languageCode: topic.languageCode.isEmpty ? nil : topic.languageCode,
            languageName: topic.languageName.isEmpty ? nil : topic.languageName,
            icon: topic.icon,
            colorHex: topic.colorHex,
            difficulty: "A1",
            estimatedMinutes: max(1, notes.count * 8),
            noteTemplates: noteTemplates,
            tags: []
        )
    }
}
