import Foundation

/// Builds an ordered list of `GrammarReviewSessionCard` items for a review session.
///
/// Priority order (drives which `sourcePool` the session uses, NEVER mixed):
///   1. Manual review items (from Firestore `grammarReviewItems` collection).
///   2. Recently opened notes (tracked via `GrammarReviewViewModel.recordOpenedNote`).
///   3. Recently edited notes (tracked via `GrammarReviewViewModel.recordEditedNote`).
///
/// The first non-empty pool wins; the others are ignored. This matches the
/// Review Today contract — we don't want to mix manual and recommended in
/// the same session.
///
/// For every selected item the builder:
///   - Fetches the full `GrammarNote` (skips the item if the note is missing
///     or has no usable content).
///   - Picks the most useful block (rule > warning > comparison > example > paragraph > …).
///   - Generates a deterministic local question — never from AI, never
///     async — using `GrammarQuizGenerator` first, then a single-block
///     fallback. Items that can't produce a usable question are skipped
///     entirely instead of degrading to rate-only mode.
final class GrammarReviewQueueBuilder: @unchecked Sendable {

    private let noteService: GrammarNoteServicing

    init(noteService: GrammarNoteServicing = GrammarNoteService()) {
        self.noteService = noteService
    }

    // MARK: - Result

    /// Output of `build(...)`: the ordered card list AND the source pool the
    /// builder actually drew from. This is the **single source of truth**
    /// for both the Review Today home card (count + pool) and the session
    /// (card list). The session never rebuilds — it reads `cards` directly.
    struct Result: Equatable {
        let cards: [GrammarReviewSessionCard]
        let pool: GrammarReviewSourcePool?

        static let empty = Result(cards: [], pool: nil)

        var isEmpty: Bool { cards.isEmpty }
        var count: Int { cards.count }
        /// Rough estimate used by the home card's "~N min" badge. ~2 minutes
        /// per card matches the previous heuristic.
        var estimatedMinutes: Int { max(1, cards.count * 2) }

        static func == (lhs: Result, rhs: Result) -> Bool {
            lhs.pool == rhs.pool
                && lhs.cards.map(\.id) == rhs.cards.map(\.id)
        }
    }

    // MARK: - Build

    /// Selects the first non-empty pool in priority order and builds cards
    /// from it. Returns an empty result only when every pool is empty OR
    /// every fetched note has been deleted from Firestore. Cards with
    /// thin content fall back to a title/preview question — they're never
    /// silently dropped, so the home card count always matches the session.
    func build(
        manualItems: [GrammarReviewItem],
        recentlyOpened: [GrammarReviewRecommendation],
        recentlyEdited: [GrammarReviewRecommendation],
        limit: Int = 20
    ) async -> Result {
        let (selectedItems, pool) = selectPool(
            manualItems: manualItems,
            recentlyOpened: recentlyOpened,
            recentlyEdited: recentlyEdited
        )

        #if DEBUG
        print("[ReviewQueue] selectPool → pool=\(pool?.rawValue ?? "nil") items=\(selectedItems.count) manual=\(manualItems.count) opened=\(recentlyOpened.count) edited=\(recentlyEdited.count)")
        #endif

        guard let pool, !selectedItems.isEmpty else {
            return .empty
        }

        let capped = Array(selectedItems.prefix(limit))

        let cards = await withTaskGroup(of: (Int, GrammarReviewSessionCard?).self) { group in
            for (index, item) in capped.enumerated() {
                group.addTask { [self] in
                    (index, await self.buildCard(for: item, pool: pool))
                }
            }
            var indexed: [(Int, GrammarReviewSessionCard)] = []
            for await (i, card) in group {
                if let card { indexed.append((i, card)) }
            }
            return indexed.sorted { $0.0 < $1.0 }.map { $0.1 }
        }

        #if DEBUG
        print("[ReviewQueue] built cards=\(cards.count) ids=\(cards.map { $0.id })")
        #endif

        // If every fetched note has been deleted from Firestore, we end up
        // with an empty card list but `selectedItems.isEmpty == false`.
        // Returning `pool: nil` here keeps the contract simple:
        // "non-nil pool ⇒ at least one card to review".
        return Result(cards: cards, pool: cards.isEmpty ? nil : pool)
    }

    // MARK: - Pool selection

