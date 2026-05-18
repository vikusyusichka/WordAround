import Foundation

struct GrammarIssue: Identifiable, Equatable {
    let id = UUID()
    let message: String
    let incorrectText: String
    let suggestedCorrection: String?
    let offset: Int
    let length: Int

    var hasSuggestion: Bool {
        guard let suggestedCorrection else { return false }
        return !suggestedCorrection.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
