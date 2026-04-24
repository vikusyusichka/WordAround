import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var sessionStore: SessionStore
    @StateObject private var viewModel = HomeViewModel()

    @State private var selectedCategory: HomeCategory? = nil
    @State private var selectedTab: HomeTab? = nil

    private var isPadLike: Bool {
        Layout.isPadLike
    }

    private var isCompactPhone: Bool {
        Layout.isCompactPhone
    }

    private var sidebarWidth: CGFloat {
        if isPadLike { return Layout.sidebarWidthPad }
        return isCompactPhone ? Layout.sidebarWidthCompact : Layout.sidebarWidthPhone
    }

    private var horizontalPadding: CGFloat {
        isPadLike ? Layout.screenHorizontalPaddingPad : Layout.screenHorizontalPaddingPhone
    }

    private var topSpacing: CGFloat {
        isPadLike ? Layout.topPaddingPad : Layout.topPaddingPhone
    }

    private var bottomBarBottomPadding: CGFloat {
        isPadLike ? 20 : 10
    }

    private var bottomSafeSpacing: CGFloat {
        isPadLike ? 132 : 118
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            backgroundLayer

            VStack(spacing: 0) {
                HomeHeaderView(
                    title: headerTitle,
                    subtitle: headerSubtitle
                )
                .padding(.top, topSpacing)
                .padding(.horizontal, horizontalPadding)

                HStack(alignment: .top, spacing: isPadLike ? 14 : 8) {
                    CategorySidebarView(selectedCategory: $selectedCategory)
                        .frame(width: sidebarWidth)

                    mainContent
                }
                .padding(.top, topSpacing)
                .padding(.horizontal, horizontalPadding)

                Spacer(minLength: bottomSafeSpacing)
            }

            BottomNavigationBar(
                selectedTab: $selectedTab,
                selectedCategory: $selectedCategory
            )
            .padding(.horizontal, isPadLike ? 28 : 14)
            .padding(.bottom, bottomBarBottomPadding)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

private extension HomeView {
    var headerTitle: String {
        switch selectedTab ?? .home {
        case .home:
            return "Flashcards"
        case .folders:
            return "Folders"
        case .flashcards:
            return "Sets"
        case .create:
            return "Create"
        case .profile:
            return "Profile"
        }
    }

    var headerSubtitle: String {
        switch selectedTab ?? .home {
        case .home:
            return "Pick a set to practice"
        case .folders:
            return "Manage your folders"
        case .flashcards:
            return "Manage your flashcard sets"
        case .create:
            return "Build a new study set"
        case .profile:
            return sessionStore.currentEmail
        }
    }

    var backgroundLayer: some View {
        ZStack {
            AppColors.appBackground
                .ignoresSafeArea()

            GeometryReader { proxy in
                let size = proxy.size

                BlobShape()
                    .fill(AppColors.blobBlue.opacity(0.45))
                    .frame(
                        width: isPadLike ? 180 : 120,
                        height: isPadLike ? 240 : 160
                    )
                    .rotationEffect(.degrees(18))
                    .position(
                        x: isPadLike ? 90 : 28,
                        y: size.height - (isPadLike ? 130 : 110)
                    )

                Circle()
                    .fill(AppColors.blobGreen.opacity(0.65))
                    .frame(width: isPadLike ? 16 : 12, height: isPadLike ? 16 : 12)
                    .position(
                        x: isPadLike ? 142 : 78,
                        y: size.height - (isPadLike ? 98 : 76)
                    )

                Circle()
                    .fill(AppColors.blobBlue.opacity(0.8))
                    .frame(width: isPadLike ? 14 : 10, height: isPadLike ? 14 : 10)
                    .position(
                        x: isPadLike ? 210 : 128,
                        y: size.height - (isPadLike ? 148 : 142)
                    )
            }
            .ignoresSafeArea()
        }
    }

    var mainContent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: isPadLike ? 16 : 12) {
                switch selectedTab ?? .home {
                case .home:
                    if let selectedCategory {
                        categoryPlaceholder(for: selectedCategory)
                    } else {
                        dashboardContent
                    }
                case .folders:
                    placeholderCard(
                        title: "Folders",
                        subtitle: "Тут буде список папок."
                    )

                case .flashcards:
                    placeholderCard(
                        title: "Flashcards",
                        subtitle: "Тут буде список сетів і папок."
                    )

                case .create:
                    placeholderCard(
                        title: "Create",
                        subtitle: "Тут буде створення нового сету."
                    )

                case .profile:
                    placeholderCard(
                        title: "Profile",
                        subtitle: sessionStore.currentEmail
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, isPadLike ? 18 : 8)
        }
    }

    var dashboardContent: some View {
        VStack(alignment: .leading, spacing: isPadLike ? 16 : 12) {
            todayGoalCard

            HStack(spacing: isPadLike ? 14 : 8) {
                ForEach(viewModel.statCards) { card in
                    StatCardView(item: card)
                }
            }

            sectionTitle("Continue learning")

            if let set = viewModel.continueLearningSet {
                learningProgressCard(from: set)
            }

            sectionHeader(title: "Your sets", actionTitle: "View all")

            VStack(spacing: isPadLike ? 14 : 10) {
                ForEach(viewModel.userSets) { set in
                    SetItemView(
                        title: set.title,
                        subtitle: set.subtitle,
                        iconSystemName: set.iconSystemName,
                        accentColor: set.accentColor,
                        titleColor: set.titleColor,
                        backgroundColor: set.backgroundColor,
                        trailingText: "Review",
                        blobColor: set.blobColor
                    )
                }
            }
        }
    }

    var todayGoalCard: some View {
        ProgressCardView(
            layout: .goal,
            title: "Today's goal",
            currentValue: viewModel.todayGoal.currentValue,
            totalValue: viewModel.todayGoal.totalValue,
            unit: viewModel.todayGoal.unit,
            subtitle: viewModel.todayGoal.subtitle,
            progress: viewModel.todayGoal.progress,
            tint: viewModel.todayGoal.accentColor,
            backgroundColor: viewModel.todayGoal.backgroundColor,
            progressBackgroundColor: viewModel.todayGoal.progressBackgroundColor,
            titleColor: viewModel.todayGoal.titleColor,
            valueColor: viewModel.todayGoal.valueColor,
            subtitleColor: viewModel.todayGoal.subtitleColor,
            iconSystemName: viewModel.todayGoal.iconSystemName,
            iconBackground: viewModel.todayGoal.iconBackground,
            blobColor: viewModel.todayGoal.blobColor
        )
    }

    func learningProgressCard(from set: FlashcardSet) -> some View {
        ProgressCardView(
            layout: .action,
            title: set.title,
            currentValue: set.currentValue,
            totalValue: set.totalValue,
            unit: set.unit,
            subtitle: set.subtitle,
            progress: set.progress,
            tint: set.accentColor,
            backgroundColor: set.backgroundColor,
            progressBackgroundColor: set.progressBackgroundColor,
            titleColor: set.titleColor,
            valueColor: set.valueColor,
            subtitleColor: set.subtitleColor,
            iconSystemName: set.iconSystemName,
            iconBackground: set.iconBackground,
            blobColor: set.blobColor,
            actionSystemName: "arrow.right"
        )
    }

    func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: isPadLike ? 34 : 22, weight: .bold, design: .rounded))
            .foregroundColor(AppColors.primaryBlueDark)
            .padding(.top, isPadLike ? 20 : 13)
    }

    func sectionHeader(title: String, actionTitle: String) -> some View {
        HStack(alignment: .center) {
            Text(title)
                .font(.system(size: isPadLike ? 34 : 22, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.primaryBlueDark)

            Spacer()

            Button(action: {}) {
                Text(actionTitle)
                    .font(.system(size: isPadLike ? 18 : 14, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.primaryBlue)
            }
            .buttonStyle(.plain)
        }
    }

    func categoryPlaceholder(for category: HomeCategory) -> some View {
        placeholderCard(
            title: category.title.capitalized,
            subtitle: "Тут буде контент вибраної категорії."
        )
    }

    func placeholderCard(title: String, subtitle: String) -> some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(Color.white.opacity(0.92))
            .overlay(
                VStack(alignment: .leading, spacing: 10) {
                    Text(title)
                        .font(.system(size: isPadLike ? 34 : 24, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.primaryBlueDark)

                    Text(subtitle)
                        .font(.system(size: isPadLike ? 18 : 15, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                }
                .padding(isPadLike ? 24 : 18),
                alignment: .topLeading
            )
            .frame(height: isPadLike ? 220 : 160)
    }
}

#Preview {
    HomeView()
        .environmentObject(SessionStore())
}
