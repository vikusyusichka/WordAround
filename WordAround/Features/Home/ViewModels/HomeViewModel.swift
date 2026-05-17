import SwiftUI
import Combine
import FirebaseAuth

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var todayGoal: HomeSetPreviewItem
    @Published var statCards: [StatCardItem] = []
    @Published var folders: [Folder] = []
    @Published var isLoadingFolders = false
    @Published var errorMessage: String?

    private let folderService = FolderService()

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

    init() {
        todayGoal = Self.staticTodayGoal
        statCards = Self.staticStatCards

        Task {
            await loadFolders()
        }
    }

    func refresh() async {
        await loadFolders()
    }

    func loadFolders() async {
        guard let user = Auth.auth().currentUser else {
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
