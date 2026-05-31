import Foundation

protocol ReadingLocalQuestionGenerating: Sendable {
    func generateQuestions(for text: ReadingUserText, focus: ReadingFocus?, maxQuestions: Int) async -> [ReadingQuestion]
}

/// Deterministic local question generation — no AI.
/// TODO: Optional AI question fallback can replace this later.
struct ReadingLocalQuestionService: ReadingLocalQuestionGenerating, Sendable {
    static let shared = ReadingLocalQuestionService()

    private let analyzer = ReadingTextAnalyzerService.shared

    func generateQuestions(for text: ReadingUserText, focus: ReadingFocus? = nil, maxQuestions: Int = 5) async -> [ReadingQuestion] {
        await Task.detached {
            Self.buildQuestions(
                content: text.content,
                title: text.title,
                preview: text.preview,
                sentences: self.analyzer.sentences(from: text.content),
                focus: focus ?? .mainIdea,
                maxQuestions: maxQuestions
            )
        }.value
    }

    func generateQuestions(for text: ReadingUserText, focus: ReadingFocus?, maxQuestions: Int) -> [ReadingQuestion] {
        Self.buildQuestions(
            content: text.content,
            title: text.title,
            preview: text.preview,
            sentences: analyzer.sentences(from: text.content),
            focus: focus ?? .mainIdea,
            maxQuestions: maxQuestions
        )
    }

    // Legacy
    func generateQuestions(from text: String, title: String, maxQuestions: Int = 5) -> [ReadingQuestion] {
        let sentences = analyzer.sentences(from: text)
        return Self.buildQuestions(
            content: text,
            title: title,
            preview: analyzer.preview(for: text),
            sentences: sentences,
            focus: .mainIdea,
            maxQuestions: maxQuestions
        )
    }

    // MARK: - Builder

    private static func buildQuestions(
        content: String,
        title: String,
        preview: String,
        sentences: [String],
        focus: ReadingFocus,
        maxQuestions: Int
    ) -> [ReadingQuestion] {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return [] }

        var questions: [ReadingQuestion] = []
        var usedPrompts = Set<String>()

        func append(_ question: ReadingQuestion?) {
            guard let question, !usedPrompts.contains(question.prompt) else { return }
            usedPrompts.insert(question.prompt)
            questions.append(question)
        }

        switch focus {
        case .mainIdea, .detailedComprehension:
            append(makeComprehension(title: title, preview: preview, sentences: sentences))
            for sentence in sentences.prefix(4) {
                guard questions.count < maxQuestions else { break }
                append(makeTrueFalse(sentence: sentence, preferTrue: questions.count.isMultiple(of: 2)))
            }
        case .vocabulary:
            append(makeComprehension(title: title, preview: preview, sentences: sentences))
            for sentence in sentences.prefix(4) {
                guard questions.count < maxQuestions else { break }
                append(makeVocabulary(sentence: sentence, allContent: content))
            }
        }

        for sentence in sentences where questions.count < maxQuestions {
            append(makeFillGap(sentence: sentence, allContent: content))
        }

        if questions.isEmpty, sentences.count >= 1 {
            append(makeComprehension(title: title, preview: preview, sentences: sentences))
        }

