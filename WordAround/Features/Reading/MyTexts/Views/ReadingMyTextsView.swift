import SwiftUI

struct ReadingMyTextsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @StateObject private var viewModel = ReadingMyTextsViewModel()

    @State private var renameTarget: ReadingUserText?
    @State private var renameDraft = ""
    @State private var deleteTarget: ReadingUserText?

    private let accent = ReadingMyTextsTheme.accent
    private let accentDark = ReadingMyTextsTheme.accentDark

    private var savedTextsColumnCount: Int {
        if horizontalSizeClass == .compact { return 1 }
        return Layout.isPadLike ? 2 : 1
    }

    private var savedTextsColumns: [GridItem] {
        Array(
            repeating: GridItem(.flexible(), spacing: Layout.readingModeGridSpacing),
            count: savedTextsColumnCount
        )
    }

    var body: some View {
        ZStack {
            AppColors.appBackground.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: Layout.homeContentSpacing) {
                    ReadingSetupHeaderView(
                        title: L10n.string("readingModeMyTextsTitle"),
                        subtitle: L10n.string("readingMyTextsSubtitle"),
                        accent: accent,
                        accentDark: accentDark,
                        onBack: { dismiss() }
                    )
                    .padding(.bottom, 4)

                    if viewModel.isLoggedOut {
                        PracticeLibraryLoggedOutView(
                            title: L10n.string("readingSignInToSaveTexts"),
                            message: L10n.string("readingSignInToSaveTextsMessage"),
                            accent: accent,
                            accentDark: accentDark
                        )
                    }

                    if !viewModel.isLoggedOut {
                        addTextButton
                    }

                    libraryContent
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
        .task { await viewModel.loadTextsAsync() }
        .navigationDestination(isPresented: $viewModel.navigateToAddText) {
            ReadingAddTextView(
                onSavedAndStart: { text in
                    viewModel.navigateToAddText = false
                    Task { @MainActor in
                        viewModel.sessionText = text
                    }
                }
            )
        }
        .navigationDestination(item: $viewModel.sessionText) { text in
            ReadingSessionView(
                userText: text,
                onExitToLibrary: { viewModel.sessionText = nil }
            )
        }
        .onChange(of: viewModel.sessionText) { _, newValue in
            if newValue == nil { Task { await viewModel.loadTextsAsync() } }
        }
        .onChange(of: viewModel.navigateToAddText) { _, isShowing in
            if !isShowing { Task { await viewModel.loadTextsAsync() } }
        }
        .alert(L10n.string("readingRenameText"), isPresented: Binding(
            get: { renameTarget != nil },
            set: { if !$0 { renameTarget = nil } }
        )) {
            TextField(L10n.string("commonTitle"), text: $renameDraft)
            Button(L10n.localized(.commonCancel), role: .cancel) { renameTarget = nil }
            Button(L10n.localized(.commonSave)) {
                if let target = renameTarget {
                    viewModel.renameText(target, newTitle: renameDraft)
                }
                renameTarget = nil
            }
        }
        .confirmationDialog(
            deleteTarget.map { String(format: L10n.string("readingDeleteTextFmt"), $0.title) } ?? L10n.string("readingDeleteTextGeneric"),
            isPresented: Binding(
                get: { deleteTarget != nil },
                set: { if !$0 { deleteTarget = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(L10n.string("commonDelete"), role: .destructive) {
                if let target = deleteTarget { viewModel.deleteText(target) }
                deleteTarget = nil
            }
            Button(L10n.string("commonCancel"), role: .cancel) { deleteTarget = nil }
        } message: {
            Text(L10n.string("commonCantBeUndone"))
        }
    }

    @ViewBuilder
    private var libraryContent: some View {
        if viewModel.isLoading {
            PracticeLibraryLoadingView(message: L10n.string("readingLoadingTexts"), accent: accent)
        } else if let error = viewModel.errorMessage {
            PracticeLibraryErrorView(
                message: error,
                accent: accent,
                accentDark: accentDark,
                onRetry: { viewModel.retry() }
            )
        } else if viewModel.isEmpty {
            ReadingEmptyStateView {
                viewModel.showAddText()
            }
        } else {
            if let continueText = viewModel.continueReadingText {
                continueSection(continueText)
            }
            savedTextsSection
        }
    }

    private var addTextButton: some View {
        ReadingPrimaryButton(
            title: L10n.string("readingAddText"),
            icon: "plus",
            accent: accent,
            accentDark: accentDark
        ) {
            viewModel.showAddText()
        }
    }

    private func continueSection(_ text: ReadingUserText) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle(L10n.string("readingContinueReading"))
            ReadingContinueReadingCardView(
                title: text.title,
                languageTitle: text.languageTitle,
                levelTitle: text.levelTitle,
                progress: text.progress,
                lastOpenedText: text.lastOpenedText,
                onContinue: { viewModel.openText(text) }
            )
        }
        .padding(.top, Layout.homeSectionTitleTopPadding)
    }

    private var savedTextsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle(L10n.string("readingSavedTexts"))
                .padding(.top, viewModel.continueReadingText == nil ? Layout.homeSectionTitleTopPadding : 4)

            LazyVGrid(columns: savedTextsColumns, spacing: Layout.readingModeGridSpacing) {
                ForEach(viewModel.sortedTexts) { text in
                    ReadingTextCardView(
                        title: text.title,
                        preview: text.preview,
                        languageTitle: text.languageTitle,
                        levelTitle: text.levelTitle,
                        wordCount: text.wordCount,
                        progress: text.progress,
                        statusLabel: text.statusLabel,
                        dateText: text.dateText,
                        actionTitle: text.actionTitle,
                        onAction: { viewModel.openText(text) },
                        onDelete: { deleteTarget = text },
                        onRename: {
                            renameTarget = text
                            renameDraft = text.title
                        },
                        onMarkCompleted: text.isCompleted ? nil : { viewModel.markCompleted(text) }
                    )
                    .gridCellColumns(
                        viewModel.sortedTexts.count == 1 ? savedTextsColumnCount : 1
                    )
                }
            }
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: Layout.homeSectionTitleSize, weight: .bold, design: .rounded))
            .foregroundColor(accentDark)
    }

}

#Preview {
    NavigationStack {
        ReadingMyTextsView()
    }
}
