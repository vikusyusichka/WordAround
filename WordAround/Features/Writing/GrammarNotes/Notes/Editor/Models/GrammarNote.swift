import Foundation

struct GrammarNote: Identifiable, Codable, Equatable {
    let id: String
    let ownerUID: String
    let topicId: String
    var title: String
    var previewText: String
    var languageCode: String
    var languageName: String
    var noteType: GrammarNoteType
    var tags: [String]
    var imageURLs: [String]
    var isPinned: Bool
    var isFavorite: Bool
    var isMistakeNote: Bool
    var savedIssueKey: String?
    var hasQuiz: Bool
    var contentBlocks: [GrammarNoteBlock]
    var plainTextContent: String
    var coverImageURL: String?
    var localImagePaths: [String]
    var templateId: String?
    var createdAt: Date
    var updatedAt: Date
    var lastEditedAt: Date
}

extension GrammarNote: Hashable {
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

extension GrammarNote {
    static func preview(
        id: String = UUID().uuidString,
        topicId: String = "preview-topic",
        title: String = "Ser vs Estar",
        previewText: String = "Use ser for identity and permanent traits. Use estar for state, location and temporary conditions.",
        noteType: GrammarNoteType = .rule,
        isPinned: Bool = false,
        isFavorite: Bool = false,
        hasQuiz: Bool = false
    ) -> GrammarNote {
        let now = Date()
        return GrammarNote(
            id: id,
            ownerUID: "preview-user",
            topicId: topicId,
            title: title,
            previewText: previewText,
            languageCode: "es",
            languageName: "Spanish",
            noteType: noteType,
            tags: ["A1", "verbs"],
            imageURLs: [],
            isPinned: isPinned,
            isFavorite: isFavorite,
            isMistakeNote: noteType == .mistake,
            savedIssueKey: nil,
            hasQuiz: hasQuiz,
            contentBlocks: [
                GrammarNoteBlock(type: .heading, text: title, order: 0),
                GrammarNoteBlock(type: .rule, text: "Use ser for identity and estar for temporary state or location.", secondaryText: "Ser + noun/adjective. Estar + place/state.", order: 1),
                GrammarNoteBlock(type: .example, text: "Soy estudiante.", secondaryText: "Estoy en casa.", order: 2)
            ],
            plainTextContent: previewText,
            coverImageURL: nil,
            localImagePaths: [],
            templateId: nil,
            createdAt: now.addingTimeInterval(-3600),
            updatedAt: now,
            lastEditedAt: now
        )
    }
}
