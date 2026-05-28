import Foundation

/// A single card in an active review session.
/// Bundles the persistence item with enriched content for the multi-phase
/// review flow: show source → answer question → see result → rate recall.
///
/// Every card is backed by an actual `GrammarNote` — the queue builder
/// fetches the note up front and drops the item from the queue if the
/// note cannot be loaded or has no usable content. There is no rate-only
/// fallback: a card without a question never reaches the session.
struct GrammarReviewSessionCard: Identifiable {
    let id: String
    let reviewItem: GrammarReviewItem

    /// Which pool of items the active session is drawing from. Drives the
    /// "Manual / Recently opened / Recently edited" badge on every card.
    let sourcePool: GrammarReviewSourcePool

    /// The full note this card is built from. Held so the session can offer
    /// "Open full note" without a second Firestore round-trip.
    let note: GrammarNote

    /// The block text shown in the "Study" phase.
    let sourceText: String

    /// Optional secondary text (e.g. secondaryText from a comparison block).
    let sourceSecondaryText: String?

    /// The block type of the source (used to render the source card label).
    let sourceBlockType: GrammarNoteBlockType?

    /// A question generated from the note content for the "Answer" phase.
    /// Always non-nil — the queue builder skips items that can't produce a
    /// usable question rather than degrading to rate-only mode.
    let question: GrammarQuizQuestion

    var displayTitle: String {
        reviewItem.title.isEmpty ? "Grammar Note" : reviewItem.title
    }
}
