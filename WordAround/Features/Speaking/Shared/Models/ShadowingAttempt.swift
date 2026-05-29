import Foundation

/// The result of comparing one spoken attempt against a target phrase.
///
/// IMPORTANT: `accuracy` is estimated from *transcript similarity only*.
/// It is NOT a true accent / pronunciation analysis — there is no audio
/// signal analysis here. The score reflects how closely the recognized
/// words match the target words.
struct ShadowingAttempt: Identifiable, Equatable {
    let id: UUID
    let phraseID: UUID
    let targetText: String
    let userTranscript: String

    /// 0...100, derived from word-level F1 of recognized vs. target words.
    let accuracy: Int
    let matchedWords: [String]
    let missingWords: [String]
    let extraWords: [String]
    let feedback: String
    let createdAt: Date

    init(
        id: UUID = UUID(),
        phraseID: UUID,
        targetText: String,
        userTranscript: String,
        accuracy: Int,
        matchedWords: [String],
        missingWords: [String],
        extraWords: [String],
        feedback: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.phraseID = phraseID
        self.targetText = targetText
        self.userTranscript = userTranscript
        self.accuracy = accuracy
        self.matchedWords = matchedWords
        self.missingWords = missingWords
        self.extraWords = extraWords
        self.feedback = feedback
        self.createdAt = createdAt
    }
}

// MARK: - Comparison

/// Pure, testable text comparison for Shadowing. Multiset word matching
/// with an F1-based accuracy score so both *missing* and *extra* words
/// lower the result. Deliberately simple — see the note on `accuracy`.
enum ShadowingComparison {

    /// Normalizes text into comparable word tokens: lowercase, fold
    /// diacritics, strip punctuation, collapse whitespace.
    static func tokenize(_ text: String) -> [String] {
        let folded = text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        let cleaned = folded.unicodeScalars.map { scalar -> Character in
            if CharacterSet.alphanumerics.contains(scalar) || scalar == " " {
                return Character(scalar)
            }
            return " "
        }
        return String(cleaned)
            .split(separator: " ")
            .map(String.init)
            .filter { !$0.isEmpty }
    }

    static func evaluate(phrase: ShadowingPhrase, userTranscript: String) -> ShadowingAttempt {
        let targetTokens = tokenize(phrase.text)
        let userTokens = tokenize(userTranscript)

        // Multiset counts.
        var targetCounts: [String: Int] = [:]
        for t in targetTokens { targetCounts[t, default: 0] += 1 }
        var userCounts: [String: Int] = [:]
        for u in userTokens { userCounts[u, default: 0] += 1 }

        // Matched = sum of min(count) per shared token.
        var matched: [String] = []
        var matchedCount = 0
        for (token, tCount) in targetCounts {
            let m = min(tCount, userCounts[token] ?? 0)
            if m > 0 {
                matchedCount += m
                matched.append(contentsOf: Array(repeating: token, count: m))
            }
        }

        // Missing = target tokens (in order) not covered by user.
        var remainingMatch = matchedCount
        var consumed: [String: Int] = [:]
        var missing: [String] = []
        for token in targetTokens {
            let availableMatches = min(targetCounts[token] ?? 0, userCounts[token] ?? 0)
            let used = consumed[token, default: 0]
            if used < availableMatches {
                consumed[token] = used + 1
                remainingMatch -= 1
            } else {
                missing.append(token)
            }
        }

        // Extra = user tokens not present (or over-spoken) vs. target.
        var extraConsumed: [String: Int] = [:]
        var extra: [String] = []
        for token in userTokens {
            let allowed = targetCounts[token] ?? 0
            let used = extraConsumed[token, default: 0]
            if used < allowed {
                extraConsumed[token] = used + 1
            } else {
                extra.append(token)
            }
        }

        let targetCount = targetTokens.count
        let userCount = userTokens.count
        let precision = userCount == 0 ? 0 : Double(matchedCount) / Double(userCount)
        let recall = targetCount == 0 ? 0 : Double(matchedCount) / Double(targetCount)
        let f1 = (precision + recall) == 0 ? 0 : (2 * precision * recall) / (precision + recall)
        let accuracy = Int((f1 * 100).rounded())

        return ShadowingAttempt(
            phraseID: phrase.id,
            targetText: phrase.text,
            userTranscript: userTranscript,
            accuracy: accuracy,
            matchedWords: matched,
            missingWords: missing,
            extraWords: extra,
            feedback: feedbackText(accuracy: accuracy, missing: missing, extra: extra)
        )
    }

    private static func feedbackText(accuracy: Int, missing: [String], extra: [String]) -> String {
        switch accuracy {
        case 90...:
            return "Excellent — you matched the phrase almost word for word."
        case 75..<90:
            if !missing.isEmpty {
                return "Great attempt. Try to include the small function words too."
            }
            return "Great attempt. Very close to the target phrase."
        case 50..<75:
            return "Good start. Listen again and focus on the words you missed."
        default:
            if !extra.isEmpty && missing.isEmpty {
                return "You added words that weren't in the phrase. Try repeating it exactly."
            }
            return "Replay the phrase, then repeat it slowly and clearly."
        }
    }
}
