import Foundation
import FirebaseFirestore

protocol GrammarNoteServicing {
    func fetchNotes(ownerUID: String, topicId: String) async throws -> [GrammarNote]
    func fetchNotePreviews(ownerUID: String, topicId: String, source: FirestoreSource) async throws -> [GrammarNote]
    func fetchNote(id: String, ownerUID: String, topicId: String) async throws -> GrammarNote?
    func fetchNoteBySavedIssueKey(ownerUID: String, topicId: String, savedIssueKey: String) async throws -> GrammarNote?
    func createNote(_ note: GrammarNote) async throws
    func createAndReturnNote(_ note: GrammarNote) async throws -> GrammarNote
    func updateNote(_ note: GrammarNote) async throws
    func uploadNoteImage(data: Data, ownerUID: String, topicId: String, noteId: String) async throws -> String
    func deleteNote(id: String, ownerUID: String, topicId: String) async throws
    func togglePinned(note: GrammarNote) async throws
    func toggleFavorite(note: GrammarNote) async throws
    func setNotePinned(id: String, ownerUID: String, topicId: String, isPinned: Bool) async throws
    func setNoteFavorite(id: String, ownerUID: String, topicId: String, isFavorite: Bool) async throws
    func setSearchableText(id: String, ownerUID: String, topicId: String, searchableText: String) async throws
    func updateNoteSortIndices(
        ownerUID: String,
        topicId: String,
        indices: [(id: String, sortIndex: Int)]
    ) async throws
    func setNoteRecentlyOpenedAt(
        id: String,
        ownerUID: String,
        topicId: String,
        openedAt: Date
    ) async throws
}

extension GrammarNoteServicing {
    func fetchNotePreviews(ownerUID: String, topicId: String) async throws -> [GrammarNote] {
        try await fetchNotePreviews(ownerUID: ownerUID, topicId: topicId, source: .default)
    }
}

final class GrammarNoteService: GrammarNoteServicing {

    private let db = Firestore.firestore()

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

    func createNote(_ note: GrammarNote) async throws {
        try await writeNote(note)
        await bestEffortIncrementTopicNotesCount(
            ownerUID: note.ownerUID,
            topicId: note.topicId
        )
    }

    func createAndReturnNote(_ note: GrammarNote) async throws -> GrammarNote {
        try await createNote(note)
        return note
    }

    func updateNote(_ note: GrammarNote) async throws {
        var stamped = note
        stamped.updatedAt = Date()
        try await writeNote(stamped)
    }

    func uploadNoteImage(data: Data, ownerUID: String, topicId: String, noteId: String) async throws -> String {
        throw NSError(
            domain: "GrammarNoteService",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "Image upload requires Firebase Storage integration."]
        )
    }

    func deleteNote(id: String, ownerUID: String, topicId: String) async throws {
        try await notesCollection(ownerUID: ownerUID, topicId: topicId).document(id).delete()
        await bestEffortDecrementTopicNotesCount(
            ownerUID: ownerUID,
            topicId: topicId
        )
    }

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
        try await notesCollection(ownerUID: ownerUID, topicId: topicId).document(id).updateData([
            "searchableText": searchableText
        ])
    }

    func updateNoteSortIndices(
        ownerUID: String,
        topicId: String,
        indices: [(id: String, sortIndex: Int)]
    ) async throws {
        guard !indices.isEmpty else { return }
        let collection = notesCollection(ownerUID: ownerUID, topicId: topicId)
        let batch = db.batch()
        for entry in indices {
            batch.updateData(
                ["sortIndex": entry.sortIndex],
                forDocument: collection.document(entry.id)
            )
        }
        try await batch.commit()
    }

    func setNoteRecentlyOpenedAt(
        id: String,
        ownerUID: String,
        topicId: String,
        openedAt: Date
    ) async throws {
        try await notesCollection(ownerUID: ownerUID, topicId: topicId).document(id).updateData([
            "recentlyOpenedAt": Timestamp(date: openedAt)
        ])
    }

    private func writeNote(_ note: GrammarNote) async throws {
        try await notesCollection(ownerUID: note.ownerUID, topicId: note.topicId)
            .document(note.id)
            .setData(dictionary(from: note), merge: true)
    }

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
            searchableText:   data["searchableText"]   as? String ?? "",
            sortIndex:        data["sortIndex"]        as? Int,
            recentlyOpenedAt: dateValue(data["recentlyOpenedAt"])
        )
    }

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
            searchableText:   data["searchableText"] as? String ?? "",
            sortIndex:        data["sortIndex"]     as? Int,
            recentlyOpenedAt: dateValue(data["recentlyOpenedAt"])
        )
    }

    private func dictionary(from note: GrammarNote) -> [String: Any] {
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
        if let savedIssueKey    = note.savedIssueKey    { data["savedIssueKey"]    = savedIssueKey }
        if let coverImageURL    = note.coverImageURL    { data["coverImageURL"]    = coverImageURL }
        if let templateId       = note.templateId       { data["templateId"]       = templateId }
        if let sortIndex        = note.sortIndex        { data["sortIndex"]        = sortIndex }
        if let recentlyOpenedAt = note.recentlyOpenedAt { data["recentlyOpenedAt"] = Timestamp(date: recentlyOpenedAt) }
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
            switch (lhs.sortIndex, rhs.sortIndex) {
            case let (l?, r?):
                if l != r { return l < r }
                return lhs.updatedAt > rhs.updatedAt
            case (nil, nil): return lhs.updatedAt > rhs.updatedAt
            case (_?, nil):  return false
            case (nil, _?):  return true
            }
        }
    }
}

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
    func updateNoteSortIndices(ownerUID: String, topicId: String, indices: [(id: String, sortIndex: Int)]) async throws {}
    func setNoteRecentlyOpenedAt(id: String, ownerUID: String, topicId: String, openedAt: Date) async throws {}
}
