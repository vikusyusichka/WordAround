import SwiftUI
import Combine
import FirebaseAuth

@MainActor
final class StorySetupViewModel: ObservableObject {
    @Published private(set) var isSaving = false
    @Published var errorMessage: String?
    @Published var createdSession: StorySession?

    private let storageService: StoryStorageServicing
    private let currentUserId: () -> String?

    init(
        storageService: StoryStorageServicing = StoryStorageService.shared,
        currentUserId: @escaping () -> String? = { Auth.auth().currentUser?.uid }
    ) {
        self.storageService = storageService
        self.currentUserId = currentUserId
    }

    // MARK: - Start Story

    func startStory(from setup: ReadingSessionSetup) {
        guard let userId = currentUserId() else {
            errorMessage = "Sign in to create a story."
            return
        }
        guard !isSaving else { return }

        isSaving = true
        errorMessage = nil
        let config = StoryModeConfiguration(from: setup)

        Task {
            defer { isSaving = false }
            do {
                let session = try await storageService.createSession(config: config, for: userId)
                createdSession = session
            } catch {
                errorMessage = "Couldn't save your story. Check your connection and try again."
                #if DEBUG
                print("[StorySetupViewModel] createSession failed:", error)
                #endif
            }
        }
    }
}
