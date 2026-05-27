import Foundation

/// Local, static topic template. Used by `GrammarTemplateLibraryView` and
/// `GrammarNotesHomeViewModel.createTopicFromTemplate(...)` to spawn a topic
/// with a curated set of starter notes.
///
/// NOT stored in Firestore — only the produced `GrammarNoteTopic` and the
/// included `GrammarNote`s are persisted.
struct GrammarTopicTemplate: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let description: String
    let languageCode: String?
    let languageName: String?
    let icon: String
    let colorHex: String
    let difficulty: String
    let estimatedMinutes: Int
    let noteTemplates: [GrammarNoteTemplate]
    let tags: [String]

    init(
        id: String,
        title: String,
        description: String,
        languageCode: String? = nil,
        languageName: String? = nil,
        icon: String = "book.closed.fill",
        colorHex: String = "#4F7CFF",
        difficulty: String = "A1",
        estimatedMinutes: Int = 30,
        noteTemplates: [GrammarNoteTemplate] = [],
        tags: [String] = []
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.languageCode = languageCode
        self.languageName = languageName
        self.icon = icon
        self.colorHex = colorHex
        self.difficulty = difficulty
        self.estimatedMinutes = estimatedMinutes
        self.noteTemplates = noteTemplates
        self.tags = tags
    }

    var noteCount: Int { noteTemplates.count }

    /// Returns a copy with quiz blocks stripped from all included note
    /// templates — used when `allowQuickQuizzes == false`.
    func withoutQuizBlocks() -> GrammarTopicTemplate {
        GrammarTopicTemplate(
            id: id,
            title: title,
            description: description,
            languageCode: languageCode,
            languageName: languageName,
            icon: icon,
            colorHex: colorHex,
            difficulty: difficulty,
            estimatedMinutes: estimatedMinutes,
            noteTemplates: noteTemplates.map { $0.withoutQuizBlocks() },
            tags: tags
        )
    }
}
