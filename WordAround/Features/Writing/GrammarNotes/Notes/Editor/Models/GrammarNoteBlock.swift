import Foundation

struct GrammarNoteBlock: Identifiable, Codable, Equatable {
    var id: String
    var type: GrammarNoteBlockType
    var text: String
    var secondaryText: String?
    var imageURL: String?
    var imageCaption: String?
    var items: [String]
    var order: Int
    var createdAt: Date
    var updatedAt: Date

    init(
        id: String = UUID().uuidString,
        type: GrammarNoteBlockType,
        text: String = "",
        secondaryText: String? = nil,
        imageURL: String? = nil,
        imageCaption: String? = nil,
        items: [String] = [],
        order: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.text = text
        self.secondaryText = secondaryText
        self.imageURL = imageURL
        self.imageCaption = imageCaption
        self.items = items
        self.order = order
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

extension GrammarNoteBlock {
    func touching() -> GrammarNoteBlock {
        var copy = self
        copy.updatedAt = Date()
        return copy
    }
}
