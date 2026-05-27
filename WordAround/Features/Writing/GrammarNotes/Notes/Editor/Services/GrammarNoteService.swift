import Foundation
import FirebaseFirestore

// MARK: - Protocol
protocol GrammarNoteServicing {
    func fetchNotes(ownerUID: String, topicId: String) async throws -> [GrammarNote]
    /// Lightweight fetch: returns notes without contentBlocks (for list/card display).
    func fetchNotePreviews(ownerUID: String, topicId: String, source: FirestoreSource) async throws -> [GrammarNote]
    /// Fetches a single fully-populated note (including contentBlocks).
    func fetchNote(id: String, ownerUID: String, topicId: String) async throws -> GrammarNote?
    func fetchNoteBySavedIssueKey(ownerUID: String, topicId: String, savedIssueKey: String) async throws -> GrammarNote?
    func createNote(_ note: GrammarNote) async throws
    /// Creates a note and returns it (useful when the caller needs the saved note for navigation).
    func createAndReturnNote(_ note: GrammarNote) async throws -> GrammarNote
    func updateNote(_ note: GrammarNote) async throws
    func uploadNoteImage(data: Data, ownerUID: String, topicId: String, noteId: String) async throws -> String
    func deleteNote(id: String, ownerUID: String, topicId: String) async throws
    func togglePinned(note: GrammarNote) async throws
    func toggleFavorite(note: GrammarNote) async throws
    /// Targeted single-field update — avoids writing the full document.
    func setNotePinned(id: String, ownerUID: String, topicId: String, isPinned: Bool) async throws
    func setNoteFavorite(id: String, ownerUID: String, topicId: String, isFavorite: Bool) async throws
    /// Targeted update for the denormalized search blob. Used for the
    /// one-shot backfill on old notes that were saved before the search
    /// indexer existed. Does NOT touch `updatedAt` so backfill writes
    /// stay invisible in lists sorted by recency.
    func setSearchableText(id: String, ownerUID: String, topicId: String, searchableText: String) async throws
}

extension GrammarNoteServicing {
    func fetchNotePreviews(ownerUID: String, topicId: String) async throws -> [GrammarNote] {
        try await fetchNotePreviews(ownerUID: ownerUID, topicId: topicId, source: .default)
    }
}

// MARK: - Live implementation
final class GrammarNoteService: GrammarNoteServicing {

    private let db = Firestore.firestore()

    // MARK: Fetch
    func fetchNotes(ownerUID: String, topicId: String) async throws -> [GrammarNote] {
        let snapshot = try await notesCollection(ownerUID: ownerUID, topicId: topicId).getDocuments()
        return sortNotes(snapshot.documents.compactMap(makeNote(from:)))
    }

    func fetchNotePreviews(ownerUID: String, topicId: String, source: FirestoreSource) async throws -> [GrammarNote] {
        let snapshot = try await notesCollection(ownerUID: ownerUID, topicId: topicId)
            .getDocuments(source: source)
        return sortNotes(snapshot.documents.compactMap(makeNotePreview(from:)))
    }

    func fetchNote(id: String, ownerUID: String, topicId: String) async throws -> GrammarNote? {
        let doc = try await notesCollection(ownerUID: ownerUID, topicId: topicId).document(id).getDocument()
        guard doc.exists, let data = doc.data() else { return nil }
        return makeNote(from: data, id: doc.documentID)
    }

    func fetchNoteBySavedIssueKey(ownerUID: String, topicId: String, savedIssueKey: String) async throws -> GrammarNote? {
        let snapshot = try await notesCollection(ownerUID: ownerUID, topicId: topicId)
            .whereField("savedIssueKey", isEqualTo: savedIssueKey)
            .limit(to: 1)
            .getDocuments()

        guard let document = snapshot.documents.first else { return nil }
        return makeNote(from: document)
    }

    // MARK: Create / Update
    func createNote(_ note: GrammarNote) async throws {
        try await writeNote(note)
        // Best-effort: the topic count is denormalized metadata. If the
        // counter update fails (e.g. topic doc missing, permission edge case,
        // transient error), the note is still saved correctly — we MUST NOT
        // rethrow here, or the caller will see "save failed" and retry,
        // creating a duplicate note. The list view auto-corrects the count
        // from the actual notes collection on next load.
        await bestEffortIncrementTopicNotesCount(
            ownerUID: note.ownerUID,
            topicId: note.topicId
        )
    }

    func createAndReturnNote(_ note: GrammarNote) async throws -> GrammarNote {
        try await createNote(note)
        return note
    }

