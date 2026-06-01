import Foundation

/// On-device comprehension question generator. Produces multiple-choice /
/// true-false questions from a passage using lightweight heuristics. No network
/// or AI calls — runs entirely locally so Listen From Text and Import Audio work
/// offline. Replaceable by an AI-backed `ListeningQuestionGenerating` later.
struct LocalListeningQuestionGenerator: ListeningQuestionGenerating {

    func generateQuestions(
        from text: String,
        language: GrammarLanguage,
        level: EssayDifficulty,
        types: Set<ListeningQuestionType>,
        count: Int
    ) async -> [ListeningQuestion] {
        let enabled = types.isEmpty ? Set(ListeningQuestionType.allCases) : types
        return await Task.detached(priority: .userInitiated) {
            Self.build(text: text, enabledTypes: enabled, maxQuestions: max(1, count))
        }.value
    }

    // MARK: - Builder

    private static func build(
        text: String,
        enabledTypes: Set<ListeningQuestionType>,
        maxQuestions: Int
    ) -> [ListeningQuestion] {
        let sentences = self.sentences(from: text)
        guard !sentences.isEmpty else { return [] }

        var questions: [ListeningQuestion] = []
        var usedPrompts = Set<String>()

        func append(_ question: ListeningQuestion?) {
            guard let question,
                  enabledTypes.contains(question.type),
                  !usedPrompts.contains(question.prompt),
                  questions.count < maxQuestions else { return }
            usedPrompts.insert(question.prompt)
            questions.append(question)
        }

        // 1. Main idea — always first when enabled.
        if enabledTypes.contains(.mainIdea) {
            append(makeMainIdea(sentences: sentences))
        }

        // 2. Detail questions from the body sentences.
        if enabledTypes.contains(.details) {
            for sentence in sentences.dropFirst().prefix(4) {
                append(makeDetail(sentence: sentence, otherSentences: sentences))
            }
        }

        // 3. Vocabulary / word recognition.
        if enabledTypes.contains(.vocabulary) {
            for sentence in sentences.prefix(4) {
                append(makeVocabulary(sentence: sentence, allText: text))
            }
        }

        // 4. True / false.
        if enabledTypes.contains(.trueFalse) {
            for (index, sentence) in sentences.prefix(5).enumerated() {
                append(makeTrueFalse(sentence: sentence, preferTrue: index.isMultiple(of: 2)))
            }
        }

        // Fallback: if nothing matched the enabled types, still return a main idea.
        if questions.isEmpty {
            append(makeMainIdea(sentences: sentences))
        }

        return Array(questions.prefix(maxQuestions))
    }

    // MARK: - Question makers

    private static func makeMainIdea(sentences: [String]) -> ListeningQuestion? {
        let lead = sentences.first ?? ""
        guard !lead.isEmpty else { return nil }
        let correct = clip(lead, max: 120)
        var options = [correct]
        for sentence in sentences.dropFirst().prefix(2) {
            options.append(clip(sentence, max: 90))
        }
        let fillers = [
            "The passage has no clear topic.",
            "The passage is only a list of dates.",
            "The passage describes a different subject entirely."
        ]
        var i = 0
        while options.count < 4 && i < fillers.count {
            if !options.contains(fillers[i]) { options.append(fillers[i]) }
            i += 1
        }
        let (shuffled, correctIndex) = shuffle(options, correct: correct)
        return ListeningQuestion(
            id: UUID().uuidString,
            prompt: "What is the passage mainly about?",
            options: shuffled,
            correctIndex: correctIndex,
            type: .mainIdea,
            explanation: "This matches the opening, which states the main idea."
        )
    }

    private static func makeDetail(sentence: String, otherSentences: [String]) -> ListeningQuestion? {
        guard sentence.count >= 20 else { return nil }
        let correct = clip(sentence, max: 110)
        var options = [correct]
        for other in otherSentences where options.count < 3 {
            let snippet = clip(other, max: 90)
            if snippet != correct && !options.contains(snippet) { options.append(snippet) }
        }
        if options.count < 4 { options.append("This is never mentioned in the passage.") }
        let (shuffled, correctIndex) = shuffle(options, correct: correct)
        return ListeningQuestion(
            id: UUID().uuidString,
            prompt: "Which statement is mentioned in the passage?",
            options: shuffled,
            correctIndex: correctIndex,
            type: .details,
            explanation: "This detail appears in the passage."
        )
    }

