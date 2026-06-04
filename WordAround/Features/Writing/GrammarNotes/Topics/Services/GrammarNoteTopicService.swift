import Foundation
import FirebaseFirestore

protocol GrammarNoteTopicServicing {
    func fetchTopics(for ownerUID: String) async throws -> [GrammarNoteTopic]
    func fetchTopics(for ownerUID: String, source: FirestoreSource) async throws -> [GrammarNoteTopic]
    func createTopic(_ topic: GrammarNoteTopic) async throws
    func ensureDefaultMistakesTopic(ownerUID: String) async throws -> GrammarNoteTopic
    func updateTopic(_ topic: GrammarNoteTopic) async throws
    func deleteTopic(id: String, ownerUID: String) async throws
    func updateTopicSortIndices(ownerUID: String, indices: [(id: String, sortIndex: Int)]) async throws
}

extension GrammarNoteTopicServicing {
    func fetchTopics(for ownerUID: String) async throws -> [GrammarNoteTopic] {
        try await fetchTopics(for: ownerUID, source: .default)
    }
}

final class GrammarNoteTopicService: GrammarNoteTopicServicing {
    private let db = Firestore.firestore()

    func fetchTopics(for ownerUID: String, source: FirestoreSource) async throws -> [GrammarNoteTopic] {
        let snapshot = try await topicsCollection(ownerUID: ownerUID).getDocuments(source: source)
        return sortTopics(snapshot.documents.compactMap(makeTopic(from:)))
    }

    func createTopic(_ topic: GrammarNoteTopic) async throws {
        try await topicsCollection(ownerUID: topic.ownerUID)
            .document(topic.id)
            .setData(dictionary(from: topic), merge: true)
    }

    func ensureDefaultMistakesTopic(ownerUID: String) async throws -> GrammarNoteTopic {
        let existingTopics = try await fetchTopics(for: ownerUID, source: .default)
        if let existing = existingTopics.first(where: { $0.isMistakesTopic }) {
            return existing
        }

        let topic = GrammarNoteTopic.commonMistakes(ownerUID: ownerUID)
        try await createTopic(topic)
        return topic
    }

    func updateTopic(_ topic: GrammarNoteTopic) async throws {
        var updatedTopic = topic
        updatedTopic.updatedAt = Date()

        try await topicsCollection(ownerUID: updatedTopic.ownerUID)
            .document(updatedTopic.id)
            .setData(dictionary(from: updatedTopic), merge: true)
    }

    func deleteTopic(id: String, ownerUID: String) async throws {
        let topicRef = topicsCollection(ownerUID: ownerUID).document(id)
        let notesRef = topicRef.collection("notes")

        let notesSnapshot = try await notesRef.getDocuments()
        for noteDoc in notesSnapshot.documents {
            let quizzesSnapshot = try await noteDoc.reference
                .collection("quizzes")
                .getDocuments()
            try await deleteDocuments(quizzesSnapshot.documents.map { $0.reference })
            try await noteDoc.reference.delete()
        }

        try await topicRef.delete()
    }

    private func deleteDocuments(_ refs: [DocumentReference]) async throws {
        guard !refs.isEmpty else { return }
        let chunkSize = 400
        var index = 0
        while index < refs.count {
            let end = min(index + chunkSize, refs.count)
            let batch = db.batch()
            for ref in refs[index..<end] {
                batch.deleteDocument(ref)
            }
            try await batch.commit()
            index = end
        }
    }

    func updateTopicSortIndices(
        ownerUID: String,
        indices: [(id: String, sortIndex: Int)]
    ) async throws {
        guard !indices.isEmpty else { return }
        let collection = topicsCollection(ownerUID: ownerUID)
        let batch = db.batch()
        for entry in indices {
            batch.updateData(
                ["sortIndex": entry.sortIndex],
                forDocument: collection.document(entry.id)
            )
        }
        try await batch.commit()
    }

    private func topicsCollection(ownerUID: String) -> CollectionReference {
        db.collection("users")
            .document(ownerUID)
            .collection("grammarNoteTopics")
    }

    private func makeTopic(from document: QueryDocumentSnapshot) -> GrammarNoteTopic? {
        let data = document.data()

        guard
            let ownerUID = data["ownerUID"] as? String,
            let title = data["title"] as? String,
            let description = data["description"] as? String,
            let languageCode = data["languageCode"] as? String,
            let languageName = data["languageName"] as? String,
            let icon = data["icon"] as? String,
            let colorHex = data["colorHex"] as? String,
            let notesCount = data["notesCount"] as? Int,
            let isPinned = data["isPinned"] as? Bool,
            let isMistakesTopic = data["isMistakesTopic"] as? Bool
        else {
            return nil
        }

        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
        let sortIndex = data["sortIndex"] as? Int

        return GrammarNoteTopic(
            id: document.documentID,
            ownerUID: ownerUID,
            title: title,
            description: description,
            languageCode: languageCode,
            languageName: languageName,
            icon: icon,
            colorHex: colorHex,
            notesCount: notesCount,
            isPinned: isPinned,
            isMistakesTopic: isMistakesTopic,
            createdAt: createdAt,
            updatedAt: updatedAt,
            sortIndex: sortIndex
        )
    }

    private func dictionary(from topic: GrammarNoteTopic) -> [String: Any] {
        var data: [String: Any] = [
            "ownerUID": topic.ownerUID,
            "title": topic.title,
            "description": topic.description,
            "languageCode": topic.languageCode,
            "languageName": topic.languageName,
            "icon": topic.icon,
            "colorHex": topic.colorHex,
            "notesCount": topic.notesCount,
            "isPinned": topic.isPinned,
            "isMistakesTopic": topic.isMistakesTopic,
            "createdAt": Timestamp(date: topic.createdAt),
            "updatedAt": Timestamp(date: topic.updatedAt)
        ]
        if let sortIndex = topic.sortIndex {
            data["sortIndex"] = sortIndex
        }
        return data
    }

    private func sortTopics(_ topics: [GrammarNoteTopic]) -> [GrammarNoteTopic] {
        topics.sorted { lhs, rhs in
            if lhs.isPinned != rhs.isPinned {
                return lhs.isPinned && !rhs.isPinned
            }

            if lhs.isMistakesTopic != rhs.isMistakesTopic {
                return lhs.isMistakesTopic && !rhs.isMistakesTopic
            }

            switch (lhs.sortIndex, rhs.sortIndex) {
            case let (l?, r?):
                if l != r { return l < r }
                return lhs.updatedAt > rhs.updatedAt
            case (nil, nil):
                return lhs.updatedAt > rhs.updatedAt
            case (_?, nil):
                return false
            case (nil, _?):
                return true
            }
        }
    }
}

struct MockGrammarNoteTopicService: GrammarNoteTopicServicing {
    var topics: [GrammarNoteTopic] = []

    func fetchTopics(for ownerUID: String, source: FirestoreSource) async throws -> [GrammarNoteTopic] { topics }
    func createTopic(_ topic: GrammarNoteTopic) async throws {}
    func ensureDefaultMistakesTopic(ownerUID: String) async throws -> GrammarNoteTopic {
        topics.first(where: { $0.isMistakesTopic }) ?? GrammarNoteTopic.commonMistakes(ownerUID: ownerUID)
    }
    func updateTopic(_ topic: GrammarNoteTopic) async throws {}
    func deleteTopic(id: String, ownerUID: String) async throws {}
    func updateTopicSortIndices(ownerUID: String, indices: [(id: String, sortIndex: Int)]) async throws {}
}
