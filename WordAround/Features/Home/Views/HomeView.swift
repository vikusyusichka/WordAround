import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var sessionStore: SessionStore
    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var setsViewModel = SetsListViewModel()

    @State private var selectedCategory: HomeCategory? = nil
    @State private var selectedTab: HomeTab? = nil

    @State private var isCreateMenuPresented = false
    @State private var isCreateSetPresented = false
    @State private var isCreateFolderPresented = false

    @State private var selectedSetForDetails: FlashcardSet?
    @State private var selectedFolderForDetails: Folder?

    var body: some View {
        ZStack(alignment: .bottom) {
            backgroundLayer
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HomeHeaderView(
                    title: headerTitle,
                    subtitle: headerSubtitle
                )
                .padding(.top, Layout.homeTopSpacing)
                .padding(.horizontal, Layout.homeHorizontalPadding)

                HStack(alignment: .top, spacing: Layout.homeHeaderSidebarSpacing) {
                    CategorySidebarView(selectedCategory: $selectedCategory)
                        .frame(width: Layout.homeSidebarWidth)

                    mainContent
                }
                .padding(.top, Layout.homeTopSpacing)
                .padding(.horizontal, Layout.homeHorizontalPadding)

                Spacer(minLength: Layout.homeBottomSafeSpacing)
            }

            if isCreateMenuPresented {
                createMenuOverlay
                    .transition(.opacity)
                    .zIndex(1)
            }

            BottomNavigationBar(
                selectedTab: $selectedTab,
                selectedCategory: $selectedCategory,
                isCreateMenuPresented: $isCreateMenuPresented
            )
            .padding(.horizontal, Layout.homeBottomBarHorizontalPadding)
            .padding(.bottom, Layout.homeBottomBarBottomPadding)
            .zIndex(2)
        }
        .ignoresSafeArea(edges: .bottom)
        .fullScreenCover(isPresented: $isCreateSetPresented) {
            CreateSetView()
        }
        .fullScreenCover(isPresented: $isCreateFolderPresented) {
            CreateFolderView()
        }
        .fullScreenCover(item: $selectedSetForDetails) { set in
            FlashcardSetDetailView(
                set: set,
                onSetChanged: { updatedSet in
                    setsViewModel.applyUpdatedSet(updatedSet)
                    selectedSetForDetails = updatedSet
                }
            )
        }
        .fullScreenCover(item: $selectedFolderForDetails) { folder in
            FolderDetailView(folder: folder)
        }
        .task {
            await refreshData()
        }
        .onChange(of: isCreateSetPresented) { isPresented in
            if !isPresented {
                Task {
                    await refreshData()
                }
            }
        }
        .onChange(of: isCreateFolderPresented) { isPresented in
            if !isPresented {
                Task {
                    await refreshData()
                }
            }
        }
    }
}

