import Foundation
import FirebaseAuth
import GoogleSignIn
import FirebaseCore
import UIKit

protocol AuthServiceProtocol {
    var currentUser: User? { get }

    func signIn(email: String, password: String) async throws
    func signUp(email: String, password: String) async throws
    func signOut() throws

    @MainActor func signInWithGoogle() async throws
    func sendEmailVerification() async throws
    func reloadCurrentUser() async throws
    func sendPasswordReset(to email: String) async throws
}

final class AuthService: AuthServiceProtocol {
    var currentUser: User? {
        Auth.auth().currentUser
    }

    func signIn(email: String, password: String) async throws {
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        _ = try await Auth.auth().signIn(withEmail: cleanEmail, password: password)
    }

    func signUp(email: String, password: String) async throws {
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let result = try await Auth.auth().createUser(withEmail: cleanEmail, password: password)
        try await result.user.sendEmailVerification()
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }

    func sendEmailVerification() async throws {
        guard let user = Auth.auth().currentUser else { return }
        try await user.sendEmailVerification()
    }

    func reloadCurrentUser() async throws {
        guard let user = Auth.auth().currentUser else { return }
        try await user.reload()
    }

    func sendPasswordReset(to email: String) async throws {
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        try await Auth.auth().sendPasswordReset(withEmail: cleanEmail)
    }

    @MainActor
    func signInWithGoogle() async throws {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw NSError(
                domain: "AuthService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Missing Firebase client ID."]
            )
        }

        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)

        guard
            let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let rootViewController = scene.windows.first?.rootViewController
        else {
            throw NSError(
                domain: "AuthService",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "Missing root view controller."]
            )
        }

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)

        guard let idToken = result.user.idToken?.tokenString else {
            throw NSError(
                domain: "AuthService",
                code: -3,
                userInfo: [NSLocalizedDescriptionKey: "Missing Google ID token."]
            )
        }

        let accessToken = result.user.accessToken.tokenString
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)

        _ = try await Auth.auth().signIn(with: credential)
    }
}
