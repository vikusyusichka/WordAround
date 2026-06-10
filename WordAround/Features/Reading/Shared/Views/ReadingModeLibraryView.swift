import SwiftUI

struct ReadingModeLibraryView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ReadingModeLibraryViewModel
    @State private var renameTarget: ReadingLibraryItem?
    @State private var renameDraft = ""
    @State private var deleteTarget: ReadingLibraryItem?

    init(mode: ReadingMode) {
        _viewModel = StateObject(wrappedValue: ReadingModeLibraryViewModel(mode: mode))
    }

    init(viewModel: ReadingModeLibraryViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    private var columns: [GridItem] {
        if Layout.isPadLike {
            [
                GridItem(.flexible(), spacing: Layout.readingModeGridSpacing),
                GridItem(.flexible(), spacing: Layout.readingModeGridSpacing)
            ]
        } else {
            [GridItem(.flexible())]
        }
    }

    var body: some View {
        ZStack {
            AppColors.appBackground.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: Layout.homeContentSpacing) {
                    headerCard

                    if !viewModel.isLoggedOut {
                        addButton
                    }

                    content
                }
                .frame(maxWidth: Layout.convContentMaxWidth)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, Layout.homeHorizontalPadding)
                .padding(.top, Layout.homeTopSpacing)
                .padding(.bottom, Layout.homeBottomSafeSpacing)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .task { await viewModel.loadItems() }
        .navigationDestination(isPresented: $viewModel.isShowingSetup) {
            if let config = ReadingSetupConfig.make(forModeID: viewModel.mode.id) {
                ReadingSetupView(config: config)
            }
        }
        .navigationDestination(isPresented: $viewModel.isShowingSetCreation) {
            ReadingFromSetCreationView(mode: viewModel.mode)
        }
        .navigationDestination(item: $viewModel.selectedItem) { item in
            if viewModel.usesSetCreationFlow {
                ReadingSessionView(item: item)
            } else if viewModel.usesStoryItemFlow {
                StorySessionView(
                    item: item,
                    onExitToSetup: { viewModel.selectedItem = nil },
                    onExitToReading: { viewModel.selectedItem = nil }
                )
            } else if viewModel.usesSpeedItemFlow {
                SpeedReadingCountdownView(
                    item: item,
                    onExitToSetup: { viewModel.selectedItem = nil },
                    onExitToReading: { viewModel.selectedItem = nil }
                )
            } else {
                ReadingPostSetupRouterView(
                    setup: viewModel.sessionSetup(for: item),
                    onExitToSetup: { viewModel.selectedItem = nil },
                    onExitToReading: { viewModel.selectedItem = nil }
                )
            }
        }
        .onChange(of: viewModel.selectedItem) { _, newValue in
            if newValue == nil { Task { await viewModel.refresh() } }
        }
        .onChange(of: viewModel.isShowingSetCreation) { _, newValue in
            if newValue == false { Task { await viewModel.refresh() } }
        }
        .onChange(of: viewModel.isShowingSetup) { _, newValue in
            if newValue == false { Task { await viewModel.refresh() } }
        }
        .alert(L10n.string("readingRenameReading"), isPresented: Binding(
            get: { renameTarget != nil },
            set: { if !$0 { renameTarget = nil } }
        )) {
            TextField(L10n.string("commonTitle"), text: $renameDraft)
            Button(L10n.localized(.commonCancel), role: .cancel) { renameTarget = nil }
            Button(L10n.localized(.commonSave)) {
                if let target = renameTarget {
                    viewModel.renameItem(target, newTitle: renameDraft)
                }
                renameTarget = nil
            }
        }
        .confirmationDialog(
            deleteTarget.map { "Delete \"\($0.title)\"?" } ?? "Delete this item?",
            isPresented: Binding(
                get: { deleteTarget != nil },
                set: { if !$0 { deleteTarget = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(L10n.string("commonDelete"), role: .destructive) {
                if let target = deleteTarget { viewModel.deleteItem(target) }
                deleteTarget = nil
            }
            Button(L10n.string("commonCancel"), role: .cancel) { deleteTarget = nil }
        } message: {
            Text(L10n.string("commonCantBeUndone"))
        }
        .fullScreenCover(item: $viewModel.presentedSet) { set in
            FlashcardSetDetailView(set: set)
        }
        .alert(
            "Set unavailable",
            isPresented: Binding(
                get: { viewModel.sourceSetUnavailableMessage != nil },
                set: { if !$0 { viewModel.sourceSetUnavailableMessage = nil } }
            ),
            presenting: viewModel.sourceSetUnavailableMessage
        ) { _ in
            Button(L10n.string("commonOK"), role: .cancel) { viewModel.sourceSetUnavailableMessage = nil }
        } message: { message in
            Text(message)
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            ReadingSetupHeaderView(
                title: viewModel.title,
                subtitle: viewModel.subtitle,
                accent: viewModel.accent,
                accentDark: viewModel.accentDark,
                onBack: { dismiss() }
            )

            if !viewModel.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: viewModel.icon)
                        .font(.system(size: 11, weight: .bold))
                    Text(viewModel.savedCountText)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                }
                .foregroundColor(viewModel.accent)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(viewModel.accent.opacity(0.12))
                .clipShape(Capsule())
                .padding(.leading, 2)
            }
        }
        .padding(.bottom, 4)
    }

    private var addButton: some View {
        ReadingPrimaryButton(
            title: viewModel.addButtonTitle,
            icon: viewModel.addButtonIcon,
            accent: viewModel.accent,
            accentDark: viewModel.accentDark
        ) {
            viewModel.handleAddTapped()
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoggedOut {
            PracticeLibraryLoggedOutView(
                title: L10n.string("readingSignInToSeeLibrary"),
                message: L10n.string("readingSignInToSeeLibraryMessage"),
                accent: viewModel.accent,
                accentDark: viewModel.accentDark
            )
        } else if viewModel.isLoading {
            PracticeLibraryLoadingView(message: L10n.string("readingLoadingLibrary"), accent: viewModel.accent)
        } else if let error = viewModel.errorMessage {
            PracticeLibraryErrorView(
                message: error,
                accent: viewModel.accent,
                accentDark: viewModel.accentDark,
                onRetry: { Task { await viewModel.loadItems() } }
            )
        } else if viewModel.isEmpty {
            ReadingLibraryEmptyStateView(
                title: viewModel.emptyTitle,
                subtitle: viewModel.emptySubtitle,
                systemImage: viewModel.icon,
                accent: viewModel.accent,
                accentDark: viewModel.accentDark,
                addTitle: viewModel.addButtonTitle,
                addIcon: viewModel.addButtonIcon,
                onAdd: { viewModel.handleAddTapped() }
            )
        } else {
            savedItemsSection
        }
    }

    private var savedItemsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.string("readingSaved"))
                .font(.system(size: Layout.homeSectionTitleSize, weight: .bold, design: .rounded))
                .foregroundColor(viewModel.accentDark)
                .padding(.top, Layout.homeSectionTitleTopPadding)

            LazyVGrid(columns: columns, spacing: Layout.readingModeGridSpacing) {
                ForEach(viewModel.items) { item in
                    ReadingLibraryItemCardView(
                        item: item,
                        accent: viewModel.accent,
                        accentDark: viewModel.accentDark,
                        systemImage: viewModel.icon,
                        onOpen: { viewModel.openItem(item) },
                        onDelete: { deleteTarget = item },
                        onRename: viewModel.supportsRename ? {
                            renameTarget = item
                            renameDraft = item.title
                        } : nil,
                        onOpenSourceSet: viewModel.usesSetCreationFlow
                            ? { viewModel.openSourceSet(for: item) }
                            : nil
                    )
                }
            }
        }
    }

}

