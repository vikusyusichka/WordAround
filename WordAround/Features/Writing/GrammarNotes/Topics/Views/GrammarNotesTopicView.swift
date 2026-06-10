import SwiftUI

struct GrammarNotesTopicView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: GrammarNotesTopicViewModel
    @StateObject private var settings = GrammarNotesSettingsStore()
    @State private var isCreateSheetPresented = false
    @State private var isQuickNoteSheetPresented = false
    @State private var isQuickMistakeSheetPresented = false
    @State private var editorNote: GrammarNote?
    @State private var quizNote: GrammarNote?
    @State private var isEditingNotes = false
    @State private var notePendingDeletion: GrammarNote?
    @State private var templateSavedToast = false

    private let theme: CreateSetTheme

    private var isPadLike: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    @MainActor
    init(
        topic: GrammarNoteTopic,
        ownerUID: String? = nil,
        noteService: GrammarNoteServicing? = nil,
        previewNotes: [GrammarNote] = []
    ) {
        let resolvedOwnerUID = ownerUID ?? topic.ownerUID
        _viewModel = StateObject(
            wrappedValue: GrammarNotesTopicViewModel(
                topic: topic,
                ownerUID: resolvedOwnerUID,
                noteService: noteService,
                previewNotes: previewNotes
            )
        )
        self.theme = CreateSetTheme.theme(forHex: topic.colorHex)
    }

    var body: some View {
        ZStack {
            AppColors.appBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: isPadLike ? 20 : 16) {
                    headerView
                    if !isEditingNotes {
                        searchBar
                        filtersRow
                    }
                    contentView
                }
                .frame(maxWidth: Layout.grammarNotesHomeContentMaxWidth, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, isPadLike ? 24 : 16)
                .padding(.top, isPadLike ? 16 : 12)
                .padding(.bottom, Layout.grammarNotesHomeScrollBottomPadding)
            }

            if templateSavedToast {
                VStack {
                    Spacer()
                    HStack(spacing: 10) {
                        Image(systemName: "doc.badge.plus")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color.white)
                        Text(L10n.string("topicToastSaved"))
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 11)
                    .background(AppColors.primaryBlueDark.opacity(0.95))
                    .clipShape(Capsule())
                    .shadow(color: Color.black.opacity(0.18), radius: 14, x: 0, y: 6)
                    .padding(.bottom, 28)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .allowsHitTesting(false)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(item: $editorNote) { note in
            GrammarNoteEditorView(
                note: note,
                ownerUID: note.ownerUID,
                topicId: note.topicId,
                allowsQuiz: settings.allowQuickQuizzes,
                onDeleted: { deleted in
                    viewModel.removeNoteLocally(deleted)
                }
            )
        }
        .sheet(isPresented: $isCreateSheetPresented) {
            createNoteSheet
        }
        .sheet(isPresented: $isQuickNoteSheetPresented) {
            quickNoteSheet
        }
        .sheet(isPresented: $isQuickMistakeSheetPresented) {
            quickMistakeSheet
        }
        .sheet(item: $quizNote) { note in
            GrammarNoteQuizListView(
                note: note,
                ownerUID: viewModel.topic.ownerUID,
                allowsCreation: false,
                onAllDeleted: {},
                onDismiss: { quizNote = nil }
            )
        }
        .confirmationDialog(
            L10n.string("editorDeleteNoteTitle"),
            isPresented: noteDeletionBinding,
            titleVisibility: .visible,
            presenting: notePendingDeletion
        ) { note in
            Button(String(format: L10n.string("templateLibDeleteFmt"), note.title), role: .destructive) {
                Task { await viewModel.deleteNote(note) }
                notePendingDeletion = nil
            }
            Button(L10n.localized(.commonCancel), role: .cancel) { notePendingDeletion = nil }
        } message: { _ in
            Text(L10n.string("topicDeleteNoteMsg"))
        }
        .task {
            await viewModel.loadNotesIfNeeded()
        }
        .onAppear {
            Task { await viewModel.refreshFromCacheIfNeeded() }
        }
    }

    private var createNoteSheet: some View {
        CreateGrammarNoteSheet(
            topic: viewModel.topic,
            isCreating: viewModel.isCreatingNote,
            errorMessage: viewModel.errorMessage,
            onCancel: { isCreateSheetPresented = false },
            onCreate: { title, previewText, noteType, tags, hasQuiz, template in
                Task {
                    let saved = await viewModel.createNote(
                        title: title,
                        previewText: previewText,
                        noteType: noteType,
                        tags: tags,
                        hasQuiz: hasQuiz,
                        template: template
                    )
                    if let saved {
                        isCreateSheetPresented = false
                        editorNote = saved
                    }
                }
            }
        )
    }

    private var quickNoteSheet: some View {
        QuickGrammarNoteSheet(
            topics: [viewModel.topicOption],
            isCreating: viewModel.isCreatingQuickNote,
            errorMessage: viewModel.quickNoteError,
            showsTopicPicker: false,
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
            topics: [viewModel.topicOption],
            isCreating: viewModel.isCreatingQuickMistake,
            errorMessage: viewModel.quickMistakeError,
            showsTopicPicker: false,
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

    private var headerView: some View {
        VStack(alignment: .leading, spacing: isPadLike ? 14 : 12) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: isPadLike ? 16 : 15, weight: .semibold))
                        .foregroundStyle(AppColors.primaryBlue)
                        .frame(width: isPadLike ? 40 : 36, height: isPadLike ? 40 : 36)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(.plain)

                Spacer()

                if hasEditableNotes || isEditingNotes {
                    Button {
                        toggleEditingNotes()
                    } label: {
                        Text(isEditingNotes ? L10n.localized(.commonDone) : L10n.string("commonEdit"))
                            .font(.system(size: isPadLike ? 13 : 12, weight: .bold, design: .rounded))
                            .foregroundStyle(isEditingNotes ? Color.white : AppColors.primaryBlue)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(isEditingNotes ? AppColors.primaryBlue : Color.white)
                            .clipShape(Capsule())
                            .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(L10n.string(isEditingNotes ? "topicDoneEditNotesA11y" : "topicEditNotesA11y"))
                }

                if !isEditingNotes {
                    quickActionIconButton(
                        systemImage: "square.and.pencil",
                        accessibilityLabel: L10n.string("notesQuickNote")
                    ) {
                        isQuickNoteSheetPresented = true
                    }

                    quickActionIconButton(
                        systemImage: "exclamationmark.bubble.fill",
                        accessibilityLabel: L10n.string("notesQuickMistake")
                    ) {
                        isQuickMistakeSheetPresented = true
                    }

                    Button {
                        isCreateSheetPresented = true
                    } label: {
                        Text(L10n.string("createNoteTitle"))
                            .font(.system(size: isPadLike ? 13 : 12, weight: .bold, design: .rounded))
                            .foregroundStyle(AppColors.primaryBlue)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.white)
                            .clipShape(Capsule())
                            .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
                    }
                    .buttonStyle(.plain)

                    topicOverflowMenu
                }
            }

            HStack(alignment: .center, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(theme.softAccent)
                        .frame(width: isPadLike ? 60 : 52, height: isPadLike ? 60 : 52)

                    Image(systemName: viewModel.topic.icon)
                        .font(.system(size: isPadLike ? 26 : 22, weight: .bold))
                        .foregroundStyle(theme.accent)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.topic.title)
                        .font(.system(size: isPadLike ? 26 : 22, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.primaryBlueDark)
                        .lineLimit(2)
                        .minimumScaleFactor(0.84)

                    if !viewModel.topic.description.isEmpty {
                        Text(viewModel.topic.description)
                            .font(.system(size: isPadLike ? 14 : 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppColors.textSecondary)
                            .lineLimit(2)
                            .lineSpacing(1)
                    }
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 8) {
                metaPill(text: String(format: L10n.string("topicNotesCountFmt"), viewModel.topic.notesCount), systemImage: "doc.text.fill")
                if !viewModel.topic.languageName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    metaPill(text: viewModel.topic.languageName, systemImage: "globe")
                }
            }
        }
        .padding(isPadLike ? 18 : 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }

    private var topicOverflowMenu: some View {
        Menu {
            Button {
                saveTopicAsTemplate()
            } label: {
                Label(L10n.string("topicSaveAsTemplate"), systemImage: "square.and.arrow.down")
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: isPadLike ? 14 : 13, weight: .bold))
                .foregroundStyle(AppColors.primaryBlue)
                .frame(width: isPadLike ? 36 : 32, height: isPadLike ? 36 : 32)
                .background(Color.white)
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
        }
        .accessibilityLabel(L10n.string("topicMoreA11y"))
    }

    private func saveTopicAsTemplate() {
        viewModel.saveTopicAsTemplate()
        withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
            templateSavedToast = true
        }
        Task {
            try? await Task.sleep(nanoseconds: 2_200_000_000)
            withAnimation(.easeInOut(duration: 0.2)) {
                templateSavedToast = false
            }
        }
    }

    private func quickActionIconButton(
        systemImage: String,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: isPadLike ? 14 : 13, weight: .bold))
                .foregroundStyle(AppColors.primaryBlue)
                .frame(width: isPadLike ? 36 : 32, height: isPadLike ? 36 : 32)
                .background(Color.white)
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }

    private var searchBar: some View {
        GrammarSearchBar(
            placeholder: L10n.string("topicSearchPh"),
            text: $viewModel.searchText,
            theme: theme,
            isPadLike: isPadLike,
            appearance: .elevated
        )
    }

    private var filtersRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            primaryFilterRow

            if viewModel.selectedFilter == .types {
                typesSubFilterRow
            } else if viewModel.selectedFilter == .tags {
                tagsSubFilterRow
            }
        }
    }

    private var primaryFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(GrammarNoteFilter.allCases) { filter in
                    primaryFilterPill(filter)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func primaryFilterPill(_ filter: GrammarNoteFilter) -> some View {
        let isSelected = viewModel.selectedFilter == filter
        let showsCaret = (filter == .types || filter == .tags)
        return Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                viewModel.selectedFilter = filter
            }
        } label: {
            HStack(spacing: 6) {
                Text(filter.title)
                    .font(.system(size: isPadLike ? 13 : 12, weight: .bold, design: .rounded))
                if showsCaret {
                    Image(systemName: isSelected ? "chevron.up" : "chevron.down")
                        .font(.system(size: 9, weight: .bold))
                }
            }
            .foregroundStyle(isSelected ? Color.white : AppColors.primaryBlue)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(isSelected ? AppColors.primaryBlue : Color.white)
            .clipShape(Capsule())
            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }

    private var typesSubFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(GrammarNoteType.allCases) { type in
                    let isSelected = viewModel.selectedNoteType == type
                    Button {
                        viewModel.selectedNoteType = isSelected ? nil : type
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: type.systemImage)
                                .font(.system(size: 10, weight: .bold))
                            Text(type.title)
                                .font(.system(size: isPadLike ? 12 : 11, weight: .bold, design: .rounded))
                                .lineLimit(1)
                        }
                        .foregroundStyle(isSelected ? Color.white : type.tintColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(isSelected ? type.tintColor : type.tintColor.opacity(0.12))
                        .clipShape(Capsule())
                        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var tagsSubFilterRow: some View {
        HStack(spacing: 8) {
            Menu {
                Button(L10n.string("topicTagAll")) {
                    viewModel.selectedTag = nil
                }
                if !viewModel.availableTags.isEmpty {
                    Divider()
                    ForEach(viewModel.availableTags, id: \.self) { tag in
                        Button {
                            viewModel.selectedTag = tag
                        } label: {
                            if viewModel.selectedTag == tag {
                                Label(tag, systemImage: "checkmark")
                            } else {
                                Text(tag)
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "tag.fill")
                        .font(.system(size: 10, weight: .bold))
                    Text(viewModel.selectedTag.map { "#\($0)" } ?? L10n.string("topicTagAll"))
                        .font(.system(size: isPadLike ? 12 : 11, weight: .bold, design: .rounded))
                        .lineLimit(1)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .bold))
                }
                .foregroundStyle(viewModel.availableTags.isEmpty ? AppColors.textSecondary : AppColors.primaryBlue)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(Color.white)
                .clipShape(Capsule())
                .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
            }
            .disabled(viewModel.availableTags.isEmpty)

            if viewModel.availableTags.isEmpty {
                Text(L10n.string("topicNoTags"))
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)
            }

            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoading {
            loadingCard
        } else if let errorMessage = viewModel.errorMessage {
            errorCard(message: errorMessage)
        } else if isEditingNotes {
            editableNotesList
        } else if viewModel.hasNoNotes || viewModel.hasNoMatchingNotes {
            emptyState(
                title: viewModel.emptyStateTitle,
                subtitle: viewModel.emptyStateSubtitle,
                showsButton: viewModel.showsEmptyStateAction
            )
        } else if viewModel.selectedFilter == .all {
            VStack(alignment: .leading, spacing: isPadLike ? 18 : 14) {
                if !viewModel.pinnedNotes.isEmpty {
                    notesSection(title: L10n.string("topicSectionPinned"), notes: viewModel.pinnedNotes, isCompact: true)
                }

                if !viewModel.regularNotes.isEmpty {
                    notesSection(title: L10n.string("topicSectionAll"), notes: viewModel.regularNotes, isCompact: false)
                }
            }
        } else {
            notesSection(title: nil, notes: viewModel.filteredNotes, isCompact: false)
        }
    }

    private var hasEditableNotes: Bool {
        !viewModel.notes.isEmpty
    }

    private func toggleEditingNotes() {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
            isEditingNotes.toggle()
        }
    }

    private var editableNotesList: some View {
        let editingNotes = viewModel.notes
        let rowSpacing: CGFloat = isPadLike ? 13 : 11
        let approxRowHeight: CGFloat = isPadLike ? 138 : 122

        return List {
            ForEach(editingNotes) { note in
                noteEditRow(note)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: rowSpacing / 2, leading: 0, bottom: rowSpacing / 2, trailing: 0))
            }
            .onMove { source, destination in
                viewModel.moveNotes(from: source, to: destination)
            }
            .onDelete { indexSet in
                guard let index = indexSet.first else { return }
                notePendingDeletion = editingNotes[index]
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollDisabled(true)
        .environment(\.editMode, .constant(.active))
        .frame(height: approxRowHeight * CGFloat(editingNotes.count))
    }

    private var noteDeletionBinding: Binding<Bool> {
        Binding(
            get: { notePendingDeletion != nil },
            set: { isPresented in
                if !isPresented { notePendingDeletion = nil }
            }
        )
    }

    private func noteEditRow(_ note: GrammarNote) -> some View {
        GrammarNoteCardView(
            note: note,
            isCompact: false,
            onQuizTap: nil,
            searchSnippet: nil
        )
        .contentShape(Rectangle())
        .allowsHitTesting(false)
    }

    private func notesSection(title: String?, notes: [GrammarNote], isCompact: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if let title {
                Text(title)
                    .font(.system(size: isPadLike ? 13 : 11, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)
                    .textCase(.uppercase)
                    .tracking(1.0)
            }

            VStack(spacing: isPadLike ? 13 : 11) {
                ForEach(notes) { note in
                    Button {
                        editorNote = note
                    } label: {
                        GrammarNoteCardView(
                            note: note,
                            isCompact: isCompact,
                            onQuizTap: note.hasQuiz ? { quizNote = note } : nil,
                            searchSnippet: viewModel.searchSnippet(for: note)
                        )
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button {
                            editorNote = note
                        } label: {
                            Label(L10n.string("commonEdit"), systemImage: "pencil")
                        }

                        Button {
                            Task { await viewModel.toggleFavorite(note) }
                        } label: {
                            Label(L10n.string(note.isFavorite ? "editorRemoveFromFavorites" : "editorAddToFavorites"),
                                  systemImage: note.isFavorite ? "heart.slash.fill" : "heart.fill")
                        }

                        Button {
                            Task { await viewModel.togglePinned(note) }
                        } label: {
                            Label(L10n.string(note.isPinned ? "editorUnpin" : "topicCtxPin"),
                                  systemImage: note.isPinned ? "pin.slash.fill" : "pin.fill")
                        }

                        Button(role: .destructive) {
                            notePendingDeletion = note
                        } label: {
                            Label(L10n.localized(.commonDelete), systemImage: "trash.fill")
                        }
                    }
                }
            }
        }
    }

    private var loadingCard: some View {
        HStack(spacing: 12) {
            ProgressView()
                .tint(AppColors.primaryBlue)
            Text(L10n.string("topicLoading"))
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, isPadLike ? 28 : 24)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }

    private func errorCard(message: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(CreateSetTheme.red.accent)
                Text(L10n.string("commonSomethingWentWrong"))
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.primaryBlueDark)
            }
            Text(message)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
            Button {
                Task { await viewModel.retryLoading() }
            } label: {
                Text(L10n.localized(.commonRetry))
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
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }

    private func emptyState(title: String, subtitle: String, showsButton: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppColors.primaryBlue.opacity(0.12))
                    .frame(width: 48, height: 48)
                Image(systemName: showsButton ? "doc.badge.plus" : "magnifyingglass")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(AppColors.primaryBlue)
            }
            Text(title)
                .font(.system(size: isPadLike ? 17 : 16, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.primaryBlueDark)
            Text(subtitle)
                .font(.system(size: isPadLike ? 14 : 12, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
            if showsButton {
                Button {
                    isCreateSheetPresented = true
                } label: {
                    Text(L10n.string("createNoteTitle"))
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
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }

    private func metaPill(text: String, systemImage: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
                .font(.system(size: 9, weight: .bold))
            Text(text)
                .lineLimit(1)
        }
        .font(.system(size: isPadLike ? 11 : 10, weight: .bold, design: .rounded))
        .foregroundStyle(AppColors.textSecondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(AppColors.primaryBlue.opacity(0.08))
        .clipShape(Capsule())
    }
}

#Preview {
    NavigationStack {
        GrammarNotesTopicView(
            topic: GrammarNoteTopic(
                id: "preview-topic",
                ownerUID: "preview-user",
                title: "Spanish Tenses",
                description: "Rules, examples and useful patterns for past and present tenses.",
                languageCode: "es",
                languageName: "Spanish",
                icon: "text.book.closed.fill",
                colorHex: "#4F7CFF",
                notesCount: 3,
                isPinned: true,
                isMistakesTopic: false,
                createdAt: Date(),
                updatedAt: Date()
            ),
            ownerUID: "preview-user",
            noteService: MockGrammarNoteService(notes: [
                .preview(title: "Ser vs Estar", noteType: .rule, isPinned: true, isFavorite: true, hasQuiz: true),
                .preview(title: "Por vs Para", noteType: .comparison, isPinned: false, isFavorite: true),
                .preview(title: "Article mistake", noteType: .mistake)
            ]),
            previewNotes: [
                .preview(title: "Ser vs Estar", noteType: .rule, isPinned: true, isFavorite: true, hasQuiz: true),
                .preview(title: "Por vs Para", noteType: .comparison, isPinned: false, isFavorite: true),
                .preview(title: "Article mistake", noteType: .mistake)
            ]
        )
    }
}
