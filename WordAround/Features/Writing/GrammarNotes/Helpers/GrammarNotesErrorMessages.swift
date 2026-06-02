import Foundation
import FirebaseFirestore

enum GrammarNotesErrorMessages {
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
