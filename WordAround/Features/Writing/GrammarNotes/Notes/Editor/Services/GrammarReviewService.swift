import Foundation
import FirebaseFirestore

protocol GrammarReviewServicing: Sendable {
    func fetchDueReviewItems(ownerUID: String, limit: Int) async throws -> [GrammarReviewItem]
    func fetchDueSummary(ownerUID: String) async throws -> GrammarReviewSummary
    func fetchItemsBySource(
        ownerUID: String,
        sourceType: GrammarReviewSourceType,
        limit: Int
    ) async throws -> [GrammarReviewItem]
    func createOrUpdateReviewItem(_ item: GrammarReviewItem) async throws
    func markReviewed(item: GrammarReviewItem, result: GrammarReviewResult) async throws -> GrammarReviewItem
    func deleteReviewItem(id: String, ownerUID: String) async throws
}

struct GrammarReviewSummary: Equatable {
    var dueTotal: Int = 0
    var dueNotes: Int = 0
    var dueMistakes: Int = 0
    var dueQuizzes: Int = 0

    static let empty = GrammarReviewSummary()

    static func from(items: [GrammarReviewItem]) -> GrammarReviewSummary {
        var summary = GrammarReviewSummary()
        summary.dueTotal = items.count
        for item in items {
            switch item.sourceType {
            case .note:    summary.dueNotes    += 1
            case .mistake: summary.dueMistakes += 1
            case .quiz:    summary.dueQuizzes  += 1
            }
        }
        return summary
    }
}

final class GrammarReviewService: GrammarReviewServicing, @unchecked Sendable {

    private let db = Firestore.firestore()

    func fetchDueReviewItems(ownerUID: String, limit: Int) async throws -> [GrammarReviewItem] {
        let snapshot = try await reviewCollection(ownerUID: ownerUID)
            .whereField("dueAt", isLessThanOrEqualTo: Timestamp(date: Date()))
            .order(by: "dueAt", descending: false)
            .limit(to: max(1, limit))
            .getDocuments()
        return snapshot.documents.compactMap { makeItem(from: $0.data(), id: $0.documentID) }
    }

    func fetchItemsBySource(
        ownerUID: String,
        sourceType: GrammarReviewSourceType,
        limit: Int
    ) async throws -> [GrammarReviewItem] {
        let snapshot = try await reviewCollection(ownerUID: ownerUID)
            .whereField("sourceType", isEqualTo: sourceType.rawValue)
            .order(by: "updatedAt", descending: true)
            .limit(to: max(1, limit))
            .getDocuments()
        return snapshot.documents.compactMap { makeItem(from: $0.data(), id: $0.documentID) }
    }

    func fetchDueSummary(ownerUID: String) async throws -> GrammarReviewSummary {
        let snapshot = try await reviewCollection(ownerUID: ownerUID)
            .whereField("dueAt", isLessThanOrEqualTo: Timestamp(date: Date()))
            .order(by: "dueAt", descending: false)
            .limit(to: 100)
            .getDocuments()
        let items = snapshot.documents.compactMap { makeItem(from: $0.data(), id: $0.documentID) }
        return GrammarReviewSummary.from(items: items)
    }

    func createOrUpdateReviewItem(_ item: GrammarReviewItem) async throws {
        let document = reviewCollection(ownerUID: item.ownerUID).document(item.id)
        let snapshot = try await document.getDocument()

        var itemToWrite = item

        if snapshot.exists,
           let data = snapshot.data(),
           let existing = makeItem(from: data, id: snapshot.documentID) {
            itemToWrite.reviewCount = existing.reviewCount
            itemToWrite.correctStreak = existing.correctStreak
            itemToWrite.incorrectStreak = existing.incorrectStreak
            itemToWrite.mistakeCount = existing.mistakeCount
            itemToWrite.lastReviewedAt = existing.lastReviewedAt
            itemToWrite.nextReviewAt = existing.nextReviewAt
            itemToWrite.createdAt = existing.createdAt
        }

        try await document.setData(dictionary(from: itemToWrite), merge: true)
    }

    func markReviewed(
        item: GrammarReviewItem,
        result: GrammarReviewResult
    ) async throws -> GrammarReviewItem {
        let updated = item.applying(result: result)
        try await createOrUpdateReviewItem(updated)
        return updated
    }

