import Foundation

/// Static helper that builds the denormalized `searchableText` blob stored on
/// every `GrammarNote`. Search runs entirely against this string locally:
/// no Firestore reads per keystroke, no full-text index, no listeners.
///
/// Normalization rules (kept intentionally simple):
///  - lower-cased
///  - whitespace/newlines collapsed
///  - diacritics folded so `está` matches `esta`
///
/// All call sites that create or save a note MUST call
/// `makeSearchableText(...)` so the field never goes stale. Old documents
/// missing the field still work — the topic VM falls back to title +
/// preview + tags at filter time.
enum GrammarNoteSearchIndexer {

    // MARK: - Build

    /// Builds the denormalized search blob from the canonical fields. Used
    /// at every note creation/update site so the stored field always
    /// matches the latest content.
    static func makeSearchableText(
        title: String,
        previewText: String,
        tags: [String],
        noteType: GrammarNoteType,
        blocks: [GrammarNoteBlock],
        plainTextContent: String = ""
    ) -> String {
        var parts: [String] = []
        parts.append(title)
        parts.append(previewText)
        parts.append(noteType.title)
        parts.append(contentsOf: tags)
        parts.append(plainTextContent)

        for block in blocks {
            parts.append(block.text)
            if let s = block.secondaryText { parts.append(s) }
            parts.append(contentsOf: block.items)
            if let c = block.imageCaption { parts.append(c) }
        }

        let joined = parts
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        return normalize(joined)
    }

    /// Convenience: rebuilds the searchable text from a fully-populated note.
    static func makeSearchableText(for note: GrammarNote) -> String {
        makeSearchableText(
            title: note.title,
            previewText: note.previewText,
            tags: note.tags,
            noteType: note.noteType,
            blocks: note.contentBlocks,
            plainTextContent: note.plainTextContent
        )
    }

    // MARK: - Match

    /// Returns `true` if the (already-normalized) `searchableText` contains
    /// the query. Pass an empty query to short-circuit to `true`.
    static func matches(query: String, in searchableText: String) -> Bool {
        let q = normalize(query)
        guard !q.isEmpty else { return true }
        return searchableText.contains(q)
    }

    /// Fallback matcher for old notes that don't have `searchableText`
    /// stored yet. Builds the index on-the-fly so search still works for
    /// legacy documents without a backfill round-trip.
    static func matchesFallback(query: String, note: GrammarNote) -> Bool {
        let blob = note.searchableText.isEmpty
            ? makeSearchableText(for: note)
            : note.searchableText
        return matches(query: query, in: blob)
    }

    // MARK: - Snippet

    /// Produces a short snippet around the first match of `query` in the
    /// note's content. Returns `nil` when no match is found, the query is
    /// empty, or the matched text is too generic (title/tag only — those
    /// are already shown on the card).
    static func snippet(for note: GrammarNote, query: String, maxLength: Int = 120) -> String? {
        let q = normalize(query)
        guard !q.isEmpty else { return nil }

        // Iterate the same fields we index, but in their RAW form so we can
        // present the user a sentence with original casing/accents.
        var sources: [String] = []
        sources.append(note.plainTextContent)
        for block in note.contentBlocks {
            sources.append(block.text)
            if let s = block.secondaryText { sources.append(s) }
            sources.append(contentsOf: block.items)
            if let c = block.imageCaption { sources.append(c) }
        }
        sources.append(note.previewText)

        for source in sources {
            let trimmed = source.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            let normalizedSource = normalize(trimmed)
            guard let range = normalizedSource.range(of: q) else { continue }

            // Map the match index back to the raw string. Diacritic folding
            // can change string length, so we approximate by offset only.
            let startOffset = max(0, normalizedSource.distance(from: normalizedSource.startIndex, to: range.lowerBound) - 30)
            let rawStart = trimmed.index(
                trimmed.startIndex,
                offsetBy: min(startOffset, trimmed.count)
            )
            let endOffset = min(trimmed.count, startOffset + maxLength)
            let rawEnd = trimmed.index(trimmed.startIndex, offsetBy: endOffset)
            var snippet = String(trimmed[rawStart..<rawEnd])

            if rawStart > trimmed.startIndex { snippet = "…" + snippet }
            if rawEnd < trimmed.endIndex     { snippet = snippet + "…" }
            return snippet
        }
        return nil
    }

    // MARK: - Normalization

    /// Lower-cases, folds diacritics, and collapses whitespace runs.
    /// Used both when building the stored blob and when comparing queries
    /// so the two sides always speak the same shape.
    static func normalize(_ value: String) -> String {
        let folded = value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil)
        let collapsed = folded
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        return collapsed
    }
}
