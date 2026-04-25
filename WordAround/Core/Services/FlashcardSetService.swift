import Foundation
import FirebaseFirestore

final class FlashcardSetService {
    private let db = Firestore.firestore()

    func createSet(_ set: FlashcardSet) async throws {
        try db
            .collection("users")
            .document(set.ownerUID)
            .collection("flashcardSets")
            .document(set.id)
            .setData(from: set)
    }

    func fetchSets(for uid: String) async throws -> [FlashcardSet] {
        let snapshot = try await db
            .collection("users")
            .document(uid)
            .collection("flashcardSets")
            .order(by: "createdAt", descending: true)
            .getDocuments()

        return try snapshot.documents.map { document in
            try document.data(as: FlashcardSet.self)
        }
    }
    func deleteSet(id: String, ownerUID: String) async throws {
        try await db
            .collection("users")
            .document(ownerUID)
            .collection("flashcardSets")
            .document(id)
            .delete()
    }
}