    func deleteReviewItem(id: String, ownerUID: String) async throws {
        try await reviewCollection(ownerUID: ownerUID).document(id).delete()
    }

    private func reviewCollection(ownerUID: String) -> CollectionReference {
        db.collection("users").document(ownerUID).collection("grammarReviewItems")
    }

    private func dictionary(from item: GrammarReviewItem) -> [String: Any] {
        var data: [String: Any] = [
            "ownerUID":         item.ownerUID,
            "sourceType":       item.sourceType.rawValue,
            "topicId":          item.topicId,
            "title":            item.title,
            "previewText":      item.previewText,
            "languageCode":     item.languageCode,
            "languageName":     item.languageName,
            "priority":         item.priority.rawValue,
            "dueAt":            Timestamp(date: item.dueAt),
            "reviewCount":      item.reviewCount,
            "correctStreak":    item.correctStreak,
            "incorrectStreak":  item.incorrectStreak,
            "mistakeCount":     item.mistakeCount,
            "createdAt":        Timestamp(date: item.createdAt),
            "updatedAt":        Timestamp(date: item.updatedAt)
        ]
        if let noteId         = item.noteId         { data["noteId"]         = noteId }
        if let quizId         = item.quizId         { data["quizId"]         = quizId }
        if let lastReviewedAt = item.lastReviewedAt { data["lastReviewedAt"] = Timestamp(date: lastReviewedAt) }
        if let nextReviewAt   = item.nextReviewAt   { data["nextReviewAt"]   = Timestamp(date: nextReviewAt)   }
        return data
    }

    private func makeItem(from data: [String: Any], id: String) -> GrammarReviewItem? {
        guard
            let ownerUID    = data["ownerUID"]    as? String,
            let typeRaw     = data["sourceType"]  as? String,
            let sourceType  = GrammarReviewSourceType(rawValue: typeRaw),
            let topicId     = data["topicId"]     as? String,
            let title       = data["title"]       as? String
        else { return nil }

        return GrammarReviewItem(
            id: id,
            ownerUID: ownerUID,
            sourceType: sourceType,
            topicId: topicId,
            noteId: data["noteId"] as? String,
            quizId: data["quizId"] as? String,
            title: title,
            previewText:   data["previewText"]   as? String ?? "",
            languageCode:  data["languageCode"]  as? String ?? "",
            languageName:  data["languageName"]  as? String ?? "",
            priority:      (data["priority"] as? String).flatMap(GrammarReviewPriority.init(rawValue:)) ?? .normal,
            dueAt:         dateValue(data["dueAt"]) ?? Date(),
            lastReviewedAt: dateValue(data["lastReviewedAt"]),
            nextReviewAt:  dateValue(data["nextReviewAt"]),
            reviewCount:   data["reviewCount"]      as? Int ?? 0,
            correctStreak: data["correctStreak"]    as? Int ?? 0,
            incorrectStreak: data["incorrectStreak"] as? Int ?? 0,
            mistakeCount:  data["mistakeCount"]     as? Int ?? 0,
            createdAt:     dateValue(data["createdAt"]) ?? Date(),
            updatedAt:     dateValue(data["updatedAt"]) ?? Date()
        )
    }

    private func dateValue(_ value: Any?) -> Date? {
        if let ts = value as? Timestamp { return ts.dateValue() }
        return value as? Date
    }
}

struct MockGrammarReviewService: GrammarReviewServicing, @unchecked Sendable {
    var items: [GrammarReviewItem] = []

    func fetchDueReviewItems(ownerUID: String, limit: Int) async throws -> [GrammarReviewItem] {
        Array(items.prefix(limit))
    }
    func fetchDueSummary(ownerUID: String) async throws -> GrammarReviewSummary {
        GrammarReviewSummary.from(items: items)
    }
    func fetchItemsBySource(
        ownerUID: String,
        sourceType: GrammarReviewSourceType,
        limit: Int
    ) async throws -> [GrammarReviewItem] {
        Array(items.filter { $0.sourceType == sourceType }.prefix(limit))
    }
    func createOrUpdateReviewItem(_ item: GrammarReviewItem) async throws {}
    func markReviewed(item: GrammarReviewItem, result: GrammarReviewResult) async throws -> GrammarReviewItem {
        item.applying(result: result)
    }
    func deleteReviewItem(id: String, ownerUID: String) async throws {}
}