    private static func makeVocabulary(sentence: String, allText: String) -> ListeningQuestion? {
        let candidates = meaningfulWords(in: sentence).filter { $0.count >= 6 }
        guard let target = candidates.max(by: { $0.count < $1.count }) else { return nil }
        let display = capitalize(target)

        var pool = Set([display])
        for word in meaningfulWords(in: allText) where pool.count < 4 {
            if word.caseInsensitiveCompare(target) != .orderedSame && word.count >= 5 {
                pool.insert(capitalize(word))
            }
        }
        guard pool.count >= 2 else { return nil }
        let (shuffled, correctIndex) = shuffle(Array(pool), correct: display)
        return ListeningQuestion(
            id: UUID().uuidString,
            prompt: "Which of these words was used in the passage?",
            options: shuffled,
            correctIndex: correctIndex,
            type: .vocabulary,
            explanation: "\"\(display)\" appears in the passage."
        )
    }

    private static func makeTrueFalse(sentence: String, preferTrue: Bool) -> ListeningQuestion? {
        let words = meaningfulWords(in: sentence)
        guard words.count >= 4 else { return nil }

        if preferTrue {
            return ListeningQuestion(
                id: UUID().uuidString,
                prompt: "True or false: \(clip(sentence, max: 140))",
                options: ["True", "False"],
                correctIndex: 0,
                type: .trueFalse,
                explanation: "This statement matches the passage."
            )
        }

        guard let target = words.first(where: { $0.count >= 5 }),
              let range = sentence.range(of: target, options: .caseInsensitive) else { return nil }
        let altered = sentence.replacingCharacters(in: range, with: "never")
        guard altered != sentence else { return nil }
        return ListeningQuestion(
            id: UUID().uuidString,
            prompt: "True or false: \(clip(altered, max: 140))",
            options: ["True", "False"],
            correctIndex: 1,
            type: .trueFalse,
            explanation: "This altered statement does not match the passage."
        )
    }

    // MARK: - Helpers

    static func sentences(from text: String) -> [String] {
        var result: [String] = []
        text.enumerateSubstrings(in: text.startIndex..., options: .bySentences) { substring, _, _, _ in
            if let s = substring?.trimmingCharacters(in: .whitespacesAndNewlines), s.count >= 8 {
                result.append(s)
            }
        }
        if result.isEmpty {
            // Fallback split on newlines for sources without sentence punctuation.
            result = text
                .split(whereSeparator: { $0 == "\n" })
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { $0.count >= 8 }
        }
        return result
    }

    private static func meaningfulWords(in text: String) -> [String] {
        text.lowercased()
            .split { !$0.isLetter }
            .map(String.init)
            .filter { $0.count >= 3 && !stopWords.contains($0) }
    }

    private static func clip(_ text: String, max: Int) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count > max ? String(trimmed.prefix(max - 1)) + "…" : trimmed
    }

    private static func capitalize(_ word: String) -> String {
        word.prefix(1).uppercased() + word.dropFirst()
    }

    /// Deduplicates, shuffles options and returns the index of `correct`.
    private static func shuffle(_ options: [String], correct: String) -> (options: [String], correctIndex: Int) {
        // Deduplicate while preserving order (NSOrderedSet is ObjC and fragile
        // across Swift value types — use a pure-Swift approach instead).
        var seen = Set<String>()
        var unique = options.filter { seen.insert($0).inserted }

        unique.shuffle()

        if let idx = unique.firstIndex(of: correct) {
            return (unique, idx)
        }
        // Correct answer was removed as duplicate or missing — re-insert at front.
        unique.insert(correct, at: 0)
        return (unique, 0)
    }

    private static let stopWords: Set<String> = [
        "the", "and", "for", "that", "with", "this", "from", "have", "were", "was", "are",
        "but", "not", "you", "your", "they", "them", "their", "what", "when", "where", "which",
        "has", "had", "his", "her", "its", "our", "out", "who", "she", "him", "all", "can"
    ]
}

/// Placeholder for a future AI-backed generator. The project's AI provider
/// router (Cloudflare Worker) can be wired in here without touching call sites,
/// since it conforms to the same `ListeningQuestionGenerating` protocol. Until
/// then it falls back to the local generator.
struct AIListeningQuestionGenerator: ListeningQuestionGenerating {
    private let fallback = LocalListeningQuestionGenerator()

    func generateQuestions(
        from text: String,
        language: GrammarLanguage,
        level: EssayDifficulty,
        types: Set<ListeningQuestionType>,
        count: Int
    ) async -> [ListeningQuestion] {
        // TODO: call the AI provider router with a task hint, then parse the
        // structured questions. For now delegate to the local generator.
        await fallback.generateQuestions(
            from: text, language: language, level: level, types: types, count: count
        )
    }
}
