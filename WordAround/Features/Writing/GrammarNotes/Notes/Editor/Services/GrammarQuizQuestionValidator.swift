import Foundation

// MARK: - Errors

enum GrammarQuizValidationError: LocalizedError, Equatable {
    case empty
    case invalidQuestion(index: Int, reason: String)

    var errorDescription: String? {
        switch self {
        case .empty:
            return "No quiz questions were created. Please try again."
        case .invalidQuestion(let index, let reason):
            return "Question \(index + 1) is invalid: \(reason)"
        }
    }
}

// MARK: - Validator

/// Normalizes and validates a batch of `GrammarQuizQuestion` before
/// they are persisted. AI-generated and manually authored questions
/// are both run through this so we never trust untyped input.
///
/// On success returns a fresh, ordered array with:
///  - trimmed text / answers
///  - unique non-empty IDs
///  - sequential `order` values
///  - options normalized for each question type
enum GrammarQuizQuestionValidator {

    static func validate(_ questions: [GrammarQuizQuestion]) throws -> [GrammarQuizQuestion] {
        guard !questions.isEmpty else { throw GrammarQuizValidationError.empty }

        var seenIDs = Set<String>()
        var normalized: [GrammarQuizQuestion] = []
        normalized.reserveCapacity(questions.count)

        for (index, raw) in questions.enumerated() {
            var q = raw

            // Text + correct answer must both be non-empty after trimming.
            let trimmedText = q.questionText.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedAnswer = q.correctAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedText.isEmpty else {
                throw GrammarQuizValidationError.invalidQuestion(index: index, reason: "missing question text")
            }
            guard !trimmedAnswer.isEmpty else {
                throw GrammarQuizValidationError.invalidQuestion(index: index, reason: "missing correct answer")
            }
            q.questionText = trimmedText
            q.correctAnswer = trimmedAnswer
            q.explanation = q.explanation?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .nonEmptyOrNil

            // Per-type rules.
            switch q.type {
            case .multipleChoice:
                let opts = q.options
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                guard opts.count >= 2 else {
                    throw GrammarQuizValidationError.invalidQuestion(
                        index: index,
                        reason: "multiple choice needs at least 2 options"
                    )
                }
                guard opts.contains(where: { $0.caseInsensitiveCompare(trimmedAnswer) == .orderedSame }) else {
                    throw GrammarQuizValidationError.invalidQuestion(
                        index: index,
                        reason: "options must contain the correct answer"
                    )
                }
                // De-duplicate options while preserving order.
                var seen = Set<String>()
                q.options = opts.filter { opt in
                    let key = opt.lowercased()
                    if seen.contains(key) { return false }
                    seen.insert(key); return true
                }

            case .trueFalse:
                let normalizedAnswer = trimmedAnswer.lowercased()
                guard normalizedAnswer == "true" || normalizedAnswer == "false" else {
                    throw GrammarQuizValidationError.invalidQuestion(
                        index: index,
                        reason: "true/false answer must be True or False"
                    )
                }
                q.correctAnswer = (normalizedAnswer == "true") ? "True" : "False"
                q.options = ["True", "False"]

            case .fillGap:
                // Must contain a blank — either underscore(s) or an explicit marker.
                if !trimmedText.contains("_") {
                    throw GrammarQuizValidationError.invalidQuestion(
                        index: index,
                        reason: "fill gap must contain a blank (e.g. _____)"
                    )
                }
                q.options = []

            case .shortAnswer:
                q.options = []
            }

            // Ensure unique non-empty id and sequential order.
            if q.id.isEmpty || seenIDs.contains(q.id) {
                q.id = UUID().uuidString
            }
            seenIDs.insert(q.id)
            q.order = index

            normalized.append(q)
        }

        return normalized
    }
}

// MARK: - File-private helpers

private extension String {
    var nonEmptyOrNil: String? { isEmpty ? nil : self }
}
