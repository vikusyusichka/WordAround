import Foundation

struct Folder: Identifiable, Codable, Equatable {
    var id: String
    var ownerUID: String

    var title: String
    var description: String
    var colorHex: String

    var createdAt: Date
    var updatedAt: Date
}