    /// Full update — stamps `updatedAt` automatically.
    func updateNote(_ note: GrammarNote) async throws {
        var stamped = note
        stamped.updatedAt = Date()
        try await writeNote(stamped)
    }

    // MARK: Image upload (stub)
    func uploadNoteImage(data: Data, ownerUID: String, topicId: String, noteId: String) async throws -> String {
        // Intended path: users/{ownerUID}/grammarNotes/{topicId}/{noteId}/images/{imageId}.jpg
        throw NSError(
            domain: "GrammarNoteService",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "Image upload requires Firebase Storage integration."]
        )
    }

    // MARK: Delete
    func deleteNote(id: String, ownerUID: String, topicId: String) async throws {
        try await notesCollection(ownerUID: ownerUID, topicId: topicId).document(id).delete()
        // Best-effort decrement — see comment in `createNote`.
        await bestEffortDecrementTopicNotesCount(
            ownerUID: ownerUID,
            topicId: topicId
        )
    }

    // MARK: Toggle helpers (now use targeted field updates)
    func togglePinned(note: GrammarNote) async throws {
        try await setNotePinned(id: note.id, ownerUID: note.ownerUID, topicId: note.topicId, isPinned: !note.isPinned)
    }

    func toggleFavorite(note: GrammarNote) async throws {
        try await setNoteFavorite(id: note.id, ownerUID: note.ownerUID, topicId: note.topicId, isFavorite: !note.isFavorite)
    }

    func setNotePinned(id: String, ownerUID: String, topicId: String, isPinned: Bool) async throws {
        try await notesCollection(ownerUID: ownerUID, topicId: topicId).document(id).updateData([
            "isPinned": isPinned,
            "updatedAt": Timestamp(date: Date())
        ])
    }

    func setNoteFavorite(id: String, ownerUID: String, topicId: String, isFavorite: Bool) async throws {
        try await notesCollection(ownerUID: ownerUID, topicId: topicId).document(id).updateData([
            "isFavorite": isFavorite,
            "updatedAt": Timestamp(date: Date())
        ])
    }

    func setSearchableText(id: String, ownerUID: String, topicId: String, searchableText: String) async throws {
        // Single-field write — keeps backfills cheap and avoids touching
        // any other note metadata.
        try await notesCollection(ownerUID: ownerUID, topicId: topicId).document(id).updateData([
            "searchableText": searchableText
        ])
    }

    // MARK: - Private write helpers
    private func writeNote(_ note: GrammarNote) async throws {
        try await notesCollection(ownerUID: note.ownerUID, topicId: note.topicId)
            .document(note.id)
            .setData(dictionary(from: note), merge: true)
    }

    // MARK: - Firestore paths
    private func notesCollection(ownerUID: String, topicId: String) -> CollectionReference {
        db.collection("users")
            .document(ownerUID)
            .collection("grammarNoteTopics")
            .document(topicId)
            .collection("notes")
    }

    private func topicDocument(ownerUID: String, topicId: String) -> DocumentReference {
        db.collection("users")
            .document(ownerUID)
            .collection("grammarNoteTopics")
            .document(topicId)
    }

    private func updateTopicNotesCount(ownerUID: String, topicId: String, delta: Int64) async throws {
        try await topicDocument(ownerUID: ownerUID, topicId: topicId).updateData([
            "notesCount": FieldValue.increment(delta),
            "updatedAt": Timestamp(date: Date())
        ])
    }

    /// Best-effort topic counter update — swallows errors so a denormalized
    /// counter cannot fail an otherwise-successful note write. Errors are
    /// logged in DEBUG so the developer can still investigate.
    private func bestEffortIncrementTopicNotesCount(ownerUID: String, topicId: String) async {
        do {
            try await updateTopicNotesCount(ownerUID: ownerUID, topicId: topicId, delta: 1)
        } catch {
            #if DEBUG
            print("[GrammarNoteService] topic count increment failed for \(topicId):", error)
            #endif
        }
    }

    private func bestEffortDecrementTopicNotesCount(ownerUID: String, topicId: String) async {
        do {
            try await updateTopicNotesCount(ownerUID: ownerUID, topicId: topicId, delta: -1)
        } catch {
            #if DEBUG
            print("[GrammarNoteService] topic count decrement failed for \(topicId):", error)
            #endif
        }
    }

    // MARK: - Firestore ↔ Model mapping

    /// Full decode including contentBlocks — used when opening the editor.
    private func makeNote(from document: QueryDocumentSnapshot) -> GrammarNote? {
        makeNote(from: document.data(), id: document.documentID)
    }

    private func makeNote(from data: [String: Any], id: String) -> GrammarNote? {
        guard
            let ownerUID     = data["ownerUID"]     as? String,
            let topicId      = data["topicId"]      as? String,
            let title        = data["title"]        as? String,
            let languageCode = data["languageCode"] as? String,
            let languageName = data["languageName"] as? String,
            let noteTypeRaw  = data["noteType"]     as? String,
            let noteType     = GrammarNoteType(rawValue: noteTypeRaw)
        else { return nil }

        let previewText = data["previewText"] as? String ?? ""
        let updatedAt   = dateValue(data["updatedAt"]) ?? Date()

        return GrammarNote(
            id:               id,
            ownerUID:         ownerUID,
            topicId:          topicId,
            title:            title,
            previewText:      previewText,
            languageCode:     languageCode,
            languageName:     languageName,
            noteType:         noteType,
            tags:             data["tags"]             as? [String] ?? [],
            imageURLs:        data["imageURLs"]        as? [String] ?? [],
            isPinned:         data["isPinned"]         as? Bool ?? false,
            isFavorite:       data["isFavorite"]       as? Bool ?? false,
            isMistakeNote:    data["isMistakeNote"]    as? Bool ?? (noteType == .mistake),
            savedIssueKey:    data["savedIssueKey"]    as? String,
            hasQuiz:          data["hasQuiz"]          as? Bool ?? false,
            contentBlocks:    decodeBlocks(from: data["contentBlocks"]),
            plainTextContent: data["plainTextContent"] as? String ?? previewText,
            coverImageURL:    data["coverImageURL"]    as? String,
            localImagePaths:  data["localImagePaths"]  as? [String] ?? [],
            templateId:       data["templateId"]       as? String,
            createdAt:        dateValue(data["createdAt"])    ?? updatedAt,
            updatedAt:        updatedAt,
            lastEditedAt:     dateValue(data["lastEditedAt"]) ?? updatedAt,
            searchableText:   data["searchableText"]   as? String ?? ""
        )
    }

    /// Preview decode — skips contentBlocks for fast list display.
    private func makeNotePreview(from document: QueryDocumentSnapshot) -> GrammarNote? {
        let data = document.data()

        guard
            let ownerUID     = data["ownerUID"]     as? String,
            let topicId      = data["topicId"]      as? String,
            let title        = data["title"]        as? String,
            let languageCode = data["languageCode"] as? String,
            let languageName = data["languageName"] as? String,
            let noteTypeRaw  = data["noteType"]     as? String,
            let noteType     = GrammarNoteType(rawValue: noteTypeRaw)
        else { return nil }

        let previewText = data["previewText"] as? String ?? ""
        let updatedAt   = dateValue(data["updatedAt"]) ?? Date()

        return GrammarNote(
            id:               document.documentID,
            ownerUID:         ownerUID,
            topicId:          topicId,
            title:            title,
            previewText:      previewText,
            languageCode:     languageCode,
            languageName:     languageName,
            noteType:         noteType,
            tags:             data["tags"]          as? [String] ?? [],
            imageURLs:        [],
            isPinned:         data["isPinned"]      as? Bool ?? false,
            isFavorite:       data["isFavorite"]    as? Bool ?? false,
            isMistakeNote:    data["isMistakeNote"] as? Bool ?? (noteType == .mistake),
            savedIssueKey:    data["savedIssueKey"] as? String,
            hasQuiz:          data["hasQuiz"]       as? Bool ?? false,
            contentBlocks:    [],
            plainTextContent: data["plainTextContent"] as? String ?? previewText,
            coverImageURL:    nil,
            localImagePaths:  [],
            templateId:       nil,
            createdAt:        dateValue(data["createdAt"])    ?? updatedAt,
            updatedAt:        updatedAt,
            lastEditedAt:     dateValue(data["lastEditedAt"]) ?? updatedAt,
            // Preview docs persist `searchableText` so list search works
            // without ever fetching `contentBlocks` from Firestore.
            searchableText:   data["searchableText"] as? String ?? ""
        )
    }

    private func dictionary(from note: GrammarNote) -> [String: Any] {
        // If callers forgot to populate `searchableText`, build it now so we
        // never persist an empty index when the note has real content.
        let searchable = note.searchableText.isEmpty
            ? GrammarNoteSearchIndexer.makeSearchableText(for: note)
            : note.searchableText

        var data: [String: Any] = [
            "ownerUID":        note.ownerUID,
            "topicId":         note.topicId,
            "title":           note.title,
            "previewText":     note.previewText,
            "languageCode":    note.languageCode,
            "languageName":    note.languageName,
            "noteType":        note.noteType.rawValue,
            "tags":            note.tags,
            "imageURLs":       note.imageURLs,
            "isPinned":        note.isPinned,
            "isFavorite":      note.isFavorite,
            "isMistakeNote":   note.isMistakeNote,
            "hasQuiz":         note.hasQuiz,
            "contentBlocks":   note.contentBlocks.map { dictionary(from: $0) },
            "plainTextContent": note.plainTextContent,
            "searchableText":  searchable,
            "localImagePaths": note.localImagePaths,
            "createdAt":       Timestamp(date: note.createdAt),
            "updatedAt":       Timestamp(date: note.updatedAt),
            "lastEditedAt":    Timestamp(date: note.lastEditedAt)
        ]
        if let savedIssueKey = note.savedIssueKey { data["savedIssueKey"] = savedIssueKey }
        if let coverImageURL = note.coverImageURL { data["coverImageURL"] = coverImageURL }
        if let templateId    = note.templateId    { data["templateId"]    = templateId }
        return data
    }

    private func dictionary(from block: GrammarNoteBlock) -> [String: Any] {
        var data: [String: Any] = [
            "id":        block.id,
            "type":      block.type.rawValue,
            "text":      block.text,
            "items":     block.items,
            "order":     block.order,
            "createdAt": Timestamp(date: block.createdAt),
            "updatedAt": Timestamp(date: block.updatedAt)
        ]
        if let v = block.secondaryText { data["secondaryText"] = v }
        if let v = block.imageURL      { data["imageURL"]      = v }
        if let v = block.imageCaption  { data["imageCaption"]  = v }
        return data
    }

    private func decodeBlocks(from value: Any?) -> [GrammarNoteBlock] {
        guard let rawBlocks = value as? [[String: Any]] else { return [] }
        return rawBlocks
            .compactMap { data -> GrammarNoteBlock? in
                guard
                    let id      = data["id"]   as? String,
                    let typeRaw = data["type"] as? String,
                    let type    = GrammarNoteBlockType(rawValue: typeRaw)
                else { return nil }
                return GrammarNoteBlock(
                    id:            id,
                    type:          type,
                    text:          data["text"]         as? String ?? "",
                    secondaryText: data["secondaryText"] as? String,
                    imageURL:      data["imageURL"]      as? String,
                    imageCaption:  data["imageCaption"]  as? String,
                    items:         data["items"]         as? [String] ?? [],
                    order:         data["order"]         as? Int ?? 0,
                    createdAt:     dateValue(data["createdAt"]) ?? Date(),
                    updatedAt:     dateValue(data["updatedAt"]) ?? Date()
                )
            }
            .sorted { $0.order < $1.order }
    }

    private func dateValue(_ value: Any?) -> Date? {
        if let ts = value as? Timestamp { return ts.dateValue() }
        return value as? Date
    }

    private func sortNotes(_ notes: [GrammarNote]) -> [GrammarNote] {
        notes.sorted { lhs, rhs in
            if lhs.isPinned   != rhs.isPinned   { return lhs.isPinned   }
            if lhs.isFavorite != rhs.isFavorite { return lhs.isFavorite }
            return lhs.updatedAt > rhs.updatedAt
        }
    }
}