    /// Picks the first non-empty pool in priority order. Manual wins over
    /// every recommendation pool, even if there are far more recommendations.
    private func selectPool(
        manualItems: [GrammarReviewItem],
        recentlyOpened: [GrammarReviewRecommendation],
        recentlyEdited: [GrammarReviewRecommendation]
    ) -> ([GrammarReviewItem], GrammarReviewSourcePool?) {
        if !manualItems.isEmpty {
            return (manualItems, .manual)
        }
        if !recentlyOpened.isEmpty {
            return (recentlyOpened.map { $0.reviewItem }, .recentlyOpened)
        }
        if !recentlyEdited.isEmpty {
            return (recentlyEdited.map { $0.reviewItem }, .recentlyEdited)
        }
        return ([], nil)
    }

    // MARK: - Card building

    private func buildCard(
        for item: GrammarReviewItem,
        pool: GrammarReviewSourcePool
    ) async -> GrammarReviewSessionCard? {
        guard let noteId = item.noteId, !noteId.isEmpty, !item.topicId.isEmpty else {
            #if DEBUG
            print("[ReviewQueue] DROP item=\(item.id) — missing noteId or topicId")
            #endif
            return nil
        }

        // Note fetch must succeed — a missing source note is the only
        // legitimate reason to drop a card. Everything else has a fallback.
        guard let note = try? await noteService.fetchNote(
            id: noteId,
            ownerUID: item.ownerUID,
            topicId: item.topicId
        ) else {
            #if DEBUG
            print("[ReviewQueue] DROP item=\(item.id) — note not found in Firestore")
            #endif
            return nil
        }

        let block = selectBestBlock(from: note.contentBlocks)
        let question = generateQuestion(
            note: note,
            primaryBlock: block,
            item: item
        )

        // Source text: prefer the picked block's text, fall back to the
        // note's previewText, then the title. The user will always see
        // *something* meaningful from the actual note — never random text.
        let sourceText = pickSourceText(block: block, note: note, item: item)

        return GrammarReviewSessionCard(
            id: item.id,
            reviewItem: item,
            sourcePool: pool,
            note: note,
            sourceText: sourceText,
            sourceSecondaryText: block?.secondaryText?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
            sourceBlockType: block?.type,
            question: question
        )
    }

