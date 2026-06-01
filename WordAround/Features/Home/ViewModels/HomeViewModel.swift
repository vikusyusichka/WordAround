import SwiftUI
import Combine
import FirebaseAuth

@MainActor
final class HomeViewModel: ObservableObject {

    // MARK: - Stats (static placeholders until a real stats backend exists)

    @Published var todayGoal: HomeSetPreviewItem
    @Published var statCards: [StatCardItem] = []

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

    // MARK: - Static placeholders

    private static let staticStatCards: [StatCardItem] = [
        StatCardItem(
            title: "Learned today",
            value: "24",
            subtitle: "words",
            iconSystemName: "chart.bar.fill",
            accentColor: Color(red: 0.64, green: 0.54, blue: 0.98),
            titleColor: Color(red: 0.58, green: 0.47, blue: 0.98),
            valueColor: AppColors.primaryBlueDark,
            subtitleColor: AppColors.textSecondary,
            backgroundColor: Color(red: 0.96, green: 0.94, blue: 1.0),
            blobColor: Color(red: 0.86, green: 0.81, blue: 1.0)
        ),
        StatCardItem(
            title: "Accuracy",
            value: "87%",
            subtitle: "Great job!",
            iconSystemName: "target",
            accentColor: Color(red: 0.42, green: 0.80, blue: 0.67),
            titleColor: Color(red: 0.33, green: 0.73, blue: 0.58),
            valueColor: AppColors.primaryBlueDark,
            subtitleColor: Color(red: 0.10, green: 0.66, blue: 0.38),
            backgroundColor: Color(red: 0.93, green: 0.99, blue: 0.97),
            blobColor: Color(red: 0.77, green: 0.92, blue: 0.85)
        ),
        StatCardItem(
            title: "Streak",
            value: "5",
            subtitle: "days",
            iconSystemName: "flame.fill",
            accentColor: Color(red: 0.98, green: 0.68, blue: 0.20),
            titleColor: Color(red: 0.67, green: 0.36, blue: 0.02),
            valueColor: Color(red: 0.67, green: 0.36, blue: 0.02),
            subtitleColor: AppColors.textSecondary,
            backgroundColor: Color(red: 1.0, green: 0.96, blue: 0.89),
            blobColor: Color(red: 0.98, green: 0.86, blue: 0.62)
        )
    ]

    private static let staticTodayGoal = HomeSetPreviewItem(
        sourceSet: nil,
        title: "Today's goal",
        subtitle: "6 words left",
        iconSystemName: "book.closed",
        currentValue: 24,
        totalValue: 30,
        unit: "words",
        progress: 0.80,
        accentColor: AppColors.primaryBlue,
        backgroundColor: AppColors.goalBackground,
        progressBackgroundColor: AppColors.goalProgressBackground,
        titleColor: AppColors.primaryBlueDark,
        valueColor: AppColors.primaryBlueDark,
        subtitleColor: AppColors.textSecondary,
        iconBackground: .white,
        blobColor: Color(red: 0.82, green: 0.86, blue: 0.98)
    )

    // MARK: - Init

    init(
        folderService: FolderService? = nil,
        authService: AuthServiceProtocol? = nil
    ) {
        self.folderService = folderService ?? FolderService()
        self.authService = authService ?? AuthService()
        self.todayGoal = Self.staticTodayGoal
        self.statCards = Self.staticStatCards

        Task {
            await loadFolders()
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

    // MARK: - Folders

    func refresh() async {
        await loadFolders()
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