// MARK: - Mock
struct MockGrammarNoteService: GrammarNoteServicing {
    var notes: [GrammarNote] = []

    func fetchNotes(ownerUID: String, topicId: String) async throws -> [GrammarNote] { notes }
    func fetchNotePreviews(ownerUID: String, topicId: String, source: FirestoreSource) async throws -> [GrammarNote] { notes }
    func fetchNote(id: String, ownerUID: String, topicId: String) async throws -> GrammarNote? { notes.first { $0.id == id } }
    func fetchNoteBySavedIssueKey(ownerUID: String, topicId: String, savedIssueKey: String) async throws -> GrammarNote? { notes.first { $0.savedIssueKey == savedIssueKey } }
    func createNote(_ note: GrammarNote)                                   async throws {}
    func createAndReturnNote(_ note: GrammarNote)                          async throws -> GrammarNote { note }
    func updateNote(_ note: GrammarNote)                                   async throws {}
    func uploadNoteImage(data: Data, ownerUID: String, topicId: String, noteId: String) async throws -> String { "" }
    func deleteNote(id: String, ownerUID: String, topicId: String)         async throws {}
    func togglePinned(note: GrammarNote)                                   async throws {}
    func toggleFavorite(note: GrammarNote)                                 async throws {}
    func setNotePinned(id: String, ownerUID: String, topicId: String, isPinned: Bool)   async throws {}
    func setNoteFavorite(id: String, ownerUID: String, topicId: String, isFavorite: Bool) async throws {}
    func setSearchableText(id: String, ownerUID: String, topicId: String, searchableText: String) async throws {}
}
