import Foundation

struct GrammarReviewSessionCard: Identifiable {
    let id: String
    let reviewItem: GrammarReviewItem

    let sourcePool: GrammarReviewSourcePool

    let note: GrammarNote

    let sourceText: String

    let sourceSecondaryText: String?

    let sourceBlockType: GrammarNoteBlockType?

    let question: GrammarQuizQuestion

    var displayTitle: String {
        reviewItem.title.isEmpty ? "Note" : reviewItem.title
    }
}
