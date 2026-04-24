import SwiftUI
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var todayGoal: FlashcardSet = FlashcardSet(
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
    @Published var continueLearningSet: FlashcardSet?
    @Published var userSets: [FlashcardSet] = []

    init() {
        loadDashboard()
    }

    func loadDashboard() {
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

        continueLearningSet = FlashcardSet(
            title: "Food",
            subtitle: "In progress",
            iconSystemName: "fork.knife",
            currentValue: 18,
            totalValue: 30,
            unit: "words",
            progress: 0.68,
            accentColor: AppColors.foodAccent,
            backgroundColor: AppColors.foodBackground,
            progressBackgroundColor: Color(red: 0.96, green: 0.84, blue: 0.85),
            titleColor: AppColors.foodTitle,
            valueColor: AppColors.foodTitle,
            subtitleColor: AppColors.textSecondary,
            iconBackground: Color(red: 0.99, green: 0.50, blue: 0.51),
            blobColor: Color(red: 0.98, green: 0.82, blue: 0.84)
        )

        userSets = [
            FlashcardSet(
                title: "Relatives",
                subtitle: "18 words",
                iconSystemName: "person.3.fill",
                currentValue: 18,
                totalValue: 18,
                unit: "words",
                progress: 1.0,
                accentColor: AppColors.orangeAccent,
                backgroundColor: Color(red: 0.97, green: 0.94, blue: 0.89),
                progressBackgroundColor: Color(red: 0.96, green: 0.86, blue: 0.62),
                titleColor: AppColors.orangeTitle,
                valueColor: AppColors.orangeTitle,
                subtitleColor: AppColors.textSecondary,
                iconBackground: AppColors.orangeAccent,
                blobColor: Color(red: 0.96, green: 0.86, blue: 0.62)
            ),
            FlashcardSet(
                title: "Travel",
                subtitle: "24 words",
                iconSystemName: "suitcase.fill",
                currentValue: 24,
                totalValue: 24,
                unit: "words",
                progress: 1.0,
                accentColor: AppColors.greenAccent,
                backgroundColor: Color(red: 0.93, green: 0.98, blue: 0.95),
                progressBackgroundColor: Color(red: 0.80, green: 0.93, blue: 0.84),
                titleColor: AppColors.greenTitle,
                valueColor: AppColors.greenTitle,
                subtitleColor: AppColors.textSecondary,
                iconBackground: AppColors.greenAccent,
                blobColor: Color(red: 0.80, green: 0.93, blue: 0.84)
            )
        ]
    }
}
