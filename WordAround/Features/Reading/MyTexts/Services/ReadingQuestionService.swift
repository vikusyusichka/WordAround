import Foundation

struct ReadingQuestionService: ReadingQuestionGenerating, Sendable {
    static let shared = ReadingQuestionService()

    private let analyzer = ReadingTextAnalyzerService.shared

    func generateQuestions(
        for text: ReadingUserText,
        focus: ReadingFocus,
        enabledTypes: Set<ReadingQuestionType>,
        maxQuestions: Int = 8
    ) async -> [ReadingQuestion] {
        await Task.detached {
            Self.build(
                content: text.content,
                title: text.title,
                preview: text.preview,
                sentences: self.analyzer.sentences(from: text.content),
                focus: focus,
                enabledTypes: enabledTypes.isEmpty ? ReadingQuestionType.defaultEnabled : enabledTypes,
                maxQuestions: maxQuestions
            )
        }.value
    }

    private static func build(
        content: String,
        title: String,
        preview: String,
        sentences: [String],
        focus: ReadingFocus,
        enabledTypes: Set<ReadingQuestionType>,
        maxQuestions: Int
    ) -> [ReadingQuestion] {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return [] }

        var questions: [ReadingQuestion] = []
        var usedPrompts = Set<String>()

        func append(_ question: ReadingQuestion?) {
            guard let question, enabledTypes.contains(question.type), !usedPrompts.contains(question.prompt) else { return }
            usedPrompts.insert(question.prompt)
            questions.append(question)
        }

        if enabledTypes.contains(.comprehension) {
            append(makeComprehension(title: title, preview: preview, sentences: sentences, focus: focus))
        }

        if enabledTypes.contains(.trueFalse) {
            for (index, sentence) in sentences.prefix(4).enumerated() {
                guard questions.count < maxQuestions else { break }
                append(makeTrueFalse(sentence: sentence, preferTrue: index.isMultiple(of: 2)))
            }
        }

        if enabledTypes.contains(.vocabulary) {
            for sentence in sentences.prefix(3) {
                guard questions.count < maxQuestions else { break }
                append(makeVocabulary(sentence: sentence, allContent: content))
            }
        }

        if enabledTypes.contains(.fillGap) {
            for sentence in sentences where questions.count < maxQuestions {
                append(makeFillGap(sentence: sentence, allContent: content))
            }
        }

        if enabledTypes.contains(.findEvidence) {
            append(makeFindEvidence(sentences: sentences, preview: preview))
        }

        if enabledTypes.contains(.orderReconstruction), sentences.count >= 3 {
            append(makeOrderReconstruction(sentences: Array(sentences.prefix(4))))
        }

        if focus == .detailedComprehension || focus == .grammarAwareness {
            for sentence in sentences.dropFirst().prefix(2) where questions.count < maxQuestions {
                append(makeComprehensionDetail(sentence: sentence, title: title))
            }
        }

        if questions.isEmpty, enabledTypes.contains(.comprehension) {
            append(makeComprehension(title: title, preview: preview, sentences: sentences, focus: focus))
        }

        return Array(questions.prefix(maxQuestions))
    }

    private static func makeComprehension(
        title: String,
        preview: String,
        sentences: [String],
        focus: ReadingFocus
    ) -> ReadingQuestion? {
        let lead = sentences.first ?? preview
        let correct = lead.count > 120 ? String(lead.prefix(117)) + "…" : lead
        var options = [correct]
        for sentence in sentences.dropFirst().prefix(2) {
            options.append(sentence.count > 80 ? String(sentence.prefix(77)) + "…" : sentence)
        }
        while options.count < 4 {
            options.append(["The text discusses something else.", "The text has no clear topic.", "The text is only a title."][min(options.count - 1, 2)])
        }
        options = shuffleOptions(options, correct: correct)

        let prompt: String
        switch focus {
        case .mainIdea, .speedFluency:
            prompt = "What is the main idea of \"\(title)\"?"
        case .vocabulary:
            prompt = "Which option best summarizes \"\(title)\"?"
        default:
            prompt = "What is this text mostly about?"
        }

        return ReadingQuestion(
            id: UUID().uuidString,
            type: .comprehension,
            prompt: prompt,
            options: options,
            correctAnswer: correct,
            explanation: "This matches the central idea of the passage.",
            sourceSentence: lead
        )
    }

    private static func makeComprehensionDetail(sentence: String, title: String) -> ReadingQuestion? {
        guard sentence.count >= 20 else { return nil }
        let correct = sentence.count > 100 ? String(sentence.prefix(97)) + "…" : sentence
        var options = [correct, "The author changes topic completely.", "The sentence is unrelated to \(title).", "None of the above."]
        options = shuffleOptions(options, correct: correct)
        return ReadingQuestion(
            id: UUID().uuidString,
            type: .comprehension,
            prompt: "Which statement best reflects this part of the text?",
            options: options,
            correctAnswer: correct,
            explanation: "This sentence appears in the passage.",
            sourceSentence: sentence
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
            explanation: "\"\(displayTarget)\" is used in this sentence.",
            sourceSentence: sentence
        )
    }

    private static func makeFindEvidence(sentences: [String], preview: String) -> ReadingQuestion? {
        guard let claim = sentences.dropFirst().first ?? sentences.first ?? Optional(preview) else { return nil }
        let correct = claim.count > 110 ? String(claim.prefix(107)) + "…" : claim
        var options = [correct]
        for sentence in sentences.prefix(3) where options.count < 4 {
            let snippet = sentence.count > 90 ? String(sentence.prefix(87)) + "…" : sentence
            if !options.contains(where: { $0 == snippet }) { options.append(snippet) }
        }
        while options.count < 4 { options.append("No supporting sentence in the text.") }
        options = shuffleOptions(options, correct: correct)

        return ReadingQuestion(
            id: UUID().uuidString,
            type: .findEvidence,
            prompt: "Which sentence best supports the main point of the passage?",
            options: options,
            correctAnswer: correct,
            explanation: "This sentence supports the passage's main idea.",
            sourceSentence: claim
        )
    }

    private static func makeOrderReconstruction(sentences: [String]) -> ReadingQuestion? {
        guard sentences.count >= 3 else { return nil }
        let correct = sentences.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n")
        var shuffled = sentences.shuffled()
        if shuffled == sentences { shuffled.reverse() }
        let wrongA = shuffled.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n")
        let wrongB = sentences.reversed().enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n")
        let options = shuffleOptions([correct, wrongA, wrongB, sentences.dropFirst().map { $0 } .joined(separator: " ")], correct: correct)

        return ReadingQuestion(
            id: UUID().uuidString,
            type: .orderReconstruction,
            prompt: "Choose the correct order of these sentences:",
            options: options,
            correctAnswer: correct,
            explanation: "This order matches the original text flow.",
            sourceSentence: nil
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
            if shuffled.isEmpty { shuffled = [correct] } else { shuffled[0] = correct }
        }
        return shuffled
    }

    private static let stopWords: Set<String> = [
        "the", "and", "for", "that", "with", "this", "from", "have", "were", "was", "are",
        "but", "not", "you", "your", "they", "them", "their", "what", "when", "where", "which"
    ]
}
