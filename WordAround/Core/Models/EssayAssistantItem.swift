import Foundation

enum EssayAssistanceModalType: Equatable {
    case translate
    case synonym
}

struct EssayAssistanceItem: Identifiable, Equatable {
    let id = UUID()
    let word: String
    let result: String
    let detail: String?

    init(word: String, result: String, detail: String? = nil) {
        self.word = word
        self.result = result
        self.detail = detail
    }
}
