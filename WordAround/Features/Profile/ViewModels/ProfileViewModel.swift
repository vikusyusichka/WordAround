import SwiftUI
import Combine
import FirebaseAuth
import UIKit

/// Backs `ProfileView` and `EditProfileSheet`. Owns the editable profile
/// state, the read-only learning summary, and the save/sign-out flows.
///
/// Firebase calls live here (not in the views): `loadProfile` snapshots
/// `Auth.auth().currentUser`, `saveProfile` writes via
/// `createProfileChangeRequest()` + `UserProfileService`, and `signOut`
/// delegates to `AuthService`. `SessionStore` observes the auth-state listener
/// and will route the app back to the auth flow automatically.
@MainActor
final class ProfileViewModel: ObservableObject {

    // MARK: - Profile fields

    @Published private(set) var email: String = ""
    @Published var displayName: String = ""
    @Published private(set) var photoURL: URL?

    /// Edit-sheet local draft. Cleared when the sheet is dismissed.
    @Published var draftDisplayName: String = ""
    @Published var draftAvatarImage: UIImage?

    // MARK: - State

    @Published private(set) var isSaving = false
    @Published var errorMessage: String?

    /// Account metadata for the summary card (joined date).
    @Published private(set) var joinedDate: Date?

    /// Learning summary numbers. Each entry is hidden when its value is 0,
    /// so the summary card can hide itself when nothing exists yet.
    @Published private(set) var totalWordsWritten: Int = 0
    @Published private(set) var totalPracticeMinutes: Int = 0

    // MARK: - Dependencies

    private let authService: AuthServiceProtocol
    private let profileService: UserProfileService
    private let statsStore: DailyPracticeStatsStoring
    private let listeningStore: ListeningSessionStoring

    // MARK: - Init

    init(
        authService: AuthServiceProtocol? = nil,
        profileService: UserProfileService = UserProfileService(),
        statsStore: DailyPracticeStatsStoring = LocalDailyPracticeStatsStore.shared,
        listeningStore: ListeningSessionStoring? = nil
    ) {
        self.authService = authService ?? AuthService()
        self.profileService = profileService
        self.statsStore = statsStore
        self.listeningStore = listeningStore ?? LocalListeningSessionStore.shared
    }

    // MARK: - Derived

    /// Two-letter avatar fallback. Falls back to the email's first letter when
    /// no display name is set so the avatar is never blank.
    var initials: String {
        let source = displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? email
            : displayName
        let parts = source
            .split(whereSeparator: { $0.isWhitespace || $0 == "." || $0 == "@" })
            .prefix(2)
        let letters = parts.compactMap { $0.first.map(String.init) }
        return letters.joined().uppercased()
    }

    /// True when the user hasn't picked a name yet — used to show the
    /// "Add your name" placeholder instead of an empty label.
    var hasDisplayName: Bool {
        !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// The summary card hides itself when there is genuinely nothing to show.
    var hasAnySummaryStat: Bool {
        totalWordsWritten > 0 || totalPracticeMinutes > 0 || joinedDate != nil
    }

    /// Edit sheet's Save button is enabled only when the draft actually differs
    /// from what's persisted on Auth. Trim so trailing whitespace doesn't pass.
    var hasUnsavedChanges: Bool {
        let trimmedDraft = draftDisplayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let nameChanged = trimmedDraft != displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        return nameChanged || draftAvatarImage != nil
    }

    // MARK: - Loading

    func loadProfile() async {
        guard let user = authService.currentUser else { return }

        email = user.email ?? ""
        displayName = user.displayName ?? ""
        photoURL = user.photoURL
        joinedDate = user.metadata.creationDate

        await loadSummaryStats()
    }

    /// Aggregates the real stats backend over all-time. Writing entries are
    /// counted in words; speaking / reading entries are stored in seconds and
    /// converted to minutes. Listening uses its dedicated session store the
    /// same way `HomeViewModel` and `ListeningHomeViewModel` do.
    private func loadSummaryStats() async {
        let entries = await statsStore.fetchAll()
        totalWordsWritten = entries
            .filter { $0.skill == .writing }
            .reduce(0) { $0 + $1.value }

        let practiceSeconds = entries
            .filter { $0.skill == .speaking || $0.skill == .reading }
            .reduce(0) { $0 + $1.value }

        let listeningSessions = await listeningStore.fetchSessions()
        var seenIds = Set<String>()
        let listeningSeconds = listeningSessions
            .filter { $0.isCompleted }
            .reduce(into: 0) { partial, session in
                guard seenIds.insert(session.id).inserted else { return }
                partial += session.elapsedSeconds
            }

        totalPracticeMinutes = (practiceSeconds + listeningSeconds) / 60
    }

    // MARK: - Edit sheet

    func beginEditing() {
        draftDisplayName = displayName
        draftAvatarImage = nil
        errorMessage = nil
    }

    func cancelEditing() {
        draftDisplayName = displayName
        draftAvatarImage = nil
    }

    // MARK: - Save

    /// Pushes the edit-sheet draft to Auth + Firestore (+ Storage if an avatar
    /// was picked). Returns `true` on success so the view can dismiss the
    /// sheet; failures stay on screen via `errorMessage`.
    @discardableResult
    func saveProfile() async -> Bool {
        guard let user = authService.currentUser else {
            errorMessage = "You're signed out."
            return false
        }
        guard hasUnsavedChanges else { return true }

        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        let trimmedName = draftDisplayName.trimmingCharacters(in: .whitespacesAndNewlines)
        var newPhotoURLString: String? = nil

        do {
            // 1. Avatar (optional). Upload first so the new photoURL can be
            // written alongside the name in a single Auth profile change.
            if let image = draftAvatarImage,
               let jpeg = image.jpegData(compressionQuality: 0.85) {
                let urlString = try await profileService.uploadAvatar(
                    uid: user.uid,
                    jpegData: jpeg
                )
                newPhotoURLString = urlString
            }

            // 2. FirebaseAuth profile change request.
            let change = user.createProfileChangeRequest()
            if trimmedName != displayName {
                change.displayName = trimmedName
            }
            if let urlString = newPhotoURLString, let url = URL(string: urlString) {
                change.photoURL = url
            }
            try await change.commitChanges()

            // 3. Firestore mirror (merge:true so unrelated fields survive).
            try await profileService.saveProfile(
                uid: user.uid,
                displayName: trimmedName,
                email: user.email,
                photoURL: newPhotoURLString ?? user.photoURL?.absoluteString
            )

            // 4. Reflect in the published state so the profile card updates.
            displayName = trimmedName
            if let urlString = newPhotoURLString, let url = URL(string: urlString) {
                photoURL = url
            }
            draftAvatarImage = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    // MARK: - Sign out

    /// Delegates to `AuthService`; `SessionStore`'s auth-state listener routes
    /// the app back to the auth flow on its own — we don't drive navigation
    /// from here.
    func signOut() {
        do {
            try authService.signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
