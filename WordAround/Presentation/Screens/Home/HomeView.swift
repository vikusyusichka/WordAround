import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var sessionStore: SessionStore
    @State private var selectedCategory: HomeCategory? = nil
    @State private var selectedTab: HomeTab? = nil

    private var screenWidth: CGFloat {
        UIScreen.main.bounds.width
    }

    private var isPadLike: Bool {
        UIDevice.current.userInterfaceIdiom == .pad || screenWidth >= 700
    }

    private var isCompactPhone: Bool {
        !isPadLike && screenWidth < 390
    }

    private var sidebarWidth: CGFloat {
        if isPadLike { return 96 }
        return isCompactPhone ? 64 : 74
    }

    private var horizontalPadding: CGFloat {
        isPadLike ? 24 : 12
    }

    private var topSpacing: CGFloat {
        isPadLike ? 18 : 10
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
                HomeHeaderView()
                    .padding(.top, topSpacing)
                    .padding(.horizontal, horizontalPadding)

                HStack(alignment: .top, spacing: isPadLike ? 14 : 8) {
                    CategorySidebarView(selectedCategory: $selectedCategory)
                        .frame(width: sidebarWidth)

                    mainContent
                }
                .padding(.top, isPadLike ? 18 : 10)
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
    var backgroundLayer: some View {
        ZStack {
            Color(red: 0.965, green: 0.965, blue: 0.985)
                .ignoresSafeArea()

            GeometryReader { proxy in
                let size = proxy.size

                BlobShape()
                    .fill(Color(red: 0.84, green: 0.88, blue: 0.98).opacity(0.45))
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
                    .fill(Color(red: 0.78, green: 0.91, blue: 0.82).opacity(0.65))
                    .frame(width: isPadLike ? 16 : 12, height: isPadLike ? 16 : 12)
                    .position(
                        x: isPadLike ? 142 : 78,
                        y: size.height - (isPadLike ? 98 : 76)
                    )

                Circle()
                    .fill(Color(red: 0.80, green: 0.88, blue: 0.95).opacity(0.8))
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

                case .flashcards:
                    flashcardsPlaceholder

                case .create:
                    createPlaceholder

                case .profile:
                    profilePlaceholder
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, isPadLike ? 18 : 8)
        }
    }

    var dashboardContent: some View {
        VStack(alignment: .leading, spacing: isPadLike ? 16 : 12) {
            ProgressCardView(
                layout: .goal,
                title: "Today's goal",
                valueText: "24 / 30 words",
                subtitle: "6 words left",
                progress: 0.80,
                tint: Color(red: 0.17, green: 0.36, blue: 0.98),
                backgroundColor: Color(red: 0.95, green: 0.96, blue: 1.0),
                progressBackgroundColor: Color(red: 0.85, green: 0.88, blue: 0.97),
                titleColor: Color(red: 0.13, green: 0.29, blue: 0.82),
                valueColor: Color(red: 0.12, green: 0.28, blue: 0.80),
                subtitleColor: Color(red: 0.55, green: 0.59, blue: 0.70),
                iconSystemName: "book.closed",
                iconBackground: Color.white,
                blobColor: Color(red: 0.82, green: 0.86, blue: 0.98)
            )

            HStack(spacing: isPadLike ? 14 : 8) {
                ForEach(statCards) { card in
                    StatCardView(item: card)
                }
            }

            sectionTitle("Continue learning")

            continueLearningCard

            sectionHeader(title: "Your sets", actionTitle: "View all")

            VStack(spacing: isPadLike ? 14 : 10) {
                SetItemView(
                    title: "Relatives",
                    subtitle: "18 words",
                    iconSystemName: "person.3.fill",
                    accentColor: Color(red: 0.97, green: 0.64, blue: 0.06),
                    backgroundColor: Color(red: 0.97, green: 0.94, blue: 0.89),
                    trailingText: "Review",
                    blobColor: Color(red: 0.96, green: 0.86, blue: 0.62)
                )

                SetItemView(
                    title: "Travel",
                    subtitle: "24 words",
                    iconSystemName: "suitcase.fill",
                    accentColor: Color(red: 0.16, green: 0.73, blue: 0.40),
                    backgroundColor: Color(red: 0.93, green: 0.98, blue: 0.95),
                    trailingText: "Review",
                    blobColor: Color(red: 0.80, green: 0.93, blue: 0.84)
                )
            }
        }
    }

    var statCards: [StatCardItem] {
        [
            StatCardItem(
                title: "Learned today",
                value: "24",
                subtitle: "words",
                iconSystemName: "chart.bar.fill",
                accentColor: Color(red: 0.64, green: 0.54, blue: 0.98),
                titleColor: Color(red: 0.58, green: 0.47, blue: 0.98),
                valueColor: Color(red: 0.10, green: 0.28, blue: 0.82),
                subtitleColor: Color(red: 0.52, green: 0.58, blue: 0.69),
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
                valueColor: Color(red: 0.10, green: 0.28, blue: 0.82),
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
                subtitleColor: Color(red: 0.52, green: 0.58, blue: 0.69),
                backgroundColor: Color(red: 1.0, green: 0.96, blue: 0.89),
                blobColor: Color(red: 0.98, green: 0.86, blue: 0.62)
            )
        ]
    }
    var continueLearningCard: some View {
        ProgressCardView(
            layout: .action,
            title: "Food",
            valueText: "18 / 30 words",
            subtitle: "In progress",
            progress: 0.68,
            tint: Color(red: 1.0, green: 0.45, blue: 0.46),
            backgroundColor: Color(red: 1.0, green: 0.94, blue: 0.95),
            progressBackgroundColor: Color(red: 0.96, green: 0.84, blue: 0.85),
            titleColor: Color(red: 0.63, green: 0.11, blue: 0.21),
            valueColor: Color(red: 0.63, green: 0.11, blue: 0.21),
            subtitleColor: Color(red: 0.52, green: 0.58, blue: 0.69),
            iconSystemName: "fork.knife",
            iconBackground: Color(red: 0.99, green: 0.50, blue: 0.51),
            blobColor: Color(red: 0.98, green: 0.82, blue: 0.84),
            actionSystemName: "arrow.right"
        )
    }

    func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: isPadLike ? 34 : 22, weight: .bold, design: .rounded))
            .foregroundColor(Color(red: 0.13, green: 0.29, blue: 0.82))
            .padding(.top, isPadLike ? 20 : 13)
    }

    func sectionHeader(title: String, actionTitle: String) -> some View {
        HStack(alignment: .center) {
            Text(title)
                .font(.system(size: isPadLike ? 34 : 22, weight: .bold, design: .rounded))
                .foregroundColor(Color(red: 0.13, green: 0.29, blue: 0.82))

            Spacer()

            Button(action: {}) {
                Text(actionTitle)
                    .font(.system(size: isPadLike ? 18 : 14, weight: .medium, design: .rounded))
                    .foregroundColor(Color(red: 0.14, green: 0.35, blue: 1.0))
            }
            .buttonStyle(.plain)
        }
    }

    func categoryPlaceholder(for category: HomeCategory) -> some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(Color.white.opacity(0.92))
            .overlay(
                VStack(alignment: .leading, spacing: 10) {
                    Text(categoryTitle(for: category))
                        .font(.system(size: isPadLike ? 34 : 24, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.13, green: 0.29, blue: 0.82))

                    Text("Тут буде контент вибраної категорії.")
                        .font(.system(size: isPadLike ? 18 : 15, weight: .medium, design: .rounded))
                        .foregroundColor(Color(red: 0.50, green: 0.56, blue: 0.67))
                }
                .padding(isPadLike ? 24 : 18),
                alignment: .topLeading
            )
            .frame(height: isPadLike ? 220 : 160)
    }

    var flashcardsPlaceholder: some View {
        placeholderCard(title: "Flashcards", subtitle: "Тут буде список сетів і папок.")
    }

    var createPlaceholder: some View {
        placeholderCard(title: "Create", subtitle: "Тут буде створення нового сету.")
    }

    var profilePlaceholder: some View {
        placeholderCard(title: "Profile", subtitle: "Тут буде профіль користувача.")
    }

    func placeholderCard(title: String, subtitle: String) -> some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(Color.white.opacity(0.92))
            .overlay(
                VStack(alignment: .leading, spacing: 10) {
                    Text(title)
                        .font(.system(size: isPadLike ? 34 : 24, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.13, green: 0.29, blue: 0.82))

                    Text(subtitle)
                        .font(.system(size: isPadLike ? 18 : 15, weight: .medium, design: .rounded))
                        .foregroundColor(Color(red: 0.50, green: 0.56, blue: 0.67))
                }
                .padding(isPadLike ? 24 : 18),
                alignment: .topLeading
            )
            .frame(height: isPadLike ? 220 : 160)
    }

    func categoryTitle(for category: HomeCategory) -> String {
        switch category {
        case .speaking:
            return "Speaking"
        case .listening:
            return "Listening"
        case .reading:
            return "Reading"
        case .writing:
            return "Writing"
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(SessionStore())
}
