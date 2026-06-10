import Foundation

struct GrammarNoteTopic: Identifiable, Codable, Equatable {
    let id: String
    let ownerUID: String
    var title: String
    var description: String
    var languageCode: String
    var languageName: String
    var icon: String
    var colorHex: String
    var notesCount: Int
    var isPinned: Bool
    var isMistakesTopic: Bool
    var createdAt: Date
    var updatedAt: Date
    var sortIndex: Int? = nil

    static func commonMistakes(ownerUID: String) -> GrammarNoteTopic {
        let now = Date()

        return GrammarNoteTopic(
            id: "common_mistakes",
            ownerUID: ownerUID,
            title: L10n.string("notesCommonMistakes"),
            description: "Saved grammar corrections from essays and writing practice.",
            languageCode: "all",
            languageName: L10n.string("notesAllLanguages"),
            icon: "exclamationmark.triangle.fill",
            colorHex: "#F4729A",
            notesCount: 0,
            isPinned: true,
            isMistakesTopic: true,
            createdAt: now,
            updatedAt: now
        )
    }
}
