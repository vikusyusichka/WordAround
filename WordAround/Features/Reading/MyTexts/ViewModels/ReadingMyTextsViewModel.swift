import Foundation
import Combine

@MainActor
final class ReadingMyTextsViewModel: ObservableObject {
    @Published var texts: [ReadingUserText] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isLoggedOut = false
    @Published var navigateToAddText = false
    @Published var sessionText: ReadingUserText?

    private let storage: ReadingMyTextsStorageServicing

    init(storage: ReadingMyTextsStorageServicing = ReadingMyTextsStorageService.shared) {
        self.storage = storage
    }

    var continueReadingText: ReadingUserText? {
        texts
            .filter { $0.isUnfinished }
            .sorted { ($0.lastOpenedAt ?? $0.updatedAt) > ($1.lastOpenedAt ?? $1.updatedAt) }
            .first
    }

    var completedTexts: [ReadingUserText] {
        texts.filter(\.isCompleted)
    }

    var activeTexts: [ReadingUserText] {
        texts.filter { !$0.isCompleted }
    }

    var isEmpty: Bool { texts.isEmpty && errorMessage == nil }

    var sortedTexts: [ReadingUserText] { texts }

    func loadTexts() {
        Task { await loadTextsAsync() }
    }

    private var hasLoadedOnce = false

    func loadTextsAsync() async {
        guard PracticeLibraryLoadCoordinator.begin(
            hasLoadedOnce: &hasLoadedOnce,
            isLoading: &isLoading,
            isLoggedOut: &isLoggedOut,
            errorMessage: &errorMessage,
            userId: storage.currentUserId()
        ) else {
            texts = []
            return
        }

        defer { PracticeLibraryLoadCoordinator.finish(hasLoadedOnce: &hasLoadedOnce, isLoading: &isLoading) }

        do {
            texts = try await storage.fetchTexts()
        } catch ReadingMyTextsStorageError.cloudPermissionDenied {
            errorMessage = ReadingMyTextsStorageError.cloudPermissionDenied.localizedDescription
            #if DEBUG
            print("[ReadingMyTextsViewModel] Firestore rules block readingItems")
            #endif
        } catch {
            errorMessage = "Couldn't load your texts. Check your connection and try again."
            #if DEBUG
            print("[ReadingMyTextsViewModel] load failed:", error)
            #endif
        }
    }

    func retry() {
        Task { await loadTextsAsync() }
    }

    func deleteText(_ text: ReadingUserText) {
        Task {
            do {
                try await storage.delete(id: text.id)
                if sessionText?.id == text.id { sessionText = nil }
                texts = try await storage.fetchTexts()
            } catch {
                errorMessage = "Could not delete text."
            }
        }
    }

    func renameText(_ text: ReadingUserText, newTitle: String) {
        Task {
            do {
                try await storage.rename(textId: text.id, newTitle: newTitle)
                texts = try await storage.fetchTexts()
            } catch {
                errorMessage = "Could not rename text."
            }
        }
    }

    func markCompleted(_ text: ReadingUserText) {
        guard let score = text.averageScore else {
            errorMessage = "Finish a reading session first to mark this text complete."
            return
        }
        Task {
            do {
                try await storage.markCompleted(
                    textId: text.id,
                    scorePercent: score,
                    readingTimeSeconds: text.readingTimeSeconds ?? 0
                )
                texts = try await storage.fetchTexts()
            } catch {
                errorMessage = "Could not update text."
            }
        }
    }

    func openText(_ text: ReadingUserText) {
        sessionText = text
        Task {
            try? await storage.markOpened(textId: text.id)
            texts = (try? await storage.fetchTexts()) ?? texts
        }
    }

    func text(withId id: String) -> ReadingUserText? {
        texts.first { $0.id == id }
    }

    func clearError() {
        errorMessage = nil
    }

    func showAddText() {
        navigateToAddText = true
    }
}
