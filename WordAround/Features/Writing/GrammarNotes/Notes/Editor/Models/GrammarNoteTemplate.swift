import Foundation

struct GrammarNoteTemplate: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let description: String
    let noteType: GrammarNoteType
    let languageCode: String?
    let blocks: [GrammarNoteBlock]
}
