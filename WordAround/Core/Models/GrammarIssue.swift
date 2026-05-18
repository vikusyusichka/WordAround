import Foundation

enum GrammarIssueCategory: String, CaseIterable, Identifiable, Equatable {
    case grammar = "Grammar"
    case vocabulary = "Vocabulary"
    case style = "Style"

    var id: String { rawValue }
}

struct GrammarIssue: Identifiable, Equatable {
    let id: UUID
    let message: String
    let incorrectText: String
    let suggestedCorrection: String?
    let offset: Int
    let length: Int
    let category: GrammarIssueCategory

    init(
        id: UUID = UUID(),
        message: String,
        incorrectText: String,
        suggestedCorrection: String?,
        offset: Int,
        length: Int,
        category: GrammarIssueCategory = .grammar
    ) {
        self.id = id
        self.message = message
        self.incorrectText = incorrectText
        self.suggestedCorrection = suggestedCorrection
        self.offset = offset
        self.length = length
        self.category = category
    }

    var hasSuggestion: Bool {
        guard let suggestedCorrection else { return false }
        return !suggestedCorrection.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
