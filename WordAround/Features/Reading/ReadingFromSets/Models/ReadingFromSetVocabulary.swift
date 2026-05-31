import Foundation

struct ReadingFromSetWord: Identifiable, Equatable, Hashable {
    let id: String
    let term: String
    let translation: String?
    let example: String?

    init(id: String = UUID().uuidString, term: String, translation: String? = nil, example: String? = nil) {
        self.id = id
        self.term = term
        self.translation = translation
        self.example = example
    }
}

struct ReadingFromSetVocabulary: Equatable {
    let setId: String
    let setTitle: String
    let words: [ReadingFromSetWord]

    var count: Int { words.count }
    var terms: [String] { words.map(\.term) }
}
