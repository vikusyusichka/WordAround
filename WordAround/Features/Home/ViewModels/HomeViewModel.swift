import SwiftUI
import Combine
import FirebaseAuth

@MainActor
final class HomeViewModel: ObservableObject {

    // MARK: - Daily practice stats (real values from DailyPracticeStatsService /
    // the listening session store — see `loadDailyStats()`)

    @Published var dailyStats: [HomeDailyStat] = []

    // MARK: - Folders

    @Published var folders: [Folder] = []
    @Published var isLoadingFolders = false
    @Published var errorMessage: String?

    // MARK: - Navigation state (single source of truth — observed by the
    // sidebar, the bottom bar, and HomeView's main content switch)

    @Published var selectedTab: HomeTab? = nil
    @Published var selectedCategory: HomeCategory? = nil
    @Published var isCreateMenuPresented: Bool = false

    // MARK: - Dependencies

    private let folderService: FolderService
    private let authService: AuthServiceProtocol
    private let statsService: DailyPracticeStatsService
    private let listeningStore: ListeningSessionStoring

    // MARK: - Init

    init(
        folderService: FolderService? = nil,
        authService: AuthServiceProtocol? = nil,
        statsService: DailyPracticeStatsService = .shared,
        listeningStore: ListeningSessionStoring? = nil
    ) {
        self.folderService = folderService ?? FolderService()
        self.authService = authService ?? AuthService()
        self.statsService = statsService
        self.listeningStore = listeningStore ?? LocalListeningSessionStore.shared

        Task {
            await loadFolders()
            await loadDailyStats()
        }
    }

    // MARK: - Header copy (derived from navigation state)

    var headerTitle: String {
        if selectedTab == nil || selectedTab == .home {
            switch selectedCategory {
            case .speaking:
                return "Speaking"
            case .listening:
                return "Listening"
            case .reading:
                return "Reading"
            case .writing:
                return "Writing"
            case .notes:
                return "Notes"
            case .none:
                return "Flashcards"
            }
        }

        switch selectedTab {
        case .folders:
            return "Folders"
        case .flashcards:
            return "Sets"
        case .create:
            return "Create"
        case .profile:
            return "Profile"
        case .home, .none:
            return "Flashcards"
        }
    }

    /// Subtitle uses the signed-in email when the profile tab is active, so
    /// the caller must pass it in (the VM does not own session state).
    func headerSubtitle(currentEmail: String) -> String {
        if selectedTab == nil || selectedTab == .home {
            switch selectedCategory {
            case .speaking:
                return "Practice speaking skills."
            case .listening:
                return "Train your ears to understand language naturally."
            case .reading:
                return "Read and review language materials."
            case .writing:
                return "Practice your language actively."
            case .notes:
                return "Your grammar notes and mistakes."
            case .none:
                return "Pick a set to practice"
            }
        }

        switch selectedTab {
        case .folders:
            return "Manage your folders"
        case .flashcards:
            return "Manage your flashcard sets"
        case .create:
            return "Build a new study set"
        case .profile:
            return currentEmail
        case .home, .none:
            return "Pick a set to practice"
        }
    }

    // MARK: - Navigation actions

    /// Clears the selected category with the same spring curve the bottom bar
    /// uses for tab transitions. Idempotent: no-op when no category is set.
    func clearSelectedCategory() {
        guard selectedCategory != nil else { return }
        withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
            selectedCategory = nil
        }
    }

    /// Selects a learning section from the sidebar. Routes to the Home tab so
    /// the category content renders regardless of which bottom tab was active —
    /// this is what makes the sidebar work globally. Sidebar and bottom bar
    /// share this single `selectedTab` / `selectedCategory` source of truth.
    func selectCategory(_ category: HomeCategory) {
        withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
            selectedTab = .home
            selectedCategory = category
        }
    }

    // MARK: - Daily stats

    /// Loads today's per-section practice totals from the existing stats
    /// backend. Speaking / listening / reading are stored in seconds (shown as
    /// minutes); writing is stored in words.
    func loadDailyStats() async {
        let speakingSeconds = await statsService.totalToday(skill: .speaking)
        let readingSeconds = await statsService.totalToday(skill: .reading)
        let writingWords = await statsService.totalToday(skill: .writing)
        let listeningMinutes = await listeningMinutesToday()

        dailyStats = [
            HomeDailyStat(
                id: .speaking,
                title: "Speaking",
                value: "\(speakingSeconds / 60)",
                label: "minutes",
                iconSystemName: HomeCategory.speaking.icon
            ),
            HomeDailyStat(
                id: .listening,
                title: "Listening",
                value: "\(listeningMinutes)",
                label: "minutes",
                iconSystemName: HomeCategory.listening.icon
            ),
            HomeDailyStat(
                id: .reading,
                title: "Reading",
                value: "\(readingSeconds / 60)",
                label: "minutes",
                iconSystemName: HomeCategory.reading.icon
            ),
            HomeDailyStat(
                id: .writing,
                title: "Writing",
                value: "\(writingWords)",
                label: "words",
                iconSystemName: HomeCategory.writing.icon
            )
        ]
    }

    /// Listening records to its own session store rather than the shared stats
    /// service, so today's minutes are aggregated here the same way the
    /// Listening home screen does (completed sessions only, each id counted once).
    private func listeningMinutesToday() async -> Int {
        let sessions = await listeningStore.fetchSessions()
        let calendar = Calendar.current
        var seenIds = Set<String>()
        let seconds = sessions
            .filter { $0.isCompleted && calendar.isDateInToday($0.updatedAt) }
            .reduce(into: 0) { partial, session in
                guard seenIds.insert(session.id).inserted else { return }
                partial += session.elapsedSeconds
            }
        return seconds / 60
    }

    // MARK: - Folders

    func refresh() async {
        await loadFolders()
        await loadDailyStats()
    }

    func loadFolders() async {
        guard let user = authService.currentUser else {
            folders = []
            errorMessage = "User is not signed in."
            return
        }

        isLoadingFolders = true
        errorMessage = nil

        do {
            folders = try await folderService.fetchFolders(for: user.uid)
            isLoadingFolders = false
        } catch {
            isLoadingFolders = false
            errorMessage = error.localizedDescription
        }
    }

    func setsCount(for folder: Folder, in sets: [HomeSetPreviewItem]) -> Int {
        sets.filter { item in
            item.sourceSet?.folderID == folder.id ||
            item.sourceSet?.folderName == folder.title
        }.count
    }

    func deleteFolder(_ folder: Folder) async {
        do {
            try await folderService.deleteFolder(
                id: folder.id,
                ownerUID: folder.ownerUID
            )

            folders.removeAll { $0.id == folder.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func moveFolders(from source: IndexSet, to destination: Int) {
        folders.move(fromOffsets: source, toOffset: destination)
    }
}
