import SwiftUI
import Combine
import FirebaseAuth
import UIKit

@MainActor
final class ProfileViewModel: ObservableObject {

    // MARK: - Profile fields

    @Published private(set) var email: String = ""
    @Published var displayName: String = ""
    @Published private(set) var photoURL: URL?

    @Published var draftDisplayName: String = ""
    @Published var draftAvatarImage: UIImage?
    @Published var draftAvatarColor: ProfileAvatarColor = .default

    // MARK: - State

    @Published private(set) var isSaving = false
    @Published private(set) var isDeleting = false
    @Published var errorMessage: String?
    @Published private(set) var requiresReauthForDeletion = false

    @Published private(set) var joinedDate: Date?

    @Published private(set) var totalWordsWritten: Int = 0
    @Published private(set) var totalPracticeMinutes: Int = 0

    // MARK: - Dependencies

    private let authService: AuthServiceProtocol
    private let profileService: UserProfileService
    private let statsStore: DailyPracticeStatsStoring
    private let listeningStore: ListeningSessionStoring
    private let deletionService: AccountDeletionService
    private let preferences: UserPreferencesStore

    // MARK: - Init

    init(
        authService: AuthServiceProtocol? = nil,
        profileService: UserProfileService = UserProfileService(),
        statsStore: DailyPracticeStatsStoring = LocalDailyPracticeStatsStore.shared,
        listeningStore: ListeningSessionStoring? = nil,
        deletionService: AccountDeletionService = AccountDeletionService(),
        preferences: UserPreferencesStore = .shared
    ) {
        self.authService = authService ?? AuthService()
        self.profileService = profileService
        self.statsStore = statsStore
        self.listeningStore = listeningStore ?? LocalListeningSessionStore.shared
        self.deletionService = deletionService
        self.preferences = preferences
    }

    // MARK: - Avatar color

    var avatarColor: ProfileAvatarColor { preferences.avatarColor }

    // MARK: - Derived

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

    var hasDisplayName: Bool {
        !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var hasAnySummaryStat: Bool {
        totalWordsWritten > 0 || totalPracticeMinutes > 0 || joinedDate != nil
    }

    var hasUnsavedChanges: Bool {
        let trimmedDraft = draftDisplayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let nameChanged = trimmedDraft != displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let colorChanged = draftAvatarColor != preferences.avatarColor
        return nameChanged || draftAvatarImage != nil || colorChanged
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
        draftAvatarColor = preferences.avatarColor
        errorMessage = nil
    }

    func cancelEditing() {
        draftDisplayName = displayName
        draftAvatarImage = nil
        draftAvatarColor = preferences.avatarColor
    }

    // MARK: - Save

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
            if let image = draftAvatarImage,
               let jpeg = image.jpegData(compressionQuality: 0.85) {
                let urlString = try await profileService.uploadAvatar(
                    uid: user.uid,
                    jpegData: jpeg
                )
                newPhotoURLString = urlString
            }

            let change = user.createProfileChangeRequest()
            if trimmedName != displayName {
                change.displayName = trimmedName
            }
            if let urlString = newPhotoURLString, let url = URL(string: urlString) {
                change.photoURL = url
            }
            try await change.commitChanges()

            try await profileService.saveProfile(
                uid: user.uid,
                displayName: trimmedName,
                email: user.email,
                photoURL: newPhotoURLString ?? user.photoURL?.absoluteString,
                avatarColor: draftAvatarColor.rawValue
            )

            displayName = trimmedName
            if let urlString = newPhotoURLString, let url = URL(string: urlString) {
                photoURL = url
            }
            preferences.avatarColor = draftAvatarColor
            draftAvatarImage = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    // MARK: - Sign out

    func signOut() {
        do {
            try authService.signOut()
            cleanupLocalUserState()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Delete account

    @discardableResult
    func deleteAccount() async -> Bool {
        guard !isDeleting else { return false }
        isDeleting = true
        errorMessage = nil
        requiresReauthForDeletion = false
        defer { isDeleting = false }

        do {
            try await deletionService.deleteCurrentUserAccount()
            cleanupLocalUserState()
            return true
        } catch AccountDeletionService.DeletionError.requiresRecentLogin {
            requiresReauthForDeletion = true
            errorMessage = L10n.string(.deleteAccountReauthNeeded)
            try? authService.signOut()
            cleanupLocalUserState()
            return false
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    private func cleanupLocalUserState() {
        preferences.resetToDefaults()
        Task { await NotificationService.shared.removeAll() }
    }
}
