import SwiftUI
import Combine
import FirebaseAuth

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var todayGoal: HomeSetPreviewItem = HomeSetPreviewItem(
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

    @Published var statCards: [StatCardItem] = []
    @Published var continueLearningSet: HomeSetPreviewItem?
    @Published var userSets: [HomeSetPreviewItem] = []
    @Published var isLoadingSets = false
    @Published var errorMessage: String?

    private let setService = FlashcardSetService()

    init() {
        loadStaticDashboardData()

        Task {
            await loadUserSets()
        }
    }

    func refresh() async {
        loadStaticDashboardData()
        await loadUserSets()
    }

    private func loadStaticDashboardData() {
        statCards = [
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
    }

    func loadUserSets() async {
        guard let user = Auth.auth().currentUser else {
            userSets = []
            continueLearningSet = nil
            errorMessage = "User is not signed in."
            return
        }

        isLoadingSets = true
        errorMessage = nil

        do {
            let sets = try await setService.fetchSets(for: user.uid)
            let previewItems = sets.map { makePreviewItem(from: $0) }

            userSets = previewItems
            continueLearningSet = previewItems.first

            isLoadingSets = false
        } catch {
            isLoadingSets = false
            errorMessage = error.localizedDescription
        }
    }

    private func makePreviewItem(from set: FlashcardSet) -> HomeSetPreviewItem {
        let theme = CreateSetTheme.theme(forHex: set.colorHex)

        return HomeSetPreviewItem(
            sourceSet: set,
            title: set.title,
            subtitle: set.description.isEmpty ? "\(set.cards.count) cards" : set.description,
            iconSystemName: iconName(from: set.icon),
            currentValue: 0,
            totalValue: max(set.cards.count, 1),
            unit: "cards",
            progress: 0,
            accentColor: theme.accent,
            backgroundColor: theme.previewBackground,
            progressBackgroundColor: theme.softAccent,
            titleColor: theme.titleColor,
            valueColor: theme.titleColor,
            subtitleColor: theme.mutedTextColor,
            iconBackground: theme.softAccent,
            blobColor: theme.softAccent
        )
    }

    private func iconName(from icon: SetIconType) -> String {
        switch icon {
        case .systemName(let name):
            return name
        default:
            return "rectangle.stack.fill"
        }
    }
    func deleteSet(_ set: HomeSetPreviewItem) async {
        guard let user = Auth.auth().currentUser else {
            errorMessage = "User is not signed in."
            return
        }

        guard let sourceSet = set.sourceSet else {
            errorMessage = "Set data is missing."
            return
        }

        do {
            try await setService.deleteSet(id: sourceSet.id, ownerUID: user.uid)

            userSets.removeAll { item in
                item.sourceSet?.id == sourceSet.id
            }

            if continueLearningSet?.sourceSet?.id == sourceSet.id {
                continueLearningSet = userSets.first
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