    /// Picks the most readable text to show in the Study phase. Order:
    /// primary block text → note previewText → review item previewText →
    /// note title → review item title. Guarantees a non-empty string.
    private func pickSourceText(
        block: GrammarNoteBlock?,
        note: GrammarNote,
        item: GrammarReviewItem
    ) -> String {
        if let block {
            let text = block.text.trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty { return text }
        }
        let notePreview = note.previewText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !notePreview.isEmpty { return notePreview }
        let itemPreview = item.previewText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !itemPreview.isEmpty { return itemPreview }
        let noteTitle = note.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !noteTitle.isEmpty { return noteTitle }
        return item.title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Block selection

    /// Priority order from the Review Today spec:
    ///   rule > warning > comparison > example > paragraph > first available text block
    private func selectBestBlock(from blocks: [GrammarNoteBlock]) -> GrammarNoteBlock? {
        let priority: [GrammarNoteBlockType] = [
            .rule, .warning, .comparison, .example, .paragraph, .quote, .exercise
        ]
        for type in priority {
            if let b = blocks.first(where: {
                $0.type == type && !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }) {
                return b
            }
        }
        // Fallback: first non-empty text-bearing block (skip layout-only types).
        return blocks.first {
            !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && $0.type != .heading
                && $0.type != .subheading
                && $0.type != .divider
                && $0.type != .image
        }
    }

    // MARK: - Question generation

    /// Tries `GrammarQuizGenerator` first (needs 2+ blocks), then a
    /// single-block deterministic builder, then a title/preview fallback.
    /// **Always returns a non-nil question** so the queue never silently
    /// drops a card just because the note has minimal content — the home
    /// card count must equal the session count.
    private func generateQuestion(
        note: GrammarNote,
        primaryBlock: GrammarNoteBlock?,
        item: GrammarReviewItem
    ) -> GrammarQuizQuestion {
        let types: Set<GrammarQuizQuestionType> = [
            .multipleChoice, .trueFalse, .fillGap, .shortAnswer
        ]

        // Layer 1: full-note generator (best distractors for multiple choice).
        if let generated = try? GrammarQuizGenerator.generate(
            from: note.contentBlocks,
            count: 1,
            types: types
        ).first {
            return generated
        }

        // Layer 2: single-block deterministic fallback.
        if let primaryBlock,
           let single = singleBlockQuestion(block: primaryBlock, note: note) {
            return single
        }

        // Layer 3: ultimate fallback — short-answer question grounded in
        // the note's preview/title. The user still gets a real question
        // backed by their note instead of being dropped from the queue.
        return ultimateFallbackQuestion(note: note, item: item)
    }

    private func ultimateFallbackQuestion(
        note: GrammarNote,
        item: GrammarReviewItem
    ) -> GrammarQuizQuestion {
        let answerText: String = {
            let preview = note.previewText.trimmingCharacters(in: .whitespacesAndNewlines)
            if !preview.isEmpty { return preview }
            let itemPreview = item.previewText.trimmingCharacters(in: .whitespacesAndNewlines)
            if !itemPreview.isEmpty { return itemPreview }
            let title = note.title.trimmingCharacters(in: .whitespacesAndNewlines)
            if !title.isEmpty { return title }
            return item.title
        }()
        return GrammarQuizQuestion(
            type: .shortAnswer,
            questionText: "What is the key idea of this note?",
            correctAnswer: String(answerText.prefix(160)),
            order: 0
        )
    }

    // MARK: - Single-block fallback

    /// Deterministic question generation from just the primary block.
    /// Picks the question type based on what content the block offers:
    ///   - comparison + secondary text → multiple choice
    ///   - warning                     → true/false
    ///   - rule with secondary text     → short answer (explain)
    ///   - rule without secondary       → short answer (state)
    ///   - example with secondary text  → short answer (what does it show?)
    ///   - anything else with > 20 chars → short answer (key idea)
    private func singleBlockQuestion(
        block: GrammarNoteBlock,
        note: GrammarNote
    ) -> GrammarQuizQuestion? {
        let text = block.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let secondary = block.secondaryText?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }

        switch block.type {
        case .comparison:
            if let secondary, !secondary.isEmpty {
                let options = [text, secondary, "Neither applies", "Both are correct"].sorted()
                return GrammarQuizQuestion(
                    type: .multipleChoice,
                    questionText: "Which form is correct here?",
                    options: Array(options.prefix(4)),
                    correctAnswer: text,
                    explanation: "Compare: \(text) vs \(secondary)",
                    order: 0
                )
            }

        case .warning:
            return GrammarQuizQuestion(
                type: .trueFalse,
                questionText: "True or False: \"\(String(text.prefix(100)))\" is a common grammar mistake.",
                options: ["True", "False"],
                correctAnswer: "True",
                explanation: secondary ?? text,
                order: 0
            )

        case .rule:
            let answer = (secondary?.nilIfEmpty) ?? text
            let prompt = (secondary?.nilIfEmpty != nil)
                ? "Explain this rule in your own words."
                : "What does this grammar rule state?"
            return GrammarQuizQuestion(
                type: .shortAnswer,
                questionText: prompt,
                correctAnswer: String(answer.prefix(160)),
                explanation: secondary,
                order: 0
            )

        case .example:
            if let secondary, !secondary.isEmpty {
                return GrammarQuizQuestion(
                    type: .shortAnswer,
                    questionText: "What does this example illustrate?",
                    correctAnswer: String(secondary.prefix(160)),
                    explanation: secondary,
                    order: 0
                )
            }

        default:
            break
        }

        // Generic short-answer fallback. Lowered the floor to 4 characters
        // so single-word mistake notes (e.g. "ser") still produce a question.
        // The ultimate title/preview fallback in `generateQuestion` catches
        // empty blocks, so we never silently drop a card.
        guard text.count >= 4 else { return nil }
        return GrammarQuizQuestion(
            type: .shortAnswer,
            questionText: shortAnswerPrompt(for: block.type),
            correctAnswer: String(text.prefix(160)),
            explanation: secondary,
            order: 0
        )
    }

    private func shortAnswerPrompt(for blockType: GrammarNoteBlockType) -> String {
        switch blockType {
        case .rule:       return "Explain this grammar rule in your own words."
        case .warning:    return "What should you avoid here?"
        case .example:    return "What does this example demonstrate?"
        case .comparison: return "Explain the difference between these two forms."
        case .quote:      return "What is the key idea of this quote?"
        case .exercise:   return "Describe how you would complete this exercise."
        default:          return "What is the key idea of this note?"
        }
    }
}

// MARK: - String helper

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
