import SwiftUI

struct GrammarNoteEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @StateObject private var viewModel: GrammarNoteEditorViewModel
    @State private var isTemplateSheetPresented = false
    @State private var isCreateQuizSheetPresented = false
    @State private var isQuizListSheetPresented = false
    @State private var isTagsSheetPresented = false
    @State private var pendingTagsText = ""
    @State private var pendingTemplate: GrammarNoteTemplate? = nil
    @State private var activeBlockId: String? = nil
    @State private var isDeleteConfirmPresented = false
    @State private var isNoteTypePickerPresented = false
    @FocusState private var isTitleFocused: Bool

    private let allowsQuiz: Bool
    private let onDeleted: ((GrammarNote) -> Void)?

    init(
        note: GrammarNote,
        ownerUID: String? = nil,
        topicId: String? = nil,
        noteService: GrammarNoteServicing = GrammarNoteService(),
        allowsQuiz: Bool = true,
        onDeleted: ((GrammarNote) -> Void)? = nil
    ) {
        _viewModel = StateObject(
            wrappedValue: GrammarNoteEditorViewModel(
                note: note,
                ownerUID: ownerUID ?? note.ownerUID,
                topicId: topicId ?? note.topicId,
                noteService: noteService
            )
        )
        self.allowsQuiz = allowsQuiz
        self.onDeleted = onDeleted
    }

    private func insertBlock(_ type: GrammarNoteBlockType) {
        let newId = viewModel.addBlock(type, after: activeBlockId)
        activeBlockId = newId
    }

    // MARK: - Adaptive metrics

    private var isRegular: Bool { hSizeClass == .regular }

    private var contentMaxWidth: CGFloat { isRegular ? 900 : .infinity }

    private var horizontalPadding: CGFloat { isRegular ? 28 : 18 }

    private var titleFontSize: CGFloat { isRegular ? 26 : 21 }

    private var topButtonSize: CGFloat { isRegular ? 46 : 42 }
    private var actionButtonSize: CGFloat { isRegular ? 38 : 34 }

    var body: some View {
        ZStack {
            AppColors.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 14, pinnedViews: [.sectionHeaders]) {
                        Section {
                            documentSection
                        } header: {
                            toolbarTray
                        }
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.top, 14)
                    .padding(.bottom, 40)
                    .frame(maxWidth: contentMaxWidth)
                    .frame(maxWidth: .infinity)
                }
            }

            if let toast = viewModel.reviewToast {
                VStack {
                    Spacer()
                    HStack(spacing: 10) {
                        Image(systemName: viewModel.reviewToastIcon)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color.white)
                        Text(toast)
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
                .animation(.spring(response: 0.32, dampingFraction: 0.86), value: viewModel.reviewToast)
                .allowsHitTesting(false)
            }
        }
        .navigationBarBackButtonHidden(true)
        .task {
            await viewModel.loadBlocks()
            viewModel.recordOpened()
        }
        .sheet(isPresented: $isTemplateSheetPresented) {
            templateSheet
        }
        .sheet(isPresented: $isCreateQuizSheetPresented) {
            CreateGrammarQuizSheet(
                note: viewModel.note,
                blocks: viewModel.blocks,
                onCreated: {
                    viewModel.markHasQuiz(true)
                    isCreateQuizSheetPresented = false
                },
                onCancel: { isCreateQuizSheetPresented = false }
            )
        }
        .sheet(isPresented: $isQuizListSheetPresented) {
            GrammarNoteQuizListView(
                note: viewModel.note,
                ownerUID: viewModel.ownerUID,
                allowsCreation: allowsQuiz,
                onAllDeleted: { viewModel.markHasQuiz(false) },
                onDismiss: { isQuizListSheetPresented = false }
            )
        }
        .sheet(isPresented: $isTagsSheetPresented) {
            tagsSheet
        }
        .sheet(isPresented: $isNoteTypePickerPresented) {
            noteTypePickerSheet
        }
        .onChange(of: isTagsSheetPresented) { _, shown in
            if shown { pendingTagsText = viewModel.note.tags.joined(separator: ", ") }
        }
        .confirmationDialog(
            pendingTemplate.map { "Apply \"\($0.title)\"?" } ?? "Apply template?",
            isPresented: Binding(
                get: { pendingTemplate != nil },
                set: { if !$0 { pendingTemplate = nil } }
            ),
            titleVisibility: .visible,
            presenting: pendingTemplate
        ) { template in
            Button("Replace current content", role: .destructive) {
                viewModel.applyTemplate(template, mode: .replace, allowsQuiz: allowsQuiz)
                pendingTemplate = nil
            }
            Button("Append template blocks") {
                viewModel.applyTemplate(template, mode: .append, allowsQuiz: allowsQuiz)
                pendingTemplate = nil
            }
            Button("Cancel", role: .cancel) {
                pendingTemplate = nil
            }
        } message: { _ in
            Text("This note already has content. Choose how to apply the template.")
        }
        .confirmationDialog(
            "Delete this note?",
            isPresented: $isDeleteConfirmPresented,
            titleVisibility: .visible
        ) {
            Button("Delete Note", role: .destructive) {
                Task {
                    let deletedNote = viewModel.note
                    if await viewModel.deleteNote() {
                        onDeleted?(deletedNote)
                        dismiss()
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This note and its content will be permanently deleted.")
        }
        .onDisappear {
            Task { await viewModel.saveIfDirty() }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: isRegular ? 14 : 12) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: isRegular ? 17 : 16, weight: .bold))
                    .foregroundStyle(AppColors.primaryBlueDark)
                    .frame(width: topButtonSize, height: topButtonSize)
                    .background(Color.white.opacity(0.9))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            ZStack {
                Circle()
                    .fill(viewModel.note.noteType.tintColor.opacity(0.14))
                    .frame(width: topButtonSize + 2, height: topButtonSize + 2)
                Image(systemName: viewModel.note.noteType.systemImage)
                    .font(.system(size: isRegular ? 19 : 18, weight: .bold))
                    .foregroundStyle(viewModel.note.noteType.tintColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                TextField(
                    "Untitled note",
                    text: Binding(
                        get: { viewModel.title },
                        set: { viewModel.updateTitle($0) }
                    )
                )
                .font(.system(size: titleFontSize, weight: .black, design: .rounded))
                .foregroundStyle(AppColors.primaryBlueDark)
                .textFieldStyle(.plain)
                .focused($isTitleFocused)

                Text(viewModel.saveState.title)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(statusColor)
            }

            Spacer(minLength: 4)

            HStack(spacing: 6) {
                headerIconButton(
                    systemImage: viewModel.note.isFavorite ? "heart.fill" : "heart",
                    tint: viewModel.note.isFavorite ? GrammarNoteType.mistake.tintColor : AppColors.primaryBlueDark,
                    accessibilityLabel: viewModel.note.isFavorite ? "Remove from Favourites" : "Add to Favourites"
                ) {
                    viewModel.toggleFavorite()
                }

                if allowsQuiz {
                    quizHeaderButton
                }

                headerIconButton(
                    systemImage: "tag",
                    tint: viewModel.note.tags.isEmpty ? AppColors.primaryBlueDark : AppColors.primaryBlue,
                    accessibilityLabel: "Edit Tags"
                ) {
                    isTagsSheetPresented = true
                }

                moreMenu
            }
        }
        .padding(.horizontal, horizontalPadding)
        .frame(maxWidth: contentMaxWidth)
        .frame(maxWidth: .infinity)
        .padding(.top, Layout.grammarNoteTopPadding)
        .padding(.bottom, 10)
    }

    private var quizHeaderButton: some View {
        Group {
            if viewModel.note.hasQuiz {
                Menu {
                    Button {
                        isCreateQuizSheetPresented = true
                    } label: {
                        Label("Create New Quiz", systemImage: "plus.circle")
                    }
                    Button {
                        isQuizListSheetPresented = true
                    } label: {
                        Label("View Quizzes", systemImage: "list.bullet.rectangle")
                    }
                    Button {
                        isQuizListSheetPresented = true
                    } label: {
                        Label("Manage Quizzes", systemImage: "slider.horizontal.3")
                    }
                } label: {
                    quizButtonLabel(
                        systemImage: "play.circle.fill",
                        tint: AppColors.primaryBlue
                    )
                }
                .accessibilityLabel("Quiz options")
            } else {
                Button {
                    isCreateQuizSheetPresented = true
                } label: {
                    quizButtonLabel(
                        systemImage: "questionmark.circle",
                        tint: AppColors.primaryBlueDark
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Create Quiz")
            }
        }
    }

    private func quizButtonLabel(systemImage: String, tint: Color) -> some View {
        Image(systemName: systemImage)
            .font(.system(size: isRegular ? 16 : 15, weight: .bold))
            .foregroundStyle(tint)
            .frame(width: actionButtonSize, height: actionButtonSize)
            .background(Color.white.opacity(0.9))
            .clipShape(Circle())
    }

    private var moreMenu: some View {
        Menu {
            Button {
                isTitleFocused = true
            } label: {
                Label("Rename Note", systemImage: "pencil")
            }
            Button {
                isNoteTypePickerPresented = true
            } label: {
                Label("Change Note Type", systemImage: "arrow.triangle.2.circlepath")
            }
            Button {
                viewModel.togglePinned()
            } label: {
                Label(
                    viewModel.note.isPinned ? "Unpin" : "Pin to Top",
                    systemImage: viewModel.note.isPinned ? "pin.slash" : "pin"
                )
            }

            Divider()

            Button("Use template") { isTemplateSheetPresented = true }
            Button {
                viewModel.saveAsTemplate()
            } label: {
                Label("Save as Template", systemImage: "square.and.arrow.down")
            }
            Button {
                viewModel.addToReview()
            } label: {
                Label("Add to Review", systemImage: "brain.head.profile")
            }
            Button("Save now") { Task { await viewModel.saveNow() } }

            Divider()

            Button(role: .destructive) {
                isDeleteConfirmPresented = true
            } label: {
                Label("Delete Note", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: isRegular ? 16 : 15, weight: .bold))
                .foregroundStyle(AppColors.primaryBlueDark)
                .frame(width: actionButtonSize, height: actionButtonSize)
                .background(Color.white.opacity(0.9))
                .clipShape(Circle())
        }
    }

    private func headerIconButton(
        systemImage: String,
        tint: Color,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: isRegular ? 16 : 15, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: actionButtonSize, height: actionButtonSize)
                .background(Color.white.opacity(0.9))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Toolbar

    private var toolbarTray: some View {
        Group {
            if isRegular {
                HStack(spacing: 0) {
                    Spacer(minLength: 0)
                    toolbarItems
                    Spacer(minLength: 0)
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    toolbarItems
                        .padding(.horizontal, 2)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.94))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.6), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        .disabled(viewModel.isLoadingBlocks)
        .opacity(viewModel.isLoadingBlocks ? 0.5 : 1)
        .padding(.bottom, 8)
        .background(AppColors.appBackground)
    }

    private var toolbarItems: some View {
        HStack(spacing: 9) {
            toolbarButton("H1",      type: .heading)
            toolbarButton("H2",      type: .subheading)
            toolbarButton("Text",    type: .paragraph)
            toolbarButton("Bullets", type: .bulletList)
            toolbarButton("Numbers", type: .numberedList)
            toolbarButton("Check",   type: .checklist)
            toolbarButton("Quote",   type: .quote)
            toolbarButton("Image",   type: .image)
            moreBlocksMenu
        }
    }

    private func toolbarButton(_ title: String, type: GrammarNoteBlockType) -> some View {
        Button {
            insertBlock(type)
        } label: {
            Text(title)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.primaryBlue)
                .padding(.horizontal, 13)
                .frame(height: 36)
                .background(AppColors.primaryBlue.opacity(0.10))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var moreBlocksMenu: some View {
        Menu {
            Button { insertBlock(.rule) } label: {
                Label("Rule", systemImage: GrammarNoteBlockType.rule.systemImage)
            }
            Button { insertBlock(.example) } label: {
                Label("Example", systemImage: GrammarNoteBlockType.example.systemImage)
            }
            Button { insertBlock(.warning) } label: {
                Label("Warning", systemImage: GrammarNoteBlockType.warning.systemImage)
            }
            Button { insertBlock(.comparison) } label: {
                Label("Comparison", systemImage: GrammarNoteBlockType.comparison.systemImage)
            }
            Button { insertBlock(.exercise) } label: {
                Label("Exercise", systemImage: GrammarNoteBlockType.exercise.systemImage)
            }
            Button { insertBlock(.divider) } label: {
                Label("Divider", systemImage: GrammarNoteBlockType.divider.systemImage)
            }
            if allowsQuiz {
                Button { insertBlock(.quiz) } label: {
                    Label("Quiz", systemImage: GrammarNoteBlockType.quiz.systemImage)
                }
            }
        } label: {
            Text("More")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.primaryBlue)
                .padding(.horizontal, 13)
                .frame(height: 36)
                .background(AppColors.primaryBlue.opacity(0.10))
                .clipShape(Capsule())
        }
    }

    // MARK: - Document

    @ViewBuilder
    private var documentSection: some View {
        if viewModel.isLoadingBlocks {
            blocksLoadingState
        } else if viewModel.blocks.isEmpty {
            emptyEditorState
        } else {
            blocksContainer
        }
    }

    private var blocksContainer: some View {
        VStack(spacing: 10) {
            ForEach(Array(viewModel.blocks.enumerated()), id: \.element.id) { index, block in
                GrammarNoteBlockEditorView(
                    block: block,
                    isActive: Binding(
                        get: { activeBlockId == block.id },
                        set: { if $0 { activeBlockId = block.id } }
                    ),
                    onChange: { viewModel.updateBlock($0) },
                    onDelete: { viewModel.deleteBlock(block) },
                    onMoveUp: index > 0
                        ? { viewModel.moveBlockUp(block) } : nil,
                    onMoveDown: index < viewModel.blocks.count - 1
                        ? { viewModel.moveBlockDown(block) } : nil,
                    onDuplicate: { viewModel.duplicateBlock(block) }
                )
                .id(block.id)
            }
        }
        .padding(isRegular ? 16 : 13)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.white.opacity(0.55))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Color.white.opacity(0.6), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 16, x: 0, y: 9)
    }

    // MARK: - States

    private var blocksLoadingState: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(AppColors.primaryBlue)
                .scaleEffect(1.1)
            Text("Loading note…")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    private var emptyEditorState: some View {
        VStack(alignment: .leading, spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppColors.primaryBlue.opacity(0.12))
                    .frame(width: 52, height: 52)
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(AppColors.primaryBlue)
            }

            Text("Start building your note")
                .font(.system(size: isRegular ? 22 : 18, weight: .black, design: .rounded))
                .foregroundStyle(AppColors.primaryBlueDark)

            Text("Tap a block above, or start from one of these.")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)

            HStack(spacing: 8) {
                emptyActionPill("Text",    systemImage: "text.alignleft")    { insertBlock(.paragraph) }
                emptyActionPill("Rule",    systemImage: GrammarNoteBlockType.rule.systemImage) { insertBlock(.rule) }
                emptyActionPill("Example", systemImage: GrammarNoteBlockType.example.systemImage) { insertBlock(.example) }
                emptyActionPill("Quote",   systemImage: "quote.opening")     { insertBlock(.quote) }
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.white.opacity(0.55))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Color.white.opacity(0.6), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 16, x: 0, y: 9)
    }

    private func emptyActionPill(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: systemImage)
                    .font(.system(size: 14, weight: .bold))
                Text(title)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
            }
            .foregroundStyle(AppColors.primaryBlue)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(AppColors.primaryBlue.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Sheets

    private var templateSheet: some View {
        GrammarTemplateLibraryView(
            kind: .note,
            onSelectTopic: nil,
            onSelectNote: { template in
                isTemplateSheetPresented = false
                handleTemplateSelection(template)
            },
            onCancel: { isTemplateSheetPresented = false }
        )
    }

    private var tagsSheet: some View {
        NavigationStack {
            ZStack {
                AppColors.appBackground.ignoresSafeArea()
                VStack(alignment: .leading, spacing: 16) {
                    Text("Separate tags with commas.")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppColors.textSecondary)

                    TextField("A1, verbs, articles", text: $pendingTagsText)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppColors.primaryBlueDark)
                        .tint(AppColors.primaryBlue)
                        .padding(14)
                        .background(Color.white.opacity(0.92))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    if !viewModel.note.tags.isEmpty {
                        tagChips(viewModel.note.tags)
                    }

                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        viewModel.updateTags(parsedTags(from: pendingTagsText))
                        isTagsSheetPresented = false
                    }
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.primaryBlue)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isTagsSheetPresented = false }
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private func tagChips(_ tags: [String]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.primaryBlue)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(AppColors.primaryBlue.opacity(0.10))
                        .clipShape(Capsule())
                }
            }
        }
    }

    private var noteTypePickerSheet: some View {
        ZStack {
            AppColors.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(AppColors.textSecondary.opacity(0.3))
                    .frame(width: 36, height: 4)
                    .padding(.top, 12)
                    .padding(.bottom, 20)

                Text("Note Type")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(AppColors.primaryBlueDark)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 22)
                    .padding(.bottom, 16)

                VStack(spacing: 10) {
                    ForEach(GrammarNoteType.allCases) { type in
                        let isSelected = viewModel.note.noteType == type
                        Button {
                            viewModel.changeNoteType(type)
                            isNoteTypePickerPresented = false
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(type.tintColor.opacity(0.15))
                                        .frame(width: 44, height: 44)
                                    Image(systemName: type.systemImage)
                                        .font(.system(size: 17, weight: .bold))
                                        .foregroundStyle(type.tintColor)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(type.title)
                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                        .foregroundStyle(AppColors.primaryBlueDark)
                                }

                                Spacer()

                                if isSelected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundStyle(type.tintColor)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(isSelected ? type.tintColor.opacity(0.08) : Color.white.opacity(0.85))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(isSelected ? type.tintColor.opacity(0.35) : Color.white.opacity(0.6), lineWidth: 1.5)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 18)

                Spacer()
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(28)
    }

    // MARK: - Helpers

    private func handleTemplateSelection(_ template: GrammarNoteTemplate) {
        if viewModel.blocks.isEmpty {
            viewModel.applyTemplate(template, mode: .replace, allowsQuiz: allowsQuiz)
        } else {
            pendingTemplate = template
        }
    }

    private func parsedTags(from raw: String) -> [String] {
        raw.split(separator: ",")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private var statusColor: Color {
        switch viewModel.saveState {
        case .failed: return CreateSetTheme.red.accent
        case .saving: return AppColors.primaryBlue
        default:      return AppColors.textSecondary
        }
    }
}

#Preview {
    NavigationStack {
        GrammarNoteEditorView(note: .preview(), noteService: MockGrammarNoteService())
    }
}
