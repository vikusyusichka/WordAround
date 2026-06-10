import SwiftUI
import FirebaseAuth

struct GrammarNotesHomeView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: GrammarNotesHomeViewModel
    @StateObject private var settings = GrammarNotesSettingsStore()
    @StateObject private var reviewVM: GrammarReviewViewModel
    @StateObject private var sessionVM: GrammarReviewSessionViewModel
    @State private var isCreateSheetPresented = false
    @State private var isSettingsPresented = false
    @State private var isQuickNoteSheetPresented = false
    @State private var isQuickMistakeSheetPresented = false
    @State private var isTemplateLibraryPresented = false
    @State private var isReviewSessionPresented = false
    @State private var editorNote: GrammarNote?
    @State private var isEditingTopics = false
    @State private var topicPendingDeletion: GrammarNoteTopic?
    @State private var isEmptyReviewAlertPresented = false

    private let theme: CreateSetTheme = .blue
    private let showsBackButton: Bool

    private var isPadLike: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    private var quickActionColumns: [GridItem] {
        if isPadLike {
            Array(repeating: GridItem(.flexible(), spacing: Layout.grammarNotesQuickActionSpacing), count: 4)
        } else {
            Array(repeating: GridItem(.flexible(), spacing: Layout.grammarNotesQuickActionSpacing), count: 2)
        }
    }

    @MainActor
    init(
        ownerUID: String? = Auth.auth().currentUser?.uid,
        showsBackButton: Bool = false
    ) {
        let uid = ownerUID ?? ""
        self.showsBackButton = showsBackButton
        _viewModel = StateObject(
            wrappedValue: GrammarNotesHomeViewModel(ownerUID: uid)
        )
        _reviewVM = StateObject(
            wrappedValue: GrammarReviewViewModel(ownerUID: uid)
        )
        _sessionVM = StateObject(
            wrappedValue: GrammarReviewSessionViewModel(ownerUID: uid)
        )
    }

    @MainActor
    init(viewModel: GrammarNotesHomeViewModel, showsBackButton: Bool = false) {
        self.showsBackButton = showsBackButton
        _viewModel = StateObject(wrappedValue: viewModel)
        _reviewVM = StateObject(
            wrappedValue: GrammarReviewViewModel(ownerUID: "")
        )
        _sessionVM = StateObject(
            wrappedValue: GrammarReviewSessionViewModel(ownerUID: "")
        )
    }

    var body: some View {
        ZStack {
            AppColors.appBackground
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: Layout.grammarNotesHomeSectionSpacing) {
                    if showsBackButton {
                        backButtonRow
                    }
                    toolbarRow
                    reviewSummaryCard
                    quickActionsRow
                    sectionHeader
                    contentView
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, isPadLike ? 12 : 8)
                .padding(.bottom, Layout.grammarNotesHomeScrollBottomPadding)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $isSettingsPresented) {
            GrammarNotesSettingsView()
        }
        .navigationDestination(item: $editorNote) { note in
            GrammarNoteEditorView(
                note: note,
                ownerUID: note.ownerUID,
                topicId: note.topicId,
                allowsQuiz: true
            )
        }
        .sheet(isPresented: $isCreateSheetPresented) {
            createTopicSheet
        }
        .sheet(isPresented: $isQuickNoteSheetPresented) {
            quickNoteSheet
        }
        .sheet(isPresented: $isQuickMistakeSheetPresented) {
            quickMistakeSheet
        }
        .sheet(isPresented: $isTemplateLibraryPresented) {
            GrammarTemplateLibraryView(
                kind: .topic,
                onSelectTopic: { template in
                    isTemplateLibraryPresented = false
                    Task {
                        let created = await viewModel.createTopicFromTemplate(template, settings: settings)
                        if created != nil { isCreateSheetPresented = false }
                    }
                },
                onSelectNote: nil,
                onCancel: { isTemplateLibraryPresented = false }
            )
        }
        .sheet(isPresented: $isReviewSessionPresented, onDismiss: {
            Task {
                await reviewVM.loadSummary(force: true)
                await reviewVM.loadHighlights()
            }
            sessionVM.reset()
        }) {
            GrammarReviewSessionView(
                viewModel: sessionVM,
                onDismiss: { isReviewSessionPresented = false },
                onOpenNote: { note in
                    isReviewSessionPresented = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        editorNote = note
                    }
                }
            )
        }
        .alert(L10n.string("notesNothingToReview"), isPresented: $isEmptyReviewAlertPresented) {
            Button(L10n.string("commonOK"), role: .cancel) { }
        } message: {
            Text(L10n.string("notesNothingToReviewMsg"))
        }
        .confirmationDialog(
            L10n.string("notesDeleteTopicQuestion"),
            isPresented: topicDeletionBinding,
            titleVisibility: .visible,
            presenting: topicPendingDeletion
        ) { topic in
            Button("Delete \"\(topic.title)\"", role: .destructive) {
                Task { await viewModel.deleteTopic(topic) }
                topicPendingDeletion = nil
            }
            Button(L10n.string("commonCancel"), role: .cancel) { topicPendingDeletion = nil }
        } message: { topic in
            Text("This topic and its \(topic.notesCount) note\(topic.notesCount == 1 ? "" : "s") will be permanently deleted. This cannot be undone.")
        }
        .task {
            await viewModel.loadTopics()
            await reviewVM.loadSummary()
            await reviewVM.loadHighlights()
        }
        .onAppear {
            Task {
                await viewModel.loadTopics()
                await reviewVM.loadSummary(force: true)
                await reviewVM.loadHighlights()
            }
        }
    }

    // MARK: - Review

    @ViewBuilder
    private var reviewSummaryCard: some View {
        let queue = reviewVM.previewQueue

        GrammarReviewSummaryView(
            summary: reviewVM.summary,
            isLoading: reviewVM.isLoadingSummary || reviewVM.isBuildingPreviewQueue,
            errorMessage: reviewVM.summaryError,
            queueCount: queue.count,
            estimatedMinutes: queue.estimatedMinutes,
            effectivePool: queue.isEmpty ? nil : queue.pool,
            onStart: startReviewSession,
            onRetry: { Task { await reviewVM.loadSummary(force: true) } }
        )
    }

    private func startReviewSession() {
        let queue = reviewVM.previewQueue

        #if DEBUG
        print("[Review] Start Review tapped — card showed pool=\(queue.pool?.rawValue ?? "nil") count=\(queue.count) ids=\(queue.cards.map { $0.id })")
        #endif

        guard !queue.isEmpty else {
            #if DEBUG
            print("[Review] queue is empty — showing alert")
            #endif
            isEmptyReviewAlertPresented = true
            return
        }

        sessionVM.startSession(prebuilt: queue)
        isReviewSessionPresented = true
    }

    // MARK: - Quick actions

    private var quickActionsRow: some View {
        LazyVGrid(columns: quickActionColumns, spacing: Layout.grammarNotesQuickActionSpacing) {
            quickActionButton(
                title: L10n.string("notesQuickNote"),
                systemImage: "square.and.pencil",
                action: { isQuickNoteSheetPresented = true }
            )
            quickActionButton(
                title: L10n.string("notesQuickMistake"),
                systemImage: "exclamationmark.bubble.fill",
                action: { isQuickMistakeSheetPresented = true }
            )
            quickActionButton(
                title: L10n.string("notesNewTopic"),
                systemImage: "folder.badge.plus",
                action: { isCreateSheetPresented = true }
            )
            quickActionButton(
                title: L10n.string("notesTemplates"),
                systemImage: "doc.on.doc.fill",
                action: { isTemplateLibraryPresented = true }
            )
        }
    }

    private func quickActionButton(
        title: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: isPadLike ? 8 : 6) {
                ZStack {
                    Circle()
                        .fill(AppColors.primaryBlue.opacity(0.12))
                        .frame(width: isPadLike ? 36 : 32, height: isPadLike ? 36 : 32)
                    Image(systemName: systemImage)
                        .font(.system(size: isPadLike ? 15 : 14, weight: .bold))
                        .foregroundStyle(AppColors.primaryBlue)
                }

                Text(title)
                    .font(.system(size: isPadLike ? 12 : 11, weight: .black, design: .rounded))
                    .foregroundStyle(AppColors.primaryBlueDark)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: Layout.grammarNotesQuickActionMinHeight)
            .padding(.horizontal, 8)
            .padding(.vertical, isPadLike ? 12 : 10)
            .background(quickActionBackground)
            .clipShape(RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.62), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.045), radius: 14, x: 0, y: 8)
        }
        .buttonStyle(.plain)
    }

    private var quickActionBackground: some View {
        ZStack(alignment: .topTrailing) {
            Color.white.opacity(0.84)

            BlobShape()
                .fill(AppColors.primaryBlue.opacity(0.07))
                .frame(width: isPadLike ? 80 : 64, height: isPadLike ? 64 : 52)
                .rotationEffect(.degrees(-9))
                .offset(x: isPadLike ? 22 : 16, y: isPadLike ? -18 : -14)
        }
    }

    // MARK: - Sheets

    private var createTopicSheet: some View {
        CreateGrammarTopicSheet(
            isCreating: viewModel.isCreatingTopic,
            errorMessage: viewModel.createTopicError,
            onCancel: {
                viewModel.createTopicError = nil
                isCreateSheetPresented = false
            },
            onCreate: { title, description, languageCode, languageName, icon, colorHex in
                Task {
                    let didCreate = await viewModel.createTopic(
                        title: title,
                        description: description,
                        languageCode: languageCode,
                        languageName: languageName,
                        icon: icon,
                        colorHex: colorHex
                    )
                    if didCreate { isCreateSheetPresented = false }
                }
            },
            onUseTemplate: { template in
                Task {
                    let created = await viewModel.createTopicFromTemplate(template, settings: settings)
                    if created != nil { isCreateSheetPresented = false }
                }
            }
        )
    }

    private var quickNoteSheet: some View {
        QuickGrammarNoteSheet(
            topics: viewModel.regularTopicOptions,
            isCreating: viewModel.isCreatingQuickNote,
            errorMessage: viewModel.quickNoteError,
            showsTopicPicker: true,
            onCancel: { isQuickNoteSheetPresented = false },
            onSave: { draft in
                Task {
                    let saved = await viewModel.createQuickNote(draft: draft)
                    if let saved {
                        isQuickNoteSheetPresented = false
                        if draft.opensEditorAfterSaving {
                            editorNote = saved
                        }
                    }
                }
            }
        )
    }

    private var quickMistakeSheet: some View {
        QuickGrammarMistakeSheet(
            topics: viewModel.regularTopicOptions,
            isCreating: viewModel.isCreatingQuickMistake,
            errorMessage: viewModel.quickMistakeError,
            showsTopicPicker: settings.groupMistakesByTopic,
            onCancel: { isQuickMistakeSheetPresented = false },
            onSave: { draft in
                Task {
                    let saved = await viewModel.createQuickMistake(draft: draft, settings: settings)
                    if let saved {
                        isQuickMistakeSheetPresented = false
                        if draft.opensEditorAfterSaving {
                            editorNote = saved
                        }
                    }
                }
            }
        )
    }

    // MARK: - Header

    private var backButtonRow: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: isPadLike ? 16 : 15, weight: .black))
                    .foregroundStyle(AppColors.primaryBlueDark)
                    .frame(width: isPadLike ? 40 : 36, height: isPadLike ? 40 : 36)
                    .background(Color.white.opacity(0.88))
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 5)
            }
            .buttonStyle(.plain)
            Spacer(minLength: 0)
        }
    }

    private var toolbarRow: some View {
        HStack(spacing: 10) {
            GrammarSearchBar(
                placeholder: L10n.string("notesSearchTopics"),
                text: $viewModel.searchText,
                theme: theme,
                isPadLike: isPadLike,
                appearance: .elevated
            )
            .frame(maxWidth: .infinity)

            Button {
                isSettingsPresented = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: isPadLike ? 20 : 18, weight: .bold))
                    .foregroundStyle(AppColors.primaryBlue)
                    .frame(width: isPadLike ? 52 : 46, height: isPadLike ? 52 : 46)
                    .background(Color.white.opacity(0.88))
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.045), radius: 10, x: 0, y: 5)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.string("notesSettingsA11y"))
        }
    }

    private var sectionHeader: some View {
        HStack(spacing: 8) {
            Text(L10n.string("notesMyTopics"))
                .font(.system(size: isPadLike ? 20 : 17, weight: .black, design: .rounded))
                .foregroundStyle(AppColors.primaryBlueDark)

            Spacer(minLength: 8)

            if canShowEditButton {
                sectionActionButton(
                    title: isEditingTopics ? L10n.string("commonDone") : L10n.string("commonEdit"),
                    isFilled: isEditingTopics,
                    action: toggleEditingTopics
                )
                .accessibilityLabel(isEditingTopics ? L10n.string("notesDoneEditingA11y") : L10n.string("notesEditTopicsA11y"))
            }

            sectionActionButton(
                title: L10n.string("notesNewTopic"),
                isFilled: false,
                action: { isCreateSheetPresented = true }
            )
        }
    }

    private func sectionActionButton(
        title: String,
        isFilled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: isPadLike ? 13 : 12, weight: .bold, design: .rounded))
                .foregroundStyle(isFilled ? Color.white : AppColors.primaryBlue)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isFilled ? AppColors.primaryBlue : Color.white.opacity(0.88))
                .clipShape(Capsule())
                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }

    private var canShowEditButton: Bool {
        isEditingTopics || viewModel.topics.contains(where: { !$0.isMistakesTopic })
    }

    private func toggleEditingTopics() {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
            isEditingTopics.toggle()
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoading {
            loadingCard
        } else if let loadError = viewModel.loadError {
            errorCard(message: loadError)
        } else if isSearchEmpty {
            searchEmptyState
        } else if isEditingTopics {
            editableTopicsList
        } else if viewModel.filteredTopics.isEmpty && viewModel.searchText.isEmpty {
            topicsEmptyState
        } else {
            topicsList
        }
    }

    private var isSearchEmpty: Bool {
        !viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && viewModel.filteredTopics.isEmpty
            && !viewModel.isLoading
    }

    private var topicsList: some View {
        VStack(spacing: isPadLike ? 12 : 10) {
            ForEach(viewModel.filteredTopics) { topic in
                NavigationLink {
                    GrammarNotesTopicView(topic: topic)
                } label: {
                    GrammarNoteTopicCardView(topic: topic)
                }
                .buttonStyle(.plain)
                .contextMenu {
                    if !topic.isMistakesTopic {
                        Button(role: .destructive) {
                            topicPendingDeletion = topic
                        } label: {
                            Label(L10n.string("notesDeleteTopicLabel"), systemImage: "trash.fill")
                        }
                    }
                }
            }

            if viewModel.hasOnlyMistakesTopic && viewModel.searchText.isEmpty {
                topicsEmptyState
            }
        }
    }

    private var editableTopicsList: some View {
        let editingTopics = viewModel.topics
        let rowSpacing: CGFloat = isPadLike ? 12 : 10
        let approxRowHeight: CGFloat = isPadLike ? 120 : 104

        return List {
            ForEach(editingTopics) { topic in
                topicEditRow(topic)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: rowSpacing / 2, leading: 0, bottom: rowSpacing / 2, trailing: 0))
                    .moveDisabled(topic.isMistakesTopic)
                    .deleteDisabled(topic.isMistakesTopic)
            }
            .onMove { source, destination in
                viewModel.moveTopics(from: source, to: destination)
            }
            .onDelete { indexSet in
                guard let index = indexSet.first else { return }
                let topic = editingTopics[index]
                guard !topic.isMistakesTopic else { return }
                topicPendingDeletion = topic
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollDisabled(true)
        .environment(\.editMode, .constant(.active))
        .frame(height: approxRowHeight * CGFloat(editingTopics.count))
    }

    private var topicDeletionBinding: Binding<Bool> {
        Binding(
            get: { topicPendingDeletion != nil },
            set: { isPresented in
                if !isPresented { topicPendingDeletion = nil }
            }
        )
    }

    private func topicEditRow(_ topic: GrammarNoteTopic) -> some View {
        GrammarNoteTopicCardView(topic: topic, isEditing: true)
            .contentShape(Rectangle())
            .allowsHitTesting(false)
    }

    // MARK: - States

    private var loadingCard: some View {
        HStack(spacing: 12) {
            ProgressView()
                .tint(AppColors.primaryBlue)
            Text(L10n.string("notesLoadingTopics"))
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, isPadLike ? 28 : 24)
        .dashboardCardBackground
    }

    private func errorCard(message: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(CreateSetTheme.red.accent)
                Text(L10n.string("commonSomethingWentWrong"))
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(AppColors.primaryBlueDark)
            }

            Text(message)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
                .lineSpacing(3)

            Button {
                Task { await viewModel.loadTopics() }
            } label: {
                Text(L10n.string("commonRetry"))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(AppColors.primaryBlue)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dashboardCardBackground
    }

    private var topicsEmptyState: some View {
        dashboardEmptyCard(
            icon: "text.book.closed.fill",
            title: L10n.string("notesNoTopics"),
            subtitle: L10n.string("notesNoTopicsSubtitle"),
            buttonTitle: L10n.string("notesNewTopic"),
            action: { isCreateSheetPresented = true }
        )
    }

    private var searchEmptyState: some View {
        dashboardEmptyCard(
            icon: "magnifyingglass",
            title: L10n.string("commonNothingFound"),
            subtitle: L10n.string("notesNothingFoundSubtitle"),
            buttonTitle: nil,
            action: {}
        )
    }

    private func dashboardEmptyCard(
        icon: String,
        title: String,
        subtitle: String,
        buttonTitle: String?,
        action: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppColors.primaryBlue.opacity(0.12))
                    .frame(width: 48, height: 48)
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(AppColors.primaryBlue)
            }

            Text(title)
                .font(.system(size: isPadLike ? 17 : 16, weight: .black, design: .rounded))
                .foregroundStyle(AppColors.primaryBlueDark)

            Text(subtitle)
                .font(.system(size: isPadLike ? 14 : 12, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            if let buttonTitle {
                Button(action: action) {
                    Text(buttonTitle)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(AppColors.primaryBlue)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dashboardCardBackground
    }
}

// MARK: - Card chrome

private struct DashboardCardChrome: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                ZStack(alignment: .topTrailing) {
                    Color.white.opacity(0.84)

                    BlobShape()
                        .fill(AppColors.primaryBlue.opacity(0.09))
                        .frame(
                            width: Layout.isPadLike ? 150 : 110,
                            height: Layout.isPadLike ? 120 : 90
                        )
                        .rotationEffect(.degrees(-9))
                        .offset(
                            x: Layout.isPadLike ? 48 : 36,
                            y: Layout.isPadLike ? -40 : -28
                        )
                }
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: Layout.grammarSettingsCardCornerRadius,
                    style: .continuous
                )
            )
            .overlay(
                RoundedRectangle(
                    cornerRadius: Layout.grammarSettingsCardCornerRadius,
                    style: .continuous
                )
                .stroke(Color.white.opacity(0.62), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.045), radius: 18, x: 0, y: 10)
    }
}

private extension View {
    var dashboardCardBackground: some View {
        modifier(DashboardCardChrome())
    }
}

#Preview {
    NavigationStack {
        GrammarNotesHomeView(ownerUID: "preview-user", showsBackButton: true)
    }
}
