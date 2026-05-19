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
    var hasQuiz: Bool
    var createdAt: Date
    var updatedAt: Date
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
        GrammarNote(
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
            hasQuiz: hasQuiz,
            createdAt: Date().addingTimeInterval(-3600),
            updatedAt: Date()
        )
    }
}
