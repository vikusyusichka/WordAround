import SwiftUI

struct GrammarNoteEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: GrammarNoteEditorViewModel
    @State private var isAddBlockSheetPresented = false
    @State private var isTemplateSheetPresented = false

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
        }
        .navigationBarBackButtonHidden(true)
        .task { await viewModel.loadBlocks() }
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
        .onDisappear {
            Task { await viewModel.saveIfDirty() }
        }
    }

    // MARK: - Header
    private var header: some View {
        HStack(spacing: 12) {
            Button {
                // Dismiss immediately; onDisappear handles the final save
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

    // MARK: - Toolbar
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

    // MARK: - Blocks loading state
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

    // MARK: - Empty state
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

    // MARK: - Template sheet
    private var templateSheet: some View {
        NavigationStack {
            ZStack {
                AppColors.appBackground.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        ForEach(GrammarNoteTemplateProvider.shared.templates) { template in
                            Button {
                                viewModel.applyTemplate(template)
                                isTemplateSheetPresented = false
                            } label: {
                                templateRow(template)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Templates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { isTemplateSheetPresented = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func templateRow(_ template: GrammarNoteTemplate) -> some View {
        HStack(spacing: 12) {
            Image(systemName: template.noteType.systemImage)
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(template.noteType.tintColor)
                .frame(width: 46, height: 46)
                .background(template.noteType.tintColor.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 5) {
                Text(template.title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.primaryBlueDark)
                Text(template.description)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)
                    .lineLimit(2)
            }
            Spacer()
        }
        .padding(15)
        .background(Color.white.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    // MARK: - Helpers
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
