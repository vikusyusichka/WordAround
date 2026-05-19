import Foundation

struct EssaySetHintItem: Identifiable, Equatable {
    let id: String
    let word: String
    let translation: String
    let example: String?
    let imageURL: String?
}
