import Foundation
import FirebaseFirestore

protocol GrammarNoteTopicServicing {
    func fetchTopics(for ownerUID: String) async throws -> [GrammarNoteTopic]
    func createTopic(_ topic: GrammarNoteTopic) async throws
    func updateTopic(_ topic: GrammarNoteTopic) async throws
    func deleteTopic(id: String, ownerUID: String) async throws
}

final class GrammarNoteTopicService: GrammarNoteTopicServicing {
    private let db = Firestore.firestore()

    func fetchTopics(for ownerUID: String) async throws -> [GrammarNoteTopic] {
        let snapshot = try await topicsCollection(ownerUID: ownerUID).getDocuments()

        let topics = snapshot.documents.compactMap { document -> GrammarNoteTopic? in
            makeTopic(from: document)
        }

        return sortTopics(topics)
    }

    func createTopic(_ topic: GrammarNoteTopic) async throws {
        try await topicsCollection(ownerUID: topic.ownerUID)
            .document(topic.id)
            .setData(dictionary(from: topic), merge: true)
    }

    func updateTopic(_ topic: GrammarNoteTopic) async throws {
        var updatedTopic = topic
        updatedTopic.updatedAt = Date()

        try await topicsCollection(ownerUID: updatedTopic.ownerUID)
            .document(updatedTopic.id)
            .setData(dictionary(from: updatedTopic), merge: true)
    }

    func deleteTopic(id: String, ownerUID: String) async throws {
        try await topicsCollection(ownerUID: ownerUID)
            .document(id)
            .delete()
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
            updatedAt: updatedAt
        )
    }

    private func dictionary(from topic: GrammarNoteTopic) -> [String: Any] {
        [
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
    }

    private func sortTopics(_ topics: [GrammarNoteTopic]) -> [GrammarNoteTopic] {
        topics.sorted { lhs, rhs in
            if lhs.isPinned != rhs.isPinned {
                return lhs.isPinned && !rhs.isPinned
            }

            if lhs.isMistakesTopic != rhs.isMistakesTopic {
                return lhs.isMistakesTopic && !rhs.isMistakesTopic
            }

            return lhs.updatedAt > rhs.updatedAt
        }
    }
}

struct MockGrammarNoteTopicService: GrammarNoteTopicServicing {
    var topics: [GrammarNoteTopic] = []

    func fetchTopics(for ownerUID: String) async throws -> [GrammarNoteTopic] {
        topics
    }

    func createTopic(_ topic: GrammarNoteTopic) async throws {}
    func updateTopic(_ topic: GrammarNoteTopic) async throws {}
    func deleteTopic(id: String, ownerUID: String) async throws {}
}
