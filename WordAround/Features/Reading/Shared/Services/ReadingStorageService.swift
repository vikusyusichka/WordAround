import Foundation
import FirebaseFirestore

/// Persistence for Reading mode libraries. Items live per user in Firestore and
/// are always scoped by `modeID`, so a mode's library never mixes content.
///
/// Mirrors the existing `FlashcardSetService` / `GrammarNoteService` conventions:
/// `users/{userId}/readingItems/{id}`, Codable mapping via `setData(from:)` /
/// `data(as:)`, `Timestamp`↔`Date`, async/await, and a `Mock` for previews.
protocol ReadingStorageServicing {
    func fetchItems(for userId: String, mode: ReadingMode) async throws -> [ReadingLibraryItem]
    func saveItem(_ item: ReadingLibraryItem, for userId: String) async throws
    func updateItem(_ item: ReadingLibraryItem, for userId: String) async throws
    func deleteItem(_ item: ReadingLibraryItem, for userId: String) async throws
    func updateProgress(itemId: String, mode: ReadingMode, progress: Double, for userId: String) async throws
    func updateLastOpened(itemId: String, mode: ReadingMode, for userId: String) async throws
}

// MARK: - Live (Firestore)

final class ReadingStorageService: ReadingStorageServicing {

    private let db = Firestore.firestore()

    private func collection(_ userId: String) -> CollectionReference {
        db.collection("users").document(userId).collection("readingItems")
    }

    func fetchItems(for userId: String, mode: ReadingMode) async throws -> [ReadingLibraryItem] {
        // Filter by mode in Firestore; sort locally so an optional `lastOpenedAt`
        // ordering never requires a composite index or drops fieldless docs.
        let snapshot = try await collection(userId)
            .whereField("modeID", isEqualTo: mode.id)
            .getDocuments()

        let items = snapshot.documents.compactMap { try? $0.data(as: ReadingLibraryItem.self) }
        return Self.sorted(items)
    }

    func saveItem(_ item: ReadingLibraryItem, for userId: String) async throws {
        try collection(userId).document(item.id).setData(from: item)
    }

    func updateItem(_ item: ReadingLibraryItem, for userId: String) async throws {
        var updated = item
        updated.updatedAt = Date()
        try collection(userId).document(item.id).setData(from: updated, merge: true)
    }

    func deleteItem(_ item: ReadingLibraryItem, for userId: String) async throws {
        try await collection(userId).document(item.id).delete()
    }

    func updateProgress(itemId: String, mode: ReadingMode, progress: Double, for userId: String) async throws {
        let clamped = min(max(progress, 0), 1)
        try await collection(userId).document(itemId).updateData([
            "progress": clamped,
            "status": ReadingLibraryItem.status(forProgress: clamped).rawValue,
            "lastOpenedAt": Timestamp(date: Date()),
            "updatedAt": Timestamp(date: Date())
        ])
    }

    func updateLastOpened(itemId: String, mode: ReadingMode, for userId: String) async throws {
        try await collection(userId).document(itemId).updateData([
            "lastOpenedAt": Timestamp(date: Date())
        ])
    }

    /// lastOpenedAt desc → updatedAt desc → createdAt desc.
    static func sorted(_ items: [ReadingLibraryItem]) -> [ReadingLibraryItem] {
        items.sorted { lhs, rhs in
            let l = lhs.lastOpenedAt ?? lhs.updatedAt
            let r = rhs.lastOpenedAt ?? rhs.updatedAt
            if l != r { return l > r }
            if lhs.updatedAt != rhs.updatedAt { return lhs.updatedAt > rhs.updatedAt }
            return lhs.createdAt > rhs.createdAt
        }
    }
}

// MARK: - Mock (previews / tests, no Firebase)

final class MockReadingStorageService: ReadingStorageServicing {
    private var items: [ReadingLibraryItem]

    init(items: [ReadingLibraryItem] = []) {
        self.items = items
    }

    func fetchItems(for userId: String, mode: ReadingMode) async throws -> [ReadingLibraryItem] {
        ReadingStorageService.sorted(items.filter { $0.modeID == mode.id })
    }

    func saveItem(_ item: ReadingLibraryItem, for userId: String) async throws {
        items.removeAll { $0.id == item.id }
        items.append(item)
    }

    func updateItem(_ item: ReadingLibraryItem, for userId: String) async throws {
        if let i = items.firstIndex(where: { $0.id == item.id }) { items[i] = item }
    }

    func deleteItem(_ item: ReadingLibraryItem, for userId: String) async throws {
        items.removeAll { $0.id == item.id }
    }

    func updateProgress(itemId: String, mode: ReadingMode, progress: Double, for userId: String) async throws {
        guard let i = items.firstIndex(where: { $0.id == itemId }) else { return }
        items[i].progress = min(max(progress, 0), 1)
        items[i].status = ReadingLibraryItem.status(forProgress: items[i].progress)
        items[i].lastOpenedAt = Date()
    }

    func updateLastOpened(itemId: String, mode: ReadingMode, for userId: String) async throws {
        guard let i = items.firstIndex(where: { $0.id == itemId }) else { return }
        items[i].lastOpenedAt = Date()
    }
}