// MARK: - Main Content

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
                        width: Layout.homeBackgroundBlobSize.width,
                        height: Layout.homeBackgroundBlobSize.height
                    )
                    .rotationEffect(.degrees(18))
                    .position(
                        x: Layout.homeBackgroundBlobX,
                        y: size.height - Layout.homeBackgroundBlobBottomOffset
                    )

                Circle()
                    .fill(AppColors.blobGreen.opacity(0.65))
                    .frame(
                        width: Layout.homeBackgroundGreenDotSize,
                        height: Layout.homeBackgroundGreenDotSize
                    )
                    .position(
                        x: Layout.homeBackgroundGreenDotX,
                        y: size.height - Layout.homeBackgroundGreenDotBottomOffset
                    )

                Circle()
                    .fill(AppColors.blobBlue.opacity(0.8))
                    .frame(
                        width: Layout.homeBackgroundBlueDotSize,
                        height: Layout.homeBackgroundBlueDotSize
                    )
                    .position(
                        x: Layout.homeBackgroundBlueDotX,
                        y: size.height - Layout.homeBackgroundBlueDotBottomOffset
                    )
            }
            .ignoresSafeArea()
        }
        .drawingGroup()
    }

    var mainContent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: Layout.homeContentSpacing) {
                switch selectedTab ?? .home {
                case .home:
                    if let selectedCategory {
                        categoryPlaceholder(for: selectedCategory)
                    } else {
                        dashboardContent
                    }

                case .folders:
                    foldersContent

                case .flashcards:
                    setsContent

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
            .padding(.bottom, Layout.homeScrollBottomPadding)
        }
    }

    var dashboardContent: some View {
        VStack(alignment: .leading, spacing: Layout.homeContentSpacing) {
            todayGoalCard

            HStack(spacing: Layout.homeStatCardSpacing) {
                ForEach(viewModel.statCards) { card in
                    StatCardView(item: card)
                }
            }

            sectionTitle("Continue learning")

            if let set = setsViewModel.continueLearningSet {
                learningProgressCard(from: set)
            }

            SetsListView(
                title: "Your sets",
                actionTitle: "View all",
                sets: setsViewModel.userSets,
                isLoading: false,
                errorMessage: nil,
                showsEditButton: false,
                onAction: {
                    selectedTab = .flashcards
                    selectedCategory = nil
                },
                onSelect: { set in
                    selectedSetForDetails = set.sourceSet
                }
            )
        }
    }
}

// MARK: - Sets

private extension HomeView {
    var setsContent: some View {
        SetsListScreen(
            viewModel: setsViewModel,
            onCreate: {
                isCreateSetPresented = true
            },
            onSelect: { set in
                selectedSetForDetails = set.sourceSet
            }
        )
    }
}

// MARK: - Folders

private extension HomeView {
    var foldersContent: some View {
        VStack(alignment: .leading, spacing: Layout.homeContentSpacing) {
            if viewModel.isLoadingFolders {
                placeholderCard(title: "Loading", subtitle: "Loading your folders...")
            } else {
                FolderListView(
                    folders: viewModel.folders,
                    setsCount: { folder in
                        viewModel.setsCount(for: folder, in: setsViewModel.userSets)
                    },
                    onCreate: {
                        isCreateFolderPresented = true
                    },
                    onSelect: { folder in
                        selectedFolderForDetails = folder
                    },
                    onDelete: { folder in
                        Task {
                            await viewModel.deleteFolder(folder)
                        }
                    },
                    onMove: { source, destination in
                        viewModel.moveFolders(from: source, to: destination)
                    }
                )
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.system(size: Layout.homeErrorTextSize, weight: .semibold, design: .rounded))
                    .foregroundColor(.red)
                    .multilineTextAlignment(.leading)
                    .padding(.top, 4)
            }
        }
    }
}

// MARK: - Cards

private extension HomeView {
    var todayGoalCard: some View {
        ProgressCardView(
            layout: .goal,
            title: viewModel.todayGoal.title,
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

    func learningProgressCard(from set: HomeSetPreviewItem) -> some View {
        Button {
            selectedSetForDetails = set.sourceSet
        } label: {
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
        .buttonStyle(.plain)
    }
}

// MARK: - Helpers

private extension HomeView {
    func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: Layout.homeSectionTitleSize, weight: .bold, design: .rounded))
            .foregroundColor(AppColors.primaryBlueDark)
            .padding(.top, Layout.homeSectionTitleTopPadding)
    }