#Preview("With items") {
    let mode = ReadingMode(
        id: "story-mode",
        title: L10n.string("storyModeTitle"),
        subtitle: L10n.string("readingStoryModeSubtitle"),
        systemImage: "books.vertical.fill",
        accentColor: ReadingSetupConfig.storyMode.accent,
        blobColor: AppColors.blobPink
    )
    let mock = MockReadingStorageService(items: [
        ReadingLibraryItem(userId: "u", modeID: "story-mode", title: "A Morning in the City",
                           preview: "The streets were quiet as the first light touched the rooftops…",
                           difficulty: "B1", estimatedMinutes: 4, progress: 0.4,
                           comprehensionScore: 0.8, tags: ["Travel"], status: .inProgress),
        ReadingLibraryItem(userId: "u", modeID: "story-mode", title: "The Lighthouse Keeper",
                           preview: "Every night he climbed the spiral stairs to light the lamp.",
                           difficulty: "B2", estimatedMinutes: 6, status: .new)
    ])
    return NavigationStack {
        ReadingModeLibraryView(viewModel: ReadingModeLibraryViewModel(
            mode: mode, storage: mock, currentUserId: { "preview-user" }
        ))
    }
}

#Preview("Empty") {
    let mode = ReadingMode(
        id: "story-mode", title: L10n.string("storyModeTitle"),
        subtitle: L10n.string("readingStoryShortSubtitle"),
        systemImage: "books.vertical.fill",
        accentColor: ReadingSetupConfig.storyMode.accent,
        blobColor: AppColors.blobPink
    )
    return NavigationStack {
        ReadingModeLibraryView(viewModel: ReadingModeLibraryViewModel(
            mode: mode, storage: MockReadingStorageService(), currentUserId: { "preview-user" }
        ))
    }
}
