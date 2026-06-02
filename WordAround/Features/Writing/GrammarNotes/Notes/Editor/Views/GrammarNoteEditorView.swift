import SwiftUI

struct GrammarNoteEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: GrammarNoteEditorViewModel
    @State private var isAddBlockSheetPresented = false
    @State private var isTemplateSheetPresented = false
    @State private var isCreateQuizSheetPresented = false
    @State private var isQuizListSheetPresented = false
    @State private var pendingTemplate: GrammarNoteTemplate? = nil

    private let allowsQuiz: Bool

    init(
        note: GrammarNote,
        ownerUID: String? = nil,
        topicId: String? = nil,
        noteService: GrammarNoteServicing = GrammarNoteService(),
        allowsQuiz: Bool = true
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
    }

    var body: some View {
        ZStack {
            AppColors.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                toolbarCard

                ScrollView(showsIndicators: false) {
                    VStack(spacing: Layout.grammarNoteBlockSpacing) {
                        if viewModel.isLoadingBlocks {
                            blocksLoadingState
                        } else if viewModel.blocks.isEmpty {
                            emptyEditorState
                        } else {
                            ForEach(viewModel.blocks) { block in
                                GrammarNoteBlockEditorView(
                                    block: block,
                                    onChange: { viewModel.updateBlock($0) },
                                    onDelete: { viewModel.deleteBlock(block) }
                                )
                                .id(block.id)
                            }
                        }
                    }
                    .padding(.horizontal, Layout.grammarNoteHorizontalPadding)
                    .padding(.top, 16)
                    .padding(.bottom, 34)
                }
            }

            if let toast = viewModel.reviewToast {
                VStack {
                    Spacer()
                    HStack(spacing: 10) {
                        Image(systemName: "brain.head.profile")
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
        .sheet(isPresented: $isAddBlockSheetPresented) {
            AddGrammarNoteBlockSheet(allowsQuiz: allowsQuiz) { type in
                viewModel.addBlock(type)
                isAddBlockSheetPresented = false
            } onCancel: {
                isAddBlockSheetPresented = false
            }
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
        .onDisappear {
            Task { await viewModel.saveIfDirty() }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppColors.primaryBlueDark)
                    .frame(width: 42, height: 42)
                    .background(Color.white.opacity(0.9))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            ZStack {
                Circle()
                    .fill(viewModel.note.noteType.tintColor.opacity(0.14))
                    .frame(width: 44, height: 44)
                Image(systemName: viewModel.note.noteType.systemImage)
                    .font(.system(size: 18, weight: .bold))
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
                .font(.system(size: Layout.value(pad: 24, phone: 20), weight: .black, design: .rounded))
                .foregroundStyle(AppColors.primaryBlueDark)
                .textFieldStyle(.plain)

                Text(viewModel.saveState.title)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(statusColor)
            }

            Spacer()

            Menu {
                Button("Save now")     { Task { await viewModel.saveNow() } }
                Button("Use template") { isTemplateSheetPresented = true }
                Button {
                    viewModel.addToReview()
                } label: {
                    Label("Add to Review", systemImage: "brain.head.profile")
                }
                if allowsQuiz {
                    Divider()
                    if viewModel.note.hasQuiz {
                        Button {
                            isQuizListSheetPresented = true
                        } label: {
                            Label("Practice Quiz", systemImage: "play.circle.fill")
                        }
                    } else {
                        Button {
                            isCreateQuizSheetPresented = true
                        } label: {
                            Label("Create Quiz", systemImage: "plus.circle.fill")
                        }
                    }
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(AppColors.primaryBlueDark)
                    .frame(width: 42, height: 42)
                    .background(Color.white.opacity(0.9))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, Layout.grammarNoteHorizontalPadding)
        .padding(.top, Layout.grammarNoteTopPadding)
        .padding(.bottom, 10)
    }

    private var toolbarCard: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 9) {
                toolbarButton("H1",      type: .heading)
                toolbarButton("H2",      type: .subheading)
                toolbarButton("Text",    type: .paragraph)
                toolbarButton("Bullets", type: .bulletList)
                toolbarButton("Numbers", type: .numberedList)
                toolbarButton("Check",   type: .checklist)
                toolbarButton("Quote",   type: .quote)
                toolbarButton("Image",   type: .image)

                Button {
                    isAddBlockSheetPresented = true
                } label: {
                    Label("Add", systemImage: "plus")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 13)
                        .frame(height: 38)
                        .background(AppColors.primaryBlue)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Layout.grammarNoteHorizontalPadding)
        }
        .padding(.vertical, 9)
        .background(Color.white.opacity(0.62))
        .disabled(viewModel.isLoadingBlocks)
        .opacity(viewModel.isLoadingBlocks ? 0.5 : 1)
    }

    private func toolbarButton(_ title: String, type: GrammarNoteBlockType) -> some View {
        Button { viewModel.addBlock(type) } label: {
            Text(title)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.primaryBlue)
                .padding(.horizontal, 13)
                .frame(height: 38)
                .background(AppColors.primaryBlue.opacity(0.10))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

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
                    .frame(width: 58, height: 58)
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 25, weight: .bold))
                    .foregroundStyle(AppColors.primaryBlue)
            }

            Text("Start writing your note")
                .font(.system(size: Layout.value(pad: 21, phone: 18), weight: .black, design: .rounded))
                .foregroundStyle(AppColors.primaryBlueDark)

            Text("Add formatted text, examples, rules, images or a ready-made template.")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)

            HStack(spacing: 10) {
                actionPill("Add text",     systemImage: "text.alignleft") { viewModel.addBlock(.paragraph) }
                actionPill("Use template", systemImage: "sparkles")       { isTemplateSheetPresented = true }
                actionPill("Add image",    systemImage: "photo.fill")     { viewModel.addBlock(.image) }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 16, x: 0, y: 8)
    }

    private func actionPill(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.primaryBlue)
                .padding(.horizontal, 11)
                .padding(.vertical, 9)
                .background(AppColors.primaryBlue.opacity(0.10))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

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

    private func handleTemplateSelection(_ template: GrammarNoteTemplate) {
        if viewModel.blocks.isEmpty {
            viewModel.applyTemplate(template, mode: .replace, allowsQuiz: allowsQuiz)
        } else {
            pendingTemplate = template
        }
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