        return Array(questions.prefix(maxQuestions))
    }

    private static func makeComprehension(title: String, preview: String, sentences: [String]) -> ReadingQuestion? {
        let lead = sentences.first ?? preview
        let correct = lead.count > 120 ? String(lead.prefix(117)) + "…" : lead
        var options = [correct]
        for sentence in sentences.dropFirst().prefix(2) {
            options.append(sentence.count > 80 ? String(sentence.prefix(77)) + "…" : sentence)
        }
        while options.count < 4 {
            options.append(["The text discusses something else.", "The text has no topic.", "The text is only a title."][options.count - 1])
        }
        options = shuffleOptions(options, correct: correct)

        return ReadingQuestion(
            id: UUID().uuidString,
            type: .comprehension,
            prompt: "What is the main idea of \"\(title)\"?",
            options: options,
            correctAnswer: correct,
            explanation: "This matches the opening idea of the text.",
            sourceSentence: lead
        )
    }

    private static func makeTrueFalse(sentence: String, preferTrue: Bool) -> ReadingQuestion? {
        let words = meaningfulWords(in: sentence)
        guard words.count >= 4 else { return nil }

        if preferTrue {
            return ReadingQuestion(
                id: UUID().uuidString,
                type: .trueFalse,
                prompt: "True or false: \"\(sentence)\"",
                options: ["True", "False"],
                correctAnswer: "True",
                explanation: "This statement matches the text.",
                sourceSentence: sentence
            )
        }

        guard let target = words.first(where: { $0.count >= 5 }) else { return nil }
        let falseSentence = sentence.replacingOccurrences(
            of: target,
            with: "never",
            options: .caseInsensitive,
            range: sentence.range(of: target, options: .caseInsensitive)
        )
        guard falseSentence != sentence else { return nil }

        return ReadingQuestion(
            id: UUID().uuidString,
            type: .trueFalse,
            prompt: "True or false: \"\(falseSentence)\"",
            options: ["True", "False"],
            correctAnswer: "False",
            explanation: "This modified statement does not match the original text.",
            sourceSentence: sentence
        )
    }

    private static func makeFillGap(sentence: String, allContent: String) -> ReadingQuestion? {
        let words = meaningfulWords(in: sentence).filter { $0.count >= 5 }
        guard words.count >= 1, sentence.split(separator: " ").count >= 6 else { return nil }
        guard let target = words.max(by: { $0.count < $1.count }) else { return nil }

        let gapSentence = sentence.replacingOccurrences(
            of: target,
            with: "____",
            options: .caseInsensitive,
            range: sentence.range(of: target, options: .caseInsensitive)
        )

        var distractors = meaningfulWords(in: allContent)
            .filter { $0.caseInsensitiveCompare(target) != .orderedSame && $0.count >= 4 }
            .prefix(6)
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }

        var options = [target.prefix(1).uppercased() + target.dropFirst()] + Array(distractors)
        options = Array(Set(options.map { $0.lowercased() })).prefix(4).map { $0.prefix(1).uppercased() + $0.dropFirst() }
        guard options.count >= 2 else { return nil }

        let correct = options.first { $0.lowercased() == target.lowercased() } ?? options[0]
        options = shuffleOptions(Array(options), correct: correct)

        return ReadingQuestion(
            id: UUID().uuidString,
            type: .fillGap,
            prompt: "Fill the gap: \(gapSentence)",
            options: options,
            correctAnswer: correct,
            explanation: "The word appears in the original sentence.",
            sourceSentence: sentence
        )
    }

    private static func makeVocabulary(sentence: String, allContent: String) -> ReadingQuestion? {
        let candidates = meaningfulWords(in: sentence).filter { $0.count >= 6 }
        guard let target = candidates.max(by: { $0.count < $1.count }) else { return nil }

        let displayTarget = target.prefix(1).uppercased() + target.dropFirst()
        var options = [displayTarget]
        options.append(contentsOf: meaningfulWords(in: allContent)
            .filter { $0.caseInsensitiveCompare(target) != .orderedSame && $0.count >= 5 }
            .prefix(3)
            .map { $0.prefix(1).uppercased() + $0.dropFirst() })

        options = Array(Set(options.map { $0.lowercased() }))
            .prefix(4)
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
        guard options.count >= 2 else { return nil }

        options = shuffleOptions(Array(options), correct: displayTarget)

        return ReadingQuestion(
            id: UUID().uuidString,
            type: .vocabulary,
            prompt: "Which word from the text appears in this sentence?\n\"\(sentence)\"",
            options: options,
            correctAnswer: displayTarget,
            explanation: "\"\(displayTarget)\" is a key word in this sentence.",
            sourceSentence: sentence
        )
    }

    private static func meaningfulWords(in text: String) -> [String] {
        text.lowercased()
            .split { !$0.isLetter }
            .map(String.init)
            .filter { $0.count >= 3 && !stopWords.contains($0) }
    }

    private static func shuffleOptions(_ options: [String], correct: String) -> [String] {
        var shuffled = options
        shuffled.shuffle()
        if !shuffled.contains(where: { $0.caseInsensitiveCompare(correct) == .orderedSame }) {
            shuffled[0] = correct
        }
        return shuffled
    }

    private static let stopWords: Set<String> = [
        "the", "and", "for", "that", "with", "this", "from", "have", "were", "was", "are",
        "but", "not", "you", "your", "they", "them", "their", "what", "when", "where", "which"
    ]
}
