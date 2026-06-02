import Foundation

final class GrammarReviewQueueBuilder: @unchecked Sendable {

    private let noteService: GrammarNoteServicing

    init(noteService: GrammarNoteServicing = GrammarNoteService()) {
        self.noteService = noteService
    }

    struct Result: Equatable {
        let cards: [GrammarReviewSessionCard]
        let pool: GrammarReviewSourcePool?

        static let empty = Result(cards: [], pool: nil)

        var isEmpty: Bool { cards.isEmpty }
        var count: Int { cards.count }
        var estimatedMinutes: Int { max(1, cards.count * 2) }

        static func == (lhs: Result, rhs: Result) -> Bool {
            lhs.pool == rhs.pool
                && lhs.cards.map(\.id) == rhs.cards.map(\.id)
        }
    }

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

        return Result(cards: cards, pool: cards.isEmpty ? nil : pool)
    }

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
        return blocks.first {
            !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && $0.type != .heading
                && $0.type != .subheading
                && $0.type != .divider
                && $0.type != .image
        }
    }

    private func generateQuestion(
        note: GrammarNote,
        primaryBlock: GrammarNoteBlock?,
        item: GrammarReviewItem
    ) -> GrammarQuizQuestion {
        let types: Set<GrammarQuizQuestionType> = [
            .multipleChoice, .trueFalse, .fillGap, .shortAnswer
        ]

        if let generated = try? GrammarQuizGenerator.generate(
            from: note.contentBlocks,
            count: 1,
            types: types
        ).first {
            return generated
        }

        if let primaryBlock,
           let single = singleBlockQuestion(block: primaryBlock, note: note) {
            return single
        }

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

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
