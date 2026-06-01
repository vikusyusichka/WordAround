import Foundation
#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

enum ReadingServiceErrorMapper {

    enum Category {
        case signInRequired
        case noInternet
        case aiUnavailable
        case syncFailed
        case unknown
    }

    static func friendlyMessage(for error: Error, fallback: String? = nil) -> String {
        switch category(for: error) {
        case .signInRequired:
            return "Sign in to continue."
        case .noInternet:
            return "You're offline. Check your connection and try again."
        case .aiUnavailable:
            return "Text generation is temporarily unavailable. Try again in a moment."
        case .syncFailed:
            return "Library sync failed. Your latest changes are saved on this device."
        case .unknown:
            if let localized = error as? LocalizedError, let description = localized.errorDescription {
                return description
            }
            return fallback ?? "Something went wrong. Please try again."
        }
    }

    static func category(for error: Error) -> Category {
        let ns = error as NSError

        if ns.domain == NSURLErrorDomain {
            switch ns.code {
            case NSURLErrorNotConnectedToInternet,
                 NSURLErrorNetworkConnectionLost,
                 NSURLErrorTimedOut,
                 NSURLErrorCannotConnectToHost,
                 NSURLErrorCannotFindHost,
                 NSURLErrorDataNotAllowed:
                return .noInternet
            default:
                break
            }
        }

        if let description = (error as? LocalizedError)?.errorDescription?.lowercased() {
            if description.contains("sign in") { return .signInRequired }
            if description.contains("offline") || description.contains("connection") {
                return .noInternet
            }
            if description.contains("ai") || description.contains("server couldn't") {
                return .aiUnavailable
            }
            if description.contains("sync") || description.contains("rules") {
                return .syncFailed
            }
        }

        #if canImport(FirebaseFirestore)
        if ns.domain == FirestoreErrorDomain {
            switch FirestoreErrorCode.Code(rawValue: ns.code) {
            case .permissionDenied, .unauthenticated:
                return .syncFailed
            case .unavailable, .deadlineExceeded:
                return .noInternet
            default:
                return .syncFailed
            }
        }
        #endif

        return .unknown
    }
}
