import Foundation
import FirebaseFirestore

/// Centralised, user-facing error messages for Firestore failures in the
/// GrammarNotes module. Both `GrammarNotesHomeViewModel` and
/// `GrammarNotesTopicViewModel` previously duplicated the same
/// `NSError.domain == FirestoreErrorDomain && code == .permissionDenied`
/// check with only the fallback message differing.
///
/// The fallback message is passed in so each VM keeps its own specific copy
/// (topics vs notes access paths) without re-implementing the detection.
enum GrammarNotesErrorMessages {
    /// Returns a user-facing message for `error`.
    /// - If the error is a Firestore permission-denied error, returns
    ///   `firestorePermission`.
    /// - Otherwise returns `error.localizedDescription`.
    static func readable(
        for error: Error,
        firestorePermission: String
    ) -> String {
        let nsError = error as NSError
        if nsError.domain == FirestoreErrorDomain,
           nsError.code == FirestoreErrorCode.permissionDenied.rawValue {
            return firestorePermission
        }
        return error.localizedDescription
    }
}
