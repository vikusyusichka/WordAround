import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

final class AccountDeletionService {
    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    enum DeletionError: LocalizedError {
        case notSignedIn
        case requiresRecentLogin
        case underlying(Error)

        var errorDescription: String? {
            switch self {
            case .notSignedIn:
                return "You're not signed in."
            case .requiresRecentLogin:
                return L10n.string(.deleteAccountReauthNeeded, language: .english)
            case .underlying(let error):
                return error.localizedDescription
            }
        }
    }

    func deleteCurrentUserAccount() async throws {
        guard let user = Auth.auth().currentUser else {
            throw DeletionError.notSignedIn
        }

        let uid = user.uid

        try? await deleteFirestoreUserDocument(uid: uid)
        try? await deleteAvatarStorage(uid: uid)

        do {
            try await user.delete()
        } catch {
            let nsError = error as NSError
            if nsError.code == AuthErrorCode.requiresRecentLogin.rawValue {
                throw DeletionError.requiresRecentLogin
            }
            throw DeletionError.underlying(error)
        }
    }

    // MARK: - Internals

    private func deleteFirestoreUserDocument(uid: String) async throws {
        try await db.collection("users").document(uid).delete()
    }

    private func deleteAvatarStorage(uid: String) async throws {
        let ref = storage.reference()
            .child("users")
            .child(uid)
            .child("profile")
            .child("avatar.jpg")
        try await ref.delete()
    }
}
