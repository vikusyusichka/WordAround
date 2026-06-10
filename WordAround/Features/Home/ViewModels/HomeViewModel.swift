import SwiftUI
import Combine
import FirebaseAuth

@MainActor
final class HomeViewModel: ObservableObject {

    // MARK: - Daily practice stats

    @Published var dailyStats: [HomeDailyStat] = []

    // MARK: - Folders

    @Published var folders: [Folder] = []
    @Published var isLoadingFolders = false
    @Published var errorMessage: String?

    // MARK: - Navigation state

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

    // MARK: - Header copy

    var headerTitle: String {
        if selectedTab == nil || selectedTab == .home {
            switch selectedCategory {
            case .speaking:
                return L10n.string("categorySpeaking")
            case .listening:
                return L10n.string("categoryListening")
            case .reading:
                return L10n.string("categoryReading")
            case .writing:
                return L10n.string("categoryWriting")
            case .notes:
                return L10n.string("categoryNotes")
            case .none:
                return L10n.string("categoryFlashcards")
            }
        }

        switch selectedTab {
        case .folders:
            return L10n.string("homeTabFolders")
        case .flashcards:
            return L10n.string("homeTabSets")
        case .create:
            return L10n.string("homeCreate")
        case .profile:
            return L10n.localized(.profileTitle)
        case .home, .none:
            return L10n.string("categoryFlashcards")
        }
    }

    func headerSubtitle(currentEmail: String) -> String {
        if selectedTab == nil || selectedTab == .home {
            switch selectedCategory {
            case .speaking:
                return L10n.string("homeSubtitleSpeaking")
            case .listening:
                return L10n.string("homeSubtitleListening")
            case .reading:
                return L10n.string("homeSubtitleReading")
            case .writing:
                return L10n.string("homeSubtitleWriting")
            case .notes:
                return L10n.string("homeSubtitleNotes")
            case .none:
                return L10n.string("homeSubtitleDefault")
            }
        }

        switch selectedTab {
        case .folders:
            return L10n.string("homeSubtitleFolders")
        case .flashcards:
            return L10n.string("homeSubtitleSets")
        case .create:
            return L10n.string("homeSubtitleCreate")
        case .profile:
            return currentEmail
        case .home, .none:
            return L10n.string("homeSubtitleDefault")
        }
    }

    // MARK: - Navigation actions

    func clearSelectedCategory() {
        guard selectedCategory != nil else { return }
        withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
            selectedCategory = nil
        }
    }

    func selectCategory(_ category: HomeCategory) {
        withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
            selectedTab = .home
            selectedCategory = category
        }
    }

    // MARK: - Daily stats

    func loadDailyStats() async {
        let speakingSeconds = await statsService.totalToday(skill: .speaking)
        let readingSeconds = await statsService.totalToday(skill: .reading)
        let writingWords = await statsService.totalToday(skill: .writing)
        let listeningMinutes = await listeningMinutesToday()

        dailyStats = [
            HomeDailyStat(
                id: .speaking,
                title: L10n.string("categorySpeaking"),
                value: "\(speakingSeconds / 60)",
                label: L10n.string("commonMinutes"),
                iconSystemName: HomeCategory.speaking.icon
            ),
            HomeDailyStat(
                id: .listening,
                title: L10n.string("categoryListening"),
                value: "\(listeningMinutes)",
                label: L10n.string("commonMinutes"),
                iconSystemName: HomeCategory.listening.icon
            ),
            HomeDailyStat(
                id: .reading,
                title: L10n.string("categoryReading"),
                value: "\(readingSeconds / 60)",
                label: L10n.string("commonMinutes"),
                iconSystemName: HomeCategory.reading.icon
            ),
            HomeDailyStat(
                id: .writing,
                title: L10n.string("categoryWriting"),
                value: "\(writingWords)",
                label: L10n.string("commonWords"),
                iconSystemName: HomeCategory.writing.icon
            )
        ]
    }

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

    @discardableResult
    func updateFolder(_ folder: Folder, title: String, description: String) async -> Bool {
        var updatedFolder = folder
        updatedFolder.title = title
        updatedFolder.description = description
        updatedFolder.updatedAt = Date()

        do {
            try await folderService.updateFolder(updatedFolder)

            if let index = folders.firstIndex(where: { $0.id == folder.id }) {
                folders[index] = updatedFolder
            }

            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
