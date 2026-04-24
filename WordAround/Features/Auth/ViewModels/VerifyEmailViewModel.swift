import Foundation
import FirebaseAuth
import Combine

@MainActor
final class VerifyEmailViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var infoMessage: String?

    func resendVerificationEmail() async {
        clearMessages()
        isLoading = true
        defer { isLoading = false }

        guard let user = Auth.auth().currentUser else {
            errorMessage = "No active account found"
            return
        }

        do {
            try await user.sendEmailVerification()
            infoMessage = "Verification email sent again"
        } catch {
            errorMessage = mapFirebaseError(error)
        }
    }

    func checkVerificationStatus(sessionStore: SessionStore) async {
        clearMessages()
        isLoading = true
        defer { isLoading = false }

        guard let user = Auth.auth().currentUser else {
            errorMessage = "No active account found"
            return
        }

        do {
            try await user.reload()

            if user.isEmailVerified {
                await sessionStore.refreshAuthState()
            } else {
                errorMessage = "Email is not verified yet"
            }
        } catch {
            errorMessage = mapFirebaseError(error)
        }
    }

    private func clearMessages() {
        errorMessage = nil
        infoMessage = nil
    }

    private func mapFirebaseError(_ error: Error) -> String {
        let nsError = error as NSError

        switch AuthErrorCode(rawValue: nsError.code) {
        case .networkError:
            return "Network error. Check your internet connection"
        case .userNotFound:
            return "No active account found"
        case .tooManyRequests:
            return "Too many attempts. Try again later"
        default:
            return nsError.localizedDescription
        }
    }
}
