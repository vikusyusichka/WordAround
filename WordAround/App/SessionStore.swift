import Foundation
import Combine
import FirebaseAuth

@MainActor
final class SessionStore: ObservableObject {
    enum AuthFlowState: Equatable {
        case loading
        case loggedOut
        case emailVerificationRequired(email: String)
        case authenticated(email: String)
    }

    @Published private(set) var state: AuthFlowState = .loading

    private var handle: AuthStateDidChangeListenerHandle?

    init() {
        observeAuthState()
    }

    deinit {
        if let handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    private func observeAuthState() {
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, _ in
            guard let self else { return }

            Task { @MainActor in
                await self.refreshAuthState()
            }
        }
    }

    func refreshAuthState() async {
        guard let user = Auth.auth().currentUser else {
            state = .loggedOut
            return
        }

        do {
            try await user.reload()
        } catch {
            // навіть якщо reload впав, пробуємо визначити стан по поточному user
        }

        let providers = user.providerData.map(\.providerID)
        let email = user.email ?? "Unknown account"

        if providers.contains("google.com") {
            state = .authenticated(email: email)
            return
        }

        if providers.contains("password") {
            if user.isEmailVerified {
                state = .authenticated(email: email)
            } else {
                state = .emailVerificationRequired(email: email)
            }
            return
        }

        state = .authenticated(email: email)
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            state = .loggedOut
        } catch {
            // залишаємо стан як є, бо без паніки
        }
    }

    var currentEmail: String {
        Auth.auth().currentUser?.email ?? "Unknown account"
    }
}
