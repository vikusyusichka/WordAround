import Foundation
import Combine
import FirebaseAuth

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var infoMessage: String?

    private let authService: AuthServiceProtocol
    private weak var sessionStore: SessionStore?

    init(
        authService: AuthServiceProtocol? = nil,
        sessionStore: SessionStore? = nil
    ) {
        self.authService = authService ?? AuthService()
        self.sessionStore = sessionStore
    }

    func attachSessionStore(_ sessionStore: SessionStore) {
        self.sessionStore = sessionStore
    }

    func signIn() async {
        clearMessages()

        guard validateForSignIn() else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            try await authService.signIn(email: email, password: password)
            await sessionStore?.refreshAuthState()
        } catch {
            errorMessage = mapFirebaseError(error)
        }
    }

    func signUp() async {
        clearMessages()

        guard validateForSignUp() else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            try await authService.signUp(email: email, password: password)
            infoMessage = L10n.string("authAccountCreated")
            await sessionStore?.refreshAuthState()
        } catch {
            errorMessage = mapFirebaseError(error)
        }
    }

    func signInWithGoogle() async {
        clearMessages()

        isLoading = true
        defer { isLoading = false }

        do {
            try await authService.signInWithGoogle()
            await sessionStore?.refreshAuthState()
        } catch {
            errorMessage = mapFirebaseError(error)
        }
    }

    func resetPassword() async {
        clearMessages()

        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanEmail.isEmpty else {
            errorMessage = L10n.string("authEnterEmailFirst")
            return
        }

        guard isValidEmail(cleanEmail) else {
            errorMessage = L10n.string("authEnterValidEmail")
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            try await authService.sendPasswordReset(to: cleanEmail)
            infoMessage = L10n.string("authPasswordResetSent")
        } catch {
            errorMessage = mapFirebaseError(error)
        }
    }

    private func clearMessages() {
        errorMessage = nil
        infoMessage = nil
    }

    private func validateForSignIn() -> Bool {
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanEmail.isEmpty else {
            errorMessage = L10n.string("authEmailRequired")
            return false
        }

        guard isValidEmail(cleanEmail) else {
            errorMessage = L10n.string("authEnterValidEmail")
            return false
        }

        guard !password.isEmpty else {
            errorMessage = L10n.string("authPasswordRequired")
            return false
        }

        return true
    }

    private func validateForSignUp() -> Bool {
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanEmail.isEmpty else {
            errorMessage = L10n.string("authEmailRequired")
            return false
        }

        guard isValidEmail(cleanEmail) else {
            errorMessage = L10n.string("authEnterValidEmail")
            return false
        }

        guard !password.isEmpty else {
            errorMessage = L10n.string("authPasswordRequired")
            return false
        }

        guard password.count >= 6 else {
            errorMessage = L10n.string("authPasswordTooShort")
            return false
        }

        return true
    }

    private func isValidEmail(_ email: String) -> Bool {
        let pattern = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: pattern, options: .regularExpression) != nil
    }

    private func mapFirebaseError(_ error: Error) -> String {
        let nsError = error as NSError

        switch nsError.code {
        case 17008:
            return L10n.string("authErrInvalidEmail")
        case 17009:
            return L10n.string("authErrIncorrectPassword")
        case 17011:
            return L10n.string("authErrNoAccount")
        case 17007:
            return L10n.string("authErrAccountExists")
        case 17026:
            return L10n.string("authPasswordTooShort")
        case 17020:
            return L10n.string("authErrNetwork")
        case 17010:
            return L10n.string("authErrTooManyAttempts")
        case 17012:
            return L10n.string("authErrDifferentMethod")
        case 17999:
            return L10n.string("authErrGeneric")
        default:
            return nsError.localizedDescription
        }
    }
}
