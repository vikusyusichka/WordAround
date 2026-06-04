import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

final class UserProfileService {
    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    func saveProfile(
        uid: String,
        displayName: String?,
        email: String?,
        photoURL: String?,
        avatarColor: String? = nil
    ) async throws {
        var payload: [String: Any] = [
            "updatedAt": FieldValue.serverTimestamp()
        ]
        if let displayName { payload["displayName"] = displayName }
        if let email { payload["email"] = email }
        if let photoURL { payload["photoURL"] = photoURL }
        if let avatarColor { payload["avatarColor"] = avatarColor }

        try await db
            .collection("users")
            .document(uid)
            .setData(payload, merge: true)
    }

    func uploadAvatar(uid: String, jpegData: Data) async throws -> String {
        let ref = storage.reference()
            .child("users")
            .child(uid)
            .child("profile")
            .child("avatar.jpg")

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        _ = try await ref.putDataAsync(jpegData, metadata: metadata)
        let url = try await ref.downloadURL()
        return url.absoluteString
    }
}
