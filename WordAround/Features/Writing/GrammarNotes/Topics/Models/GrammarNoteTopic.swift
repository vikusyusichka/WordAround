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
    /// User-defined ordering for edit mode. `nil` for legacy documents that
    /// were never reordered; sorting falls back to `updatedAt` in that case.
    var sortIndex: Int? = nil

    static func commonMistakes(ownerUID: String) -> GrammarNoteTopic {
        let now = Date()

        return GrammarNoteTopic(
            id: "common_mistakes",
            ownerUID: ownerUID,
            title: "Common Mistakes",
            description: "Saved grammar corrections from essays and writing practice.",
            languageCode: "all",
            languageName: "All languages",
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
