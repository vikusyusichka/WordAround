import SwiftUI

struct GrammarNotesTopicView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: GrammarNotesTopicViewModel
    @StateObject private var settings = GrammarNotesSettingsStore()
    @State private var isCreateSheetPresented = false
    @State private var isFABExpanded = false
    @State private var isQuickNoteSheetPresented = false
    @State private var isQuickMistakeSheetPresented = false
    @State private var editorNote: GrammarNote?
    @State private var quizNote: GrammarNote?
    @State private var isEditingNotes = false
    @State private var notePendingDeletion: GrammarNote?

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
            theme.screenBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: isPadLike ? 20 : 16) {
                    headerView
                    if !isEditingNotes {
                        searchBar
                        filtersRow
                    }
                    contentView
                }
                .padding(.horizontal, isPadLike ? 28 : 20)
                .padding(.top, isPadLike ? 22 : 16)
                .padding(.bottom, 96)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            GrammarNotesFABMenu(
                tint: theme.accent,
                items: GrammarNotesFABMenuItem.topicItems,
                onSelect: handleFABSelection,
                isExpanded: $isFABExpanded
            )
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(item: $editorNote) { note in
            GrammarNoteEditorView(
                note: note,
                ownerUID: note.ownerUID,
                topicId: note.topicId,
                allowsQuiz: settings.allowQuickQuizzes
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
            // Note opened from badge has empty contentBlocks (preview-load).
            // Creation is available from the full editor (where blocks are loaded).
            GrammarNoteQuizListView(
                note: note,
                ownerUID: viewModel.topic.ownerUID,
                allowsCreation: false,
                onAllDeleted: {},
                onDismiss: { quizNote = nil }
            )
        }
        .task {
            await viewModel.loadNotesIfNeeded()
        }
        .onAppear {
            // Re-appear from editor: refresh previews from cache so edited
            // titles/previewText are reflected without a server round-trip.
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
                        // Restore the full "New Note" flow: after metadata is
                        // saved, jump straight into the rich editor so the user
                        // can add blocks (rules, examples, images, etc.) without
                        // an extra tap on the new card.
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

    private func handleFABSelection(_ item: GrammarNotesFABMenuItem) {
        switch item.role {
        case .newNote:      isCreateSheetPresented = true
        case .quickNote:    isQuickNoteSheetPresented = true
        case .quickMistake: isQuickMistakeSheetPresented = true
        case .newTopic:     break
        }
    }

    private var headerView: some View {
        VStack(alignment: .leading, spacing: isPadLike ? 16 : 13) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: isPadLike ? 18 : 16, weight: .semibold))
                        .foregroundStyle(theme.mutedTextColor)
                        .frame(width: isPadLike ? 50 : 44, height: isPadLike ? 50 : 44)
                        .background(theme.fieldBackground)
                        .clipShape(Circle())
                        .shadow(color: theme.shadowColor, radius: 12, x: 0, y: 7)
                }
                .buttonStyle(.plain)

                Spacer()

                Button {
                    toggleEditingNotes()
                } label: {
                    Image(systemName: isEditingNotes ? "checkmark" : "pencil")
                        .font(.system(size: isPadLike ? 17 : 15, weight: .bold))
                        .foregroundStyle(isEditingNotes ? Color.white : theme.accent)
                        .frame(width: isPadLike ? 46 : 40, height: isPadLike ? 46 : 40)
                        .background(isEditingNotes ? theme.accent : theme.fieldBackground)
                        .clipShape(Circle())
                        .shadow(color: theme.shadowColor, radius: 12, x: 0, y: 7)
                }
                .buttonStyle(.plain)
                .disabled(!hasEditableNotes)
                .opacity(hasEditableNotes ? 1 : 0.55)
                .accessibilityLabel(isEditingNotes ? "Done editing notes" : "Edit notes")
            }

            HStack(alignment: .center, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(theme.softAccent)
                        .frame(width: isPadLike ? 68 : 58, height: isPadLike ? 68 : 58)

                    Image(systemName: viewModel.topic.icon)
                        .font(.system(size: isPadLike ? 29 : 24, weight: .bold))
                        .foregroundStyle(theme.accent)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(viewModel.topic.title)
                        .font(.system(size: isPadLike ? 31 : 26, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.titleColor)
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)

                    Text(viewModel.topic.description)
                        .font(.system(size: isPadLike ? 15 : 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(theme.mutedTextColor)
                        .lineLimit(2)
                        .lineSpacing(2)
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 8) {
                metaPill(text: "\(viewModel.topic.notesCount) notes", systemImage: "doc.text.fill")
                metaPill(text: viewModel.topic.languageName, systemImage: "globe")
            }
        }
        .padding(isPadLike ? 22 : 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.sectionBackground)
        .clipShape(RoundedRectangle(cornerRadius: isPadLike ? 30 : 26, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: isPadLike ? 30 : 26, style: .continuous)
                .stroke(theme.softBorderColor, lineWidth: 1)
        )
        .shadow(color: theme.shadowColor, radius: 18, x: 0, y: 10)
    }

    private var searchBar: some View {
        GrammarSearchBar(
            placeholder: "Search notes",
            text: $viewModel.searchText,
            theme: theme,
            isPadLike: isPadLike
        )
    }

    private var filtersRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 9) {
                ForEach(GrammarNoteFilter.allCases) { filter in
                    Button {
                        viewModel.selectedFilter = filter
                    } label: {
                        Text(filter.title)
                            .font(.system(size: isPadLike ? 13 : 12, weight: .bold, design: .rounded))
                            .foregroundStyle(viewModel.selectedFilter == filter ? Color.white : theme.accent)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(viewModel.selectedFilter == filter ? theme.accent : theme.fieldBackground)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(theme.softBorderColor, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
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
                    notesSection(title: "PINNED", notes: viewModel.pinnedNotes, isCompact: true)
                }

                if !viewModel.regularNotes.isEmpty {
                    notesSection(title: "All Notes", notes: viewModel.regularNotes, isCompact: false)
                }
            }
        } else {
            notesSection(title: nil, notes: viewModel.filteredNotes, isCompact: false)
        }
    }

    // MARK: - Edit mode

    private var hasEditableNotes: Bool {
        !viewModel.notes.isEmpty
    }

    private func toggleEditingNotes() {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
            isEditingNotes.toggle()
        }
    }

    /// Edit-mode notes list. Switches to a `List` so SwiftUI gives us drag
    /// handles and standard delete affordances. Uses the full `notes`
    /// array (not the filtered/grouped one) so reorder indices stay stable
    /// regardless of the active filter — the filter chips resume normal
    /// behavior the moment the user taps "Done".
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
        .confirmationDialog(
            "Delete this note?",
            isPresented: noteDeletionBinding,
            titleVisibility: .visible,
            presenting: notePendingDeletion
        ) { note in
            Button("Delete \"\(note.title)\"", role: .destructive) {
                Task { await viewModel.deleteNote(note) }
                notePendingDeletion = nil
            }
            Button("Cancel", role: .cancel) { notePendingDeletion = nil }
        } message: { _ in
            Text("This note will be removed from the topic permanently.")
        }
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
                    .font(.system(size: isPadLike ? 16 : 13, weight: .black, design: .rounded))
                    .foregroundStyle(theme.mutedTextColor)
                    .textCase(.uppercase)
                    .tracking(0.8)
            }

            VStack(spacing: isPadLike ? 13 : 11) {
                ForEach(notes) { note in
                    NavigationLink {
                        GrammarNoteEditorView(
                            note: note,
                            ownerUID: viewModel.topic.ownerUID,
                            topicId: viewModel.topic.id,
                            allowsQuiz: settings.allowQuickQuizzes
                        )
                    } label: {
                        GrammarNoteCardView(
                            note: note,
                            isCompact: isCompact,
                            onQuizTap: note.hasQuiz ? { quizNote = note } : nil,
                            searchSnippet: viewModel.searchSnippet(for: note)
                        )
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                        Button {
                            Task { await viewModel.togglePinned(note) }
                        } label: {
                            Label(note.isPinned ? "Unpin" : "Pin", systemImage: note.isPinned ? "pin.slash.fill" : "pin.fill")
                        }
                        .tint(AppColors.primaryBlue)

                        Button {
                            Task { await viewModel.toggleFavorite(note) }
                        } label: {
                            Label(note.isFavorite ? "Unfavorite" : "Favorite", systemImage: note.isFavorite ? "heart.slash.fill" : "heart.fill")
                        }
                        .tint(note.noteType.tintColor)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            Task { await viewModel.deleteNote(note) }
                        } label: {
                            Label("Delete", systemImage: "trash.fill")
                        }
                    }
                }
            }
        }
    }

    private var loadingCard: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(theme.accent)
                .scaleEffect(1.08)

            Text("Loading notes...")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(theme.mutedTextColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, isPadLike ? 36 : 30)
        .background(theme.sectionBackground)
        .grammarSectionCardChrome(theme: theme)
    }

    private func errorCard(message: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(CreateSetTheme.red.accent)

                Text("Something went wrong")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.titleColor)
            }

            Text(message)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(theme.mutedTextColor)

            Button {
                Task { await viewModel.retryLoading() }
            } label: {
                Text("Retry")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(theme.accent)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.sectionBackground)
        .grammarSectionCardChrome(theme: theme)
    }

    private func emptyState(title: String, subtitle: String, showsButton: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                Circle()
                    .fill(theme.softAccent)
                    .frame(width: 54, height: 54)

                Image(systemName: showsButton ? "doc.badge.plus" : "magnifyingglass")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(theme.accent)
            }

            Text(title)
                .font(.system(size: isPadLike ? 18 : 16, weight: .bold, design: .rounded))
                .foregroundStyle(theme.titleColor)

            Text(subtitle)
                .font(.system(size: isPadLike ? 14 : 12, weight: .semibold, design: .rounded))
                .foregroundStyle(theme.mutedTextColor)
                .lineSpacing(2)

            if showsButton {
                Button {
                    isCreateSheetPresented = true
                } label: {
                    Text("New Note")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 11)
                        .background(theme.accent)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.sectionBackground)
        .grammarSectionCardChrome(theme: theme)
    }

    private func metaPill(text: String, systemImage: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: systemImage)
                .font(.system(size: 10, weight: .bold))

            Text(text)
                .lineLimit(1)
        }
        .font(.system(size: isPadLike ? 12 : 10, weight: .bold, design: .rounded))
        .foregroundStyle(theme.mutedTextColor)
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(theme.fieldBackground)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(theme.softBorderColor, lineWidth: 1)
        )
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
