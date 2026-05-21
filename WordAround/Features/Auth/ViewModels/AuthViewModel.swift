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
            infoMessage = "Account created. We sent a verification email."
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
            errorMessage = "Enter your email first"
            return
        }

        guard isValidEmail(cleanEmail) else {
            errorMessage = "Enter a valid email"
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            try await authService.sendPasswordReset(to: cleanEmail)
            infoMessage = "Password reset email sent"
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
            errorMessage = "Email is required"
            return false
        }

        guard isValidEmail(cleanEmail) else {
            errorMessage = "Enter a valid email"
            return false
        }

        guard !password.isEmpty else {
            errorMessage = "Password is required"
            return false
        }

        return true
    }

    private func validateForSignUp() -> Bool {
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanEmail.isEmpty else {
            errorMessage = "Email is required"
            return false
        }

        guard isValidEmail(cleanEmail) else {
            errorMessage = "Enter a valid email"
            return false
        }

        guard !password.isEmpty else {
            errorMessage = "Password is required"
            return false
        }

        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
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
            return "Invalid email format"
        case 17009:
            return "Incorrect password"
        case 17011:
            return "No account found with this email"
        case 17007:
            return "This account already exists"
        case 17026:
            return "Password must be at least 6 characters"
        case 17020:
            return "Network error. Check your internet connection"
        case 17010:
            return "Too many attempts. Try again later"
        case 17012:
            return "This email is already used with another sign-in method"
        case 17999:
            return "Authentication failed. Please try again"
        default:
            return nsError.localizedDescription
        }
    }
}
