import Foundation
import FirebaseFirestore

protocol GrammarNoteServicing {
    func fetchNotes(ownerUID: String, topicId: String) async throws -> [GrammarNote]
    func createNote(_ note: GrammarNote) async throws
    func updateNote(_ note: GrammarNote) async throws
    func deleteNote(id: String, ownerUID: String, topicId: String) async throws
    func togglePinned(note: GrammarNote) async throws
    func toggleFavorite(note: GrammarNote) async throws
}

final class GrammarNoteService: GrammarNoteServicing {
    private let db = Firestore.firestore()

    func fetchNotes(ownerUID: String, topicId: String) async throws -> [GrammarNote] {
        let snapshot = try await notesCollection(ownerUID: ownerUID, topicId: topicId).getDocuments()
        let notes = snapshot.documents.compactMap { makeNote(from: $0) }
        return sortNotes(notes)
    }

    func createNote(_ note: GrammarNote) async throws {
        try await notesCollection(ownerUID: note.ownerUID, topicId: note.topicId)
            .document(note.id)
            .setData(dictionary(from: note), merge: true)

        try await updateTopicNotesCount(ownerUID: note.ownerUID, topicId: note.topicId, delta: 1)
    }

    func updateNote(_ note: GrammarNote) async throws {
        var updatedNote = note
        updatedNote.updatedAt = Date()

        try await notesCollection(ownerUID: updatedNote.ownerUID, topicId: updatedNote.topicId)
            .document(updatedNote.id)
            .setData(dictionary(from: updatedNote), merge: true)
    }

    func deleteNote(id: String, ownerUID: String, topicId: String) async throws {
        try await notesCollection(ownerUID: ownerUID, topicId: topicId)
            .document(id)
            .delete()

        try await updateTopicNotesCount(ownerUID: ownerUID, topicId: topicId, delta: -1)
    }

    func togglePinned(note: GrammarNote) async throws {
        var updatedNote = note
        updatedNote.isPinned.toggle()
        updatedNote.updatedAt = Date()
        try await updateNote(updatedNote)
    }

    func toggleFavorite(note: GrammarNote) async throws {
        var updatedNote = note
        updatedNote.isFavorite.toggle()
        updatedNote.updatedAt = Date()
        try await updateNote(updatedNote)
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

    private func makeNote(from document: QueryDocumentSnapshot) -> GrammarNote? {
        let data = document.data()

        guard
            let ownerUID = data["ownerUID"] as? String,
            let topicId = data["topicId"] as? String,
            let title = data["title"] as? String,
            let previewText = data["previewText"] as? String,
            let languageCode = data["languageCode"] as? String,
            let languageName = data["languageName"] as? String,
            let noteTypeRaw = data["noteType"] as? String,
            let noteType = GrammarNoteType(rawValue: noteTypeRaw),
            let tags = data["tags"] as? [String],
            let imageURLs = data["imageURLs"] as? [String],
            let isPinned = data["isPinned"] as? Bool,
            let isFavorite = data["isFavorite"] as? Bool,
            let isMistakeNote = data["isMistakeNote"] as? Bool,
            let hasQuiz = data["hasQuiz"] as? Bool
        else {
            return nil
        }

        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()

        return GrammarNote(
            id: document.documentID,
            ownerUID: ownerUID,
            topicId: topicId,
            title: title,
            previewText: previewText,
            languageCode: languageCode,
            languageName: languageName,
            noteType: noteType,
            tags: tags,
            imageURLs: imageURLs,
            isPinned: isPinned,
            isFavorite: isFavorite,
            isMistakeNote: isMistakeNote,
            hasQuiz: hasQuiz,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    private func dictionary(from note: GrammarNote) -> [String: Any] {
        [
            "ownerUID": note.ownerUID,
            "topicId": note.topicId,
            "title": note.title,
            "previewText": note.previewText,
            "languageCode": note.languageCode,
            "languageName": note.languageName,
            "noteType": note.noteType.rawValue,
            "tags": note.tags,
            "imageURLs": note.imageURLs,
            "isPinned": note.isPinned,
            "isFavorite": note.isFavorite,
            "isMistakeNote": note.isMistakeNote,
            "hasQuiz": note.hasQuiz,
            "createdAt": Timestamp(date: note.createdAt),
            "updatedAt": Timestamp(date: note.updatedAt)
        ]
    }

    private func sortNotes(_ notes: [GrammarNote]) -> [GrammarNote] {
        notes.sorted { lhs, rhs in
            if lhs.isPinned != rhs.isPinned { return lhs.isPinned && !rhs.isPinned }
            if lhs.isFavorite != rhs.isFavorite { return lhs.isFavorite && !rhs.isFavorite }
            return lhs.updatedAt > rhs.updatedAt
        }
    }
}

struct MockGrammarNoteService: GrammarNoteServicing {
    var notes: [GrammarNote] = []

    func fetchNotes(ownerUID: String, topicId: String) async throws -> [GrammarNote] { notes }
    func createNote(_ note: GrammarNote) async throws {}
    func updateNote(_ note: GrammarNote) async throws {}
    func deleteNote(id: String, ownerUID: String, topicId: String) async throws {}
    func togglePinned(note: GrammarNote) async throws {}
    func toggleFavorite(note: GrammarNote) async throws {}
}
