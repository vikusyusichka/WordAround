import Foundation

struct GrammarNoteTemplate: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let description: String
    let noteType: GrammarNoteType
    let languageCode: String?
    let tags: [String]
    let blocks: [GrammarNoteBlock]
    let estimatedMinutes: Int
    let difficulty: String

    init(
        id: String,
        title: String,
        description: String,
        noteType: GrammarNoteType,
        languageCode: String? = nil,
        tags: [String] = [],
        blocks: [GrammarNoteBlock] = [],
        estimatedMinutes: Int = 8,
        difficulty: String = "A1"
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.noteType = noteType
        self.languageCode = languageCode
        self.tags = tags
        self.blocks = blocks
        self.estimatedMinutes = estimatedMinutes
        self.difficulty = difficulty
    }

    var hasQuizBlock: Bool {
        blocks.contains { $0.type == .quiz }
    }

    func withoutQuizBlocks() -> GrammarNoteTemplate {
        let filtered = blocks
            .filter { $0.type != .quiz }
            .enumerated()
            .map { index, block -> GrammarNoteBlock in
                var copy = block
                copy.order = index
                return copy
            }
        return GrammarNoteTemplate(
            id: id,
            title: title,
            description: description,
            noteType: noteType,
            languageCode: languageCode,
            tags: tags,
            blocks: filtered,
            estimatedMinutes: estimatedMinutes,
            difficulty: difficulty
        )
    }
}
