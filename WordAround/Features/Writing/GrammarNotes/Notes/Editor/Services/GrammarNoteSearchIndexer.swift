import Foundation

enum GrammarNoteSearchIndexer {

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

    static func matches(query: String, in searchableText: String) -> Bool {
        let q = normalize(query)
        guard !q.isEmpty else { return true }
        return searchableText.contains(q)
    }

    static func matchesFallback(query: String, note: GrammarNote) -> Bool {
        let blob = note.searchableText.isEmpty
            ? makeSearchableText(for: note)
            : note.searchableText
        return matches(query: query, in: blob)
    }

    static func snippet(for note: GrammarNote, query: String, maxLength: Int = 120) -> String? {
        let q = normalize(query)
        guard !q.isEmpty else { return nil }

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
