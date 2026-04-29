import Foundation
import FirebaseFirestore

final class FolderService {
    private let db = Firestore.firestore()

    func createFolder(_ folder: Folder) async throws {
        try db
            .collection("users")
            .document(folder.ownerUID)
            .collection("folders")
            .document(folder.id)
            .setData(from: folder)
    }

    func fetchFolders(for uid: String) async throws -> [Folder] {
        let snapshot = try await db
            .collection("users")
            .document(uid)
            .collection("folders")
            .order(by: "createdAt", descending: true)
            .getDocuments()

        return try snapshot.documents.map {
            try $0.data(as: Folder.self)
        }
    }

    func updateFolder(_ folder: Folder) async throws {
        try db
            .collection("users")
            .document(folder.ownerUID)
            .collection("folders")
            .document(folder.id)
            .setData(from: folder, merge: true)
    }

    func deleteFolder(id: String, ownerUID: String) async throws {
        try await db
            .collection("users")
            .document(ownerUID)
            .collection("folders")
            .document(id)
            .delete()
    }
}
