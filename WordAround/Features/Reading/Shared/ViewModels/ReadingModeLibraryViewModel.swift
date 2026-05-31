import SwiftUI
import Combine
import FirebaseAuth

@MainActor
final class ReadingModeLibraryViewModel: ObservableObject {
    let mode: ReadingMode

    @Published private(set) var items: [ReadingLibraryItem] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    @Published private(set) var isLoggedOut = false
    @Published var selectedItem: ReadingLibraryItem?
    @Published var isShowingSetup = false
    @Published var isShowingSetCreation = false

    private let storage: ReadingStorageServicing
    private let currentUserId: () -> String?
    private var hasLoadedOnce = false

    init(
        mode: ReadingMode,
        storage: ReadingStorageServicing = ReadingStorageService(),
        currentUserId: @escaping () -> String? = { Auth.auth().currentUser?.uid }
    ) {
        self.mode = mode
        self.storage = storage
        self.currentUserId = currentUserId
    }

    // MARK: - Derived state

    var isEmpty: Bool { items.isEmpty && errorMessage == nil }
    var savedCountText: String { items.count == 1 ? "1 saved" : "\(items.count) saved" }

    // MARK: - Theme (reuses the mode's setup accent)

    private var setupConfig: ReadingSetupConfig? { ReadingSetupConfig.make(forModeID: mode.id) }
    var accent: Color { setupConfig?.accent ?? mode.accentColor }
    var accentDark: Color { setupConfig?.accentDark ?? mode.accentColor }

    // MARK: - Copy

    var title: String { mode.title }
    var subtitle: String { mode.subtitle }
    var icon: String { mode.systemImage }

    var addButtonTitle: String {
        switch mode.id {
        case "generated-reading":   return "Generate Reading"
        case "reading-from-sets":   return "Create From Set"
        case "story-mode":          return "Start Story"
        case "speed-reading":       return "Start Speed Practice"
        case "interactive-reading": return "Start Interactive Reading"
        default:                    return "Add"
        }
    }

    var addButtonIcon: String {
        switch mode.id {
        case "generated-reading":   return "sparkles"
        case "reading-from-sets":   return "rectangle.stack.fill"
        case "story-mode":          return "books.vertical.fill"
        case "speed-reading":       return "bolt.fill"
        case "interactive-reading": return "hand.tap.fill"
        default:                    return "plus"
        }
    }

    var emptyTitle: String {
        switch mode.id {
        case "generated-reading":   return "No generated readings yet"
        case "reading-from-sets":   return "No set-based readings yet"
        case "story-mode":          return "No stories yet"
        case "speed-reading":       return "No speed sessions yet"
        case "interactive-reading": return "No interactive readings yet"
        default:                    return "Nothing here yet"
        }
    }

    var emptySubtitle: String {
        switch mode.id {
        case "generated-reading":   return "Generate reading texts and practice sessions from topics."
        case "reading-from-sets":   return "Create reading sessions from your flashcard sets."
        case "story-mode":          return "Start stories, unlock chapters, and continue reading."
        case "speed-reading":       return "Train faster reading with timed exercises."
        case "interactive-reading": return "Create branching reading adventures with choices and progress."
        default:                    return "Tap add to get started."
        }
    }

    // MARK: - Loading

    func loadItems() async {
        guard PracticeLibraryLoadCoordinator.begin(
            hasLoadedOnce: &hasLoadedOnce,
            isLoading: &isLoading,
            isLoggedOut: &isLoggedOut,
            errorMessage: &errorMessage,
            userId: currentUserId()
        ) else {
            items = []
            return
        }

        defer { PracticeLibraryLoadCoordinator.finish(hasLoadedOnce: &hasLoadedOnce, isLoading: &isLoading) }

        guard let userId = currentUserId() else { return }

        do {
            items = try await storage.fetchItems(for: userId, mode: mode)
        } catch {
            errorMessage = PracticeLibraryLoadCoordinator.genericLoadError
            #if DEBUG
            print("[ReadingModeLibraryViewModel] load failed:", error)
            #endif
        }
    }

    func refresh() async { await loadItems() }

    // MARK: - Actions

    func deleteItem(_ item: ReadingLibraryItem) {
        guard let userId = currentUserId() else { return }
        items.removeAll { $0.id == item.id } // optimistic
        Task {
            do {
                try await storage.deleteItem(item, for: userId)
            } catch {
                errorMessage = "Couldn't delete that item."
                await loadItems()
            }
        }
    }

    func renameItem(_ item: ReadingLibraryItem, newTitle: String) {
        let trimmed = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != item.title else { return }
        guard let userId = currentUserId() else { return }

        var updated = item
        updated.title = trimmed
        updated.updatedAt = Date()

        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index] = updated
        }

        Task {
            do {
                try await storage.updateItem(updated, for: userId)
            } catch {
                errorMessage = "Couldn't rename that reading."
                await loadItems()
            }
        }
    }

    func openItem(_ item: ReadingLibraryItem) {
        updateLastOpened(item)
        selectedItem = item
    }

    func updateLastOpened(_ item: ReadingLibraryItem) {
        guard let userId = currentUserId() else { return }
        Task { try? await storage.updateLastOpened(itemId: item.id, mode: mode, for: userId) }
    }

    func handleAddTapped() {
        if usesSetCreationFlow {
            isShowingSetCreation = true
        } else {
            isShowingSetup = true
        }
    }

    var usesSetCreationFlow: Bool { mode.id == "reading-from-sets" }

    var supportsRename: Bool { mode.id == "reading-from-sets" }

    func clearError() { errorMessage = nil }

    func sessionSetup(for item: ReadingLibraryItem) -> ReadingSessionSetup {
        ReadingSessionSetup(
            modeID: mode.id,
            language: item.language,
            selections: item.selections,
            toggles: item.toggles,
            accent: accent,
            accentDark: accentDark,
            title: mode.title,
            subtitle: mode.subtitle
        )
    }
}
