import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var sessionStore: SessionStore
    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var setsViewModel = SetsListViewModel()

    @State private var isCreateSetPresented = false
    @State private var isCreateFolderPresented = false
    @State private var isWritingSetSelectionPresented = false
    @State private var isAddTextPresented = false
    @State private var isImportAudioPresented = false
    @State private var isEssayPracticePresented = false

    @State private var isTipSheetPresented = false
    @State private var isGuideSheetPresented = false
    @State private var isStreakSheetPresented = false

    @State private var selectedSetForDetails: FlashcardSet?
    @State private var selectedSetForWriting: FlashcardSet?
    @State private var selectedFolderForDetails: Folder?

    var body: some View {
        ZStack(alignment: .bottom) {
            backgroundLayer
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HomeHeaderView(
                    title: viewModel.headerTitle,
                    subtitle: viewModel.headerSubtitle(currentEmail: sessionStore.currentEmail)
                )
                .padding(.top, Layout.homeTopSpacing)
                .padding(.horizontal, Layout.homeHorizontalPadding)

                HStack(alignment: .top, spacing: Layout.homeHeaderSidebarSpacing) {
                    CategorySidebarView(
                        selectedCategory: $viewModel.selectedCategory,
                        onSelect: { viewModel.selectCategory($0) }
                    )
                    .frame(width: Layout.homeSidebarWidth)

                    mainContent
                }
                .padding(.top, Layout.homeTopSpacing)
                .padding(.horizontal, Layout.homeHorizontalPadding)

                Spacer(minLength: Layout.homeBottomSafeSpacing)
            }

            if viewModel.isCreateMenuPresented {
                createMenuOverlay
                    .transition(.opacity)
                    .zIndex(1)
            }

            BottomNavigationBar(
                selectedTab: $viewModel.selectedTab,
                isCreateMenuPresented: $viewModel.isCreateMenuPresented,
                onSelectTab: { tab in
                    if tab == .home { viewModel.clearSelectedCategory() }
                }
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
        .fullScreenCover(isPresented: $isWritingSetSelectionPresented) {
            writingSetSelectionCover
        }
        .fullScreenCover(isPresented: $isAddTextPresented) {
            NavigationStack {
                ReadingAddTextView()
            }
        }
        .fullScreenCover(isPresented: $isImportAudioPresented) {
            NavigationStack {
                ImportAudioSetupView(onExitToListening: { isImportAudioPresented = false })
            }
        }
        .fullScreenCover(isPresented: $isEssayPracticePresented) {
            NavigationStack {
                EssayPracticeView()
            }
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
        .fullScreenCover(item: $selectedSetForWriting) { set in
            WriteWordsView(set: set)
        }
        .fullScreenCover(item: $selectedFolderForDetails) { folder in
            FolderDetailView(folder: folder)
        }
        .sheet(isPresented: $isTipSheetPresented) {
            HomeTipSheet(tip: viewModel.dailyTip)
        }
        .sheet(isPresented: $isGuideSheetPresented) {
            HomeGuideSheet()
        }
        .sheet(isPresented: $isStreakSheetPresented) {
            HomeStreakSheet(state: viewModel.streakState)
        }
        .task {
            await refreshData()
        }
        .onChange(of: isCreateSetPresented) { _, isPresented in
            refreshIfDismissed(isPresented)
        }
        .onChange(of: isCreateFolderPresented) { _, isPresented in
            refreshIfDismissed(isPresented)
        }
        .onChange(of: viewModel.isCreateMenuPresented) { _, _ in
            viewModel.clearSelectedCategory()
        }
    }
}

// MARK: - Main Content

private extension HomeView {
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
                switch viewModel.selectedTab ?? .home {
                case .home:
                    if viewModel.selectedCategory == .writing {
                        writingContent
                    } else if viewModel.selectedCategory == .speaking {
                        SpeakingView()
                    } else if viewModel.selectedCategory == .reading {
                        ReadingView()
                    } else if viewModel.selectedCategory == .listening {
                        ListeningView()
                    } else if viewModel.selectedCategory == .notes {
                        GrammarNotesHomeView()
                    } else if let category = viewModel.selectedCategory {
                        categoryPlaceholder(for: category)
                    } else {
                        dashboardContent
                    }

                case .folders:
                    foldersContent

                case .flashcards:
                    setsContent

                case .create:
                    placeholderCard(
                        title: L10n.string("homeCreate"),
                        subtitle: L10n.string("homeCreatePlaceholderSubtitle")
                    )

                case .profile:
                    ProfileView()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, Layout.homeScrollBottomPadding)
        }
    }

    var dashboardContent: some View {
        VStack(alignment: .leading, spacing: Layout.homeContentSpacing) {
            sectionTitle(L10n.string("homeDailyPractice"))

            HomeStatsGridView(stats: viewModel.dailyStats)

            HomeDashboardSection(
                continueItem: ContinueLearningItem(set: setsViewModel.continueLearningSet),
                tip: viewModel.dailyTip,
                streak: viewModel.streakState,
                onNote: {
                    viewModel.selectCategory(.notes)
                },
                onContinue: {
                    if let set = setsViewModel.continueLearningSet?.sourceSet {
                        selectedSetForDetails = set
                    } else {
                        viewModel.selectedTab = .flashcards
                        viewModel.selectedCategory = nil
                    }
                },
                onTip: { isTipSheetPresented = true },
                onGuide: { isGuideSheetPresented = true },
                onStreak: { isStreakSheetPresented = true }
            )
            .padding(.top, Layout.homeContentSpacing)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Writing

private extension HomeView {
    var writingContent: some View {
        WritingView {
            isWritingSetSelectionPresented = true
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
                placeholderCard(title: L10n.string("homeLoadingTitle"), subtitle: L10n.string("homeLoadingFolders"))
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
                    },
                    onUpdate: { folder, title, description in
                        await viewModel.updateFolder(folder, title: title, description: description)
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

// MARK: - Helpers

private extension HomeView {
    func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: Layout.homeSectionTitleSize, weight: .bold, design: .rounded))
            .foregroundColor(AppColors.primaryBlueDark)
            .padding(.top, Layout.homeSectionTitleTopPadding)
    }

    func categoryPlaceholder(for category: HomeCategory) -> some View {
        placeholderCard(
            title: category.title.capitalized,
            subtitle: L10n.string("homeCategoryPlaceholderSubtitle")
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

    func refreshIfDismissed(_ isPresented: Bool) {
        guard !isPresented else { return }
        Task { await refreshData() }
    }

    var writingSetSelectionCover: some View {
        WritingSetSelectionView(sets: setsViewModel.userSets.compactMap(\.sourceSet)) { set in
            isWritingSetSelectionPresented = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                selectedSetForWriting = set
            }
        }
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
                        viewModel.isCreateMenuPresented = false
                    }
                }

            VStack {
                Spacer()

                ZStack {
                    createMenuItem(
                        icon: "folder.fill",
                        title: L10n.string("homeCreateFolder"),
                        xOffset: Layout.homeCreateFolderOffset.width,
                        yOffset: Layout.homeCreateFolderOffset.height,
                        delay: 0.04
                    ) {
                        isCreateFolderPresented = true
                    }

                    createMenuItem(
                        icon: "square.stack.3d.up.fill",
                        title: L10n.string("homeCreateSet"),
                        xOffset: Layout.homeCreateSetOffset.width,
                        yOffset: Layout.homeCreateSetOffset.height,
                        delay: 0.10
                    ) {
                        isCreateSetPresented = true
                    }

                    createMenuItem(
                        icon: "doc.text.fill",
                        title: L10n.string("homeCreateText"),
                        xOffset: 0,
                        yOffset: Layout.homeCreateTextOffset.height,
                        delay: 0.16
                    ) {
                        isAddTextPresented = true
                    }

                    createMenuItem(
                        icon: "waveform",
                        title: L10n.string("homeCreateAudio"),
                        xOffset: Layout.homeCreateAudioOffset.width,
                        yOffset: Layout.homeCreateSetOffset.height,
                        delay: 0.22
                    ) {
                        isImportAudioPresented = true
                    }

                    createMenuItem(
                        icon: "pencil.and.scribble",
                        title: L10n.string("homeCreateEssay"),
                        xOffset: Layout.homeCreateEssayOffset.width,
                        yOffset: Layout.homeCreateFolderOffset.height,
                        delay: 0.28
                    ) {
                        isEssayPracticePresented = true
                    }
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
                viewModel.isCreateMenuPresented = false
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
        .scaleEffect(viewModel.isCreateMenuPresented ? 1.0 : 0.2)
        .opacity(viewModel.isCreateMenuPresented ? 1.0 : 0.0)
        .offset(
            x: viewModel.isCreateMenuPresented ? xOffset : 0,
            y: viewModel.isCreateMenuPresented ? yOffset : 0
        )
        .animation(
            .interpolatingSpring(
                mass: 1.0,
                stiffness: 90,
                damping: 18,
                initialVelocity: 0
            )
            .delay(delay),
            value: viewModel.isCreateMenuPresented
        )
    }
}

#Preview {
    HomeView()
        .environmentObject(SessionStore())
}