    func sectionHeader(title: String, actionTitle: String) -> some View {
        HStack(alignment: .center) {
            Text(title)
                .font(.system(size: Layout.homeSectionTitleSize, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.primaryBlueDark)

            Spacer()

            Button {
                if actionTitle == "Create" {
                    isCreateSetPresented = true
                } else if actionTitle == "Create Folder" {
                    isCreateFolderPresented = true
                } else if actionTitle == "View all" {
                    selectedTab = .flashcards
                    selectedCategory = nil
                }
            } label: {
                Text(actionTitle)
                    .font(.system(size: Layout.homeSectionActionSize, weight: .medium, design: .rounded))
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
                        .font(.system(size: Layout.homePlaceholderTitleSize, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.primaryBlueDark)

                    Text(subtitle)
                        .font(.system(size: Layout.homePlaceholderSubtitleSize, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                }
                .padding(Layout.homePlaceholderPadding),
                alignment: .topLeading
            )
            .frame(height: Layout.homePlaceholderHeight)
    }
}

private extension HomeView {
    func refreshData() async {
        await viewModel.refresh()
        await setsViewModel.refresh()
    }
}

// MARK: - Create Menu

private extension HomeView {
    var createMenuOverlay: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.36, dampingFraction: 0.82)) {
                        isCreateMenuPresented = false
                    }
                }

            VStack {
                Spacer()

                ZStack {
                    createMenuItem(
                        icon: "folder.fill",
                        title: "Folder",
                        xOffset: Layout.homeCreateFolderOffset.width,
                        yOffset: Layout.homeCreateFolderOffset.height,
                        delay: 0.04
                    ) {
                        isCreateFolderPresented = true
                    }

                    createMenuItem(
                        icon: "square.stack.3d.up.fill",
                        title: "Set",
                        xOffset: Layout.homeCreateSetOffset.width,
                        yOffset: Layout.homeCreateSetOffset.height,
                        delay: 0.10
                    ) {
                        isCreateSetPresented = true
                    }

                    createMenuItem(
                        icon: "doc.text.fill",
                        title: "Text",
                        xOffset: 0,
                        yOffset: Layout.homeCreateTextOffset.height,
                        delay: 0.16
                    )

                    createMenuItem(
                        icon: "waveform",
                        title: "Audio",
                        xOffset: Layout.homeCreateAudioOffset.width,
                        yOffset: Layout.homeCreateSetOffset.height,
                        delay: 0.22
                    )

                    createMenuItem(
                        icon: "pencil.and.scribble",
                        title: "Essay",
                        xOffset: Layout.homeCreateEssayOffset.width,
                        yOffset: Layout.homeCreateFolderOffset.height,
                        delay: 0.28
                    )
                }
                .frame(height: Layout.homeCreateMenuFrameHeight)
                .padding(.bottom, Layout.homeCreateMenuBottomPadding)
            }
        }
    }

    func createMenuItem(
        icon: String,
        title: String,
        xOffset: CGFloat,
        yOffset: CGFloat,
        delay: Double,
        action: @escaping () -> Void = {}
    ) -> some View {
        Button {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) {
                isCreateMenuPresented = false
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                action()
            }
        } label: {
            VStack(spacing: Layout.homeCreateMenuItemSpacing) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.98))
                        .frame(
                            width: Layout.homeCreateMenuCircleSize,
                            height: Layout.homeCreateMenuCircleSize
                        )
                        .shadow(
                            color: Color.black.opacity(0.10),
                            radius: Layout.homeCreateMenuShadowRadius,
                            x: 0,
                            y: Layout.homeCreateMenuShadowY
                        )

                    Image(systemName: icon)
                        .font(.system(size: Layout.homeCreateMenuIconSize, weight: .semibold))
                        .foregroundColor(Color(red: 0.17, green: 0.36, blue: 0.98))
                }

                Text(title)
                    .font(.system(size: Layout.homeCreateMenuTitleSize, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(red: 0.17, green: 0.36, blue: 0.98))
            }
            .frame(
                width: Layout.homeCreateMenuItemWidth,
                height: Layout.homeCreateMenuItemHeight
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .scaleEffect(isCreateMenuPresented ? 1.0 : 0.2)
        .opacity(isCreateMenuPresented ? 1.0 : 0.0)
        .offset(
            x: isCreateMenuPresented ? xOffset : 0,
            y: isCreateMenuPresented ? yOffset : 0
        )
        .animation(
            .interpolatingSpring(
                mass: 1.0,
                stiffness: 90,
                damping: 18,
                initialVelocity: 0
            )
            .delay(delay),
            value: isCreateMenuPresented
        )
    }
}

#Preview {
    HomeView()
        .environmentObject(SessionStore())
}
