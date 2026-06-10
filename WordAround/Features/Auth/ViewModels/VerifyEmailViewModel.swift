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
            errorMessage = L10n.string("authNoActiveAccount")
            return
        }

        do {
            try await user.sendEmailVerification()
            infoMessage = L10n.string("authVerifyResent")
        } catch {
            errorMessage = mapFirebaseError(error)
        }
    }

    func checkVerificationStatus(sessionStore: SessionStore) async {
        clearMessages()
        isLoading = true
        defer { isLoading = false }

        guard let user = Auth.auth().currentUser else {
            errorMessage = L10n.string("authNoActiveAccount")
            return
        }

        do {
            try await user.reload()

            if user.isEmailVerified {
                await sessionStore.refreshAuthState()
            } else {
                errorMessage = L10n.string("authEmailNotVerified")
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
            return L10n.string("authErrNetwork")
        case .userNotFound:
            return L10n.string("authNoActiveAccount")
        case .tooManyRequests:
            return L10n.string("authErrTooManyAttempts")
        default:
            return nsError.localizedDescription
        }
    }
}
