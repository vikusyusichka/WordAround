import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

/// Persistence for the signed-in user's profile.
///
/// Responsibilities:
/// - Mirrors `displayName`, `email`, `photoURL`, `updatedAt` to
///   `users/{uid}` in Firestore (merge: true) so other screens / future
///   features can read the profile without touching FirebaseAuth.
/// - Uploads avatar images to `users/{uid}/profile/avatar.jpg` in Storage and
///   returns the public download URL the caller writes back into the Auth
///   profile + Firestore mirror.
final class UserProfileService {
    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    /// Writes profile fields to `users/{uid}` with `merge: true` so unrelated
    /// fields (added by other features) are preserved.
    func saveProfile(
        uid: String,
        displayName: String?,
        email: String?,
        photoURL: String?
    ) async throws {
        var payload: [String: Any] = [
            "updatedAt": FieldValue.serverTimestamp()
        ]
        if let displayName { payload["displayName"] = displayName }
        if let email { payload["email"] = email }
        if let photoURL { payload["photoURL"] = photoURL }

        try await db
            .collection("users")
            .document(uid)
            .setData(payload, merge: true)
    }

    /// Uploads JPEG data to a fixed path so the avatar is replaceable without
    /// leaving orphaned objects. Returns the download URL string.
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
