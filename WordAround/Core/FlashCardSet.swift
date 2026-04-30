import Foundation

struct FlashcardSet: Identifiable, Codable {
    var id: String
    var ownerUID: String
    var ownerEmail: String

    var title: String
    var description: String
    var privacy: String

    var folderID: String?
    var folderName: String?

    var colorHex: String
    var icon: SetIconType

    var cards: [Flashcard]

    var createdAt: Date
    var updatedAt: Date
}

