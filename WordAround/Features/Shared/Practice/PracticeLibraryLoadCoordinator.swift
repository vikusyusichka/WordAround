import Foundation

@MainActor
enum PracticeLibraryLoadCoordinator {
    static func begin(
        hasLoadedOnce: inout Bool,
        isLoading: inout Bool,
        isLoggedOut: inout Bool,
        errorMessage: inout String?,
        userId: String?
    ) -> Bool {
        guard userId != nil else {
            isLoggedOut = true
            isLoading = false
            errorMessage = nil
            return false
        }

        isLoggedOut = false
        if !hasLoadedOnce { isLoading = true }
        errorMessage = nil
        return true
    }

    static func finish(
        hasLoadedOnce: inout Bool,
        isLoading: inout Bool
    ) {
        isLoading = false
        hasLoadedOnce = true
    }

    static var genericLoadError: String {
        "Couldn't load your library. Check your connection and try again."
    }
}
