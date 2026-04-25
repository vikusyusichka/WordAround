import Foundation

struct Flashcard: Identifiable, Codable {
    var id: String
    var word: String
    var translation: String
    var example: String
    var imageURL: String?
}
