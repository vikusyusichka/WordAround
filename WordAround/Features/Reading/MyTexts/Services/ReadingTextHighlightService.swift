import Foundation
import SwiftUI
import UIKit

enum ReadingTextHighlightService {
    private static let commonWords: Set<String> = [
        "about", "after", "again", "against", "among", "because", "before", "being",
        "between", "could", "during", "every", "first", "found", "from", "have",
        "into", "just", "like", "made", "many", "more", "most", "much", "must",
        "only", "other", "over", "people", "said", "same", "should", "some",
        "such", "than", "that", "their", "them", "then", "there", "these", "they",
        "this", "those", "through", "under", "until", "very", "were", "what",
        "when", "where", "which", "while", "with", "would", "your",
        "the", "and", "for", "are", "but", "not", "you", "all", "can", "had",
        "her", "was", "one", "our", "out", "day", "get", "has", "him", "his",
        "how", "its", "may", "new", "now", "old", "see", "two", "way", "who",
        "did", "she", "use", "own", "say", "too", "any", "also", "back", "been",
        "come", "does", "down", "each", "even", "give", "good", "here", "high",
        "know", "last", "left", "life", "long", "look", "make", "man", "men",
        "might", "never", "next", "once", "part", "place", "right", "small",
        "still", "take", "tell", "think", "time", "turn", "want", "well", "went",
        "will", "work", "world", "year", "years", "young"
    ]

    static func attributedString(
        for content: String,
        baseColor: Color,
        highlightColor: Color
    ) -> AttributedString {
        AttributedString(nsAttributedString(for: content, baseColor: baseColor, highlightColor: highlightColor))
    }

    static func nsAttributedString(
        for content: String,
        baseColor: Color,
        highlightColor: Color
    ) -> NSAttributedString {
        let uiBase = UIColor(baseColor)
        let uiHighlight = UIColor(highlightColor)
        let mutable = NSMutableAttributedString(
            string: content,
            attributes: [
                .font: UIFont.systemFont(ofSize: 16, weight: .medium),
                .foregroundColor: uiBase
            ]
        )

        let pattern = #"[A-Za-z][A-Za-z'-]{6,}"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return mutable
        }

        let nsContent = content as NSString
        for match in regex.matches(in: content, range: NSRange(location: 0, length: nsContent.length)) {
            let word = nsContent.substring(with: match.range).lowercased()
            guard shouldHighlight(word) else { continue }
            mutable.addAttribute(.foregroundColor, value: uiHighlight, range: match.range)
            mutable.addAttribute(.backgroundColor, value: uiHighlight.withAlphaComponent(0.18), range: match.range)
        }

        return mutable
    }

    static func plainNSAttributedString(for content: String, baseColor: Color) -> NSAttributedString {
        NSAttributedString(
            string: content,
            attributes: [
                .font: UIFont.systemFont(ofSize: 16, weight: .medium),
                .foregroundColor: UIColor(baseColor)
            ]
        )
    }

    static func word(at characterIndex: Int, in content: String) -> String? {
        guard let range = wordRange(at: characterIndex, in: content) else { return nil }
        let nsContent = content as NSString
        let raw = nsContent.substring(with: range)
        let cleaned = raw.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        return cleaned.count >= 2 ? cleaned : nil
    }

    static func wordRange(at characterIndex: Int, in content: String) -> NSRange? {
        let nsContent = content as NSString
        guard characterIndex >= 0, characterIndex < nsContent.length else { return nil }

        var start = characterIndex
        var end = characterIndex

        while start > 0, isWordCharacter(nsContent.character(at: start - 1)) {
            start -= 1
        }
        while end < nsContent.length, isWordCharacter(nsContent.character(at: end)) {
            end += 1
        }

        guard end > start else { return nil }
        return NSRange(location: start, length: end - start)
    }

    static func applyingSelectionHighlight(
        to base: NSAttributedString,
        range: NSRange?,
        highlightColor: UIColor
    ) -> NSAttributedString {
        guard let range,
              range.location != NSNotFound,
              range.length > 0,
              NSMaxRange(range) <= base.length else {
            return base
        }

        let mutable = NSMutableAttributedString(attributedString: base)
        mutable.addAttribute(.foregroundColor, value: highlightColor, range: range)
        mutable.addAttribute(
            .backgroundColor,
            value: highlightColor.withAlphaComponent(0.18),
            range: range
        )
        return mutable
    }

    private static func isWordCharacter(_ scalar: unichar) -> Bool {
        guard let scalar = UnicodeScalar(scalar) else { return false }
        return CharacterSet.alphanumerics.contains(scalar) || scalar == "-" || scalar == "'"
    }

    private static func shouldHighlight(_ word: String) -> Bool {
        let normalized = word.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        guard normalized.count >= 7 else { return false }
        return !commonWords.contains(normalized)
    }
}
