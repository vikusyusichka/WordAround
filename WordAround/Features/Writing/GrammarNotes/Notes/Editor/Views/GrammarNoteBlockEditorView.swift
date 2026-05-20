import SwiftUI
import PhotosUI

struct GrammarNoteBlockEditorView: View {
    let block: GrammarNoteBlock
    let onChange: (GrammarNoteBlock) -> Void
    let onDelete: () -> Void

    @State private var draft: GrammarNoteBlock
    @State private var selectedPhoto: PhotosPickerItem?

    init(
        block: GrammarNoteBlock,
        onChange: @escaping (GrammarNoteBlock) -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.block = block
        self.onChange = onChange
        self.onDelete = onDelete
        _draft = State(initialValue: block)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            content
        }
        .padding(Layout.grammarNoteBlockPadding)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: Layout.grammarNoteBlockCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Layout.grammarNoteBlockCornerRadius, style: .continuous)
                .stroke(Color.white.opacity(0.72), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.045), radius: 12, x: 0, y: 7)
        .onChange(of: draft) { _, newDraft in
            if newDraft != block { onChange(newDraft) }
        }
        .onChange(of: block) { _, newBlock in
            if newBlock != draft { draft = newBlock }
        }
    }

    // MARK: - Header
    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: draft.type.systemImage)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(tint)

            Text(draft.type.title)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(tint)

            Spacer()

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(CreateSetTheme.red.accent)
                    .frame(width: 30, height: 30)
                    .background(CreateSetTheme.red.softAccent)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Content
    @ViewBuilder
    private var content: some View {
        switch draft.type {
        case .heading:
            TextField(draft.type.placeholder, text: $draft.text, axis: .vertical)
                .font(.system(size: Layout.grammarNoteHeadingSize, weight: .black, design: .rounded))
                .foregroundStyle(AppColors.primaryBlueDark)
                .textFieldStyle(.plain)

        case .subheading:
            TextField(draft.type.placeholder, text: $draft.text, axis: .vertical)
                .font(.system(size: Layout.grammarNoteSubheadingSize, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.primaryBlueDark)
                .textFieldStyle(.plain)

        case .paragraph:
            editor(text: $draft.text, minHeight: 120)

        case .bulletList, .numberedList, .checklist:
            listEditor

        case .quote:
            editor(text: $draft.text, minHeight: 86)
                .padding(.leading, 12)
                .overlay(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(tint).frame(width: 4)
                }

        case .rule, .example, .warning, .exercise, .quiz:
            VStack(spacing: 10) {
                editor(text: $draft.text, minHeight: 82)
                TextField(
                    "Extra explanation",
                    text: Binding(
                        get: { draft.secondaryText ?? "" },
                        set: { draft.secondaryText = $0 }
                    ),
                    axis: .vertical
                )
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
                .padding(12)
                .background(Color.white.opacity(0.72))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

        case .comparison:
            HStack(spacing: 10) {
                editor(text: $draft.text, minHeight: 120)
                editor(
                    text: Binding(
                        get: { draft.secondaryText ?? "" },
                        set: { draft.secondaryText = $0 }
                    ),
                    minHeight: 120
                )
            }

        case .image:
            imageEditor

        case .divider:
            Rectangle()
                .fill(AppColors.primaryBlue.opacity(0.18))
                .frame(height: 2)
                .clipShape(Capsule())
                .padding(.vertical, 8)
        }
    }

    // MARK: - List editor
    private var listEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(draft.items.indices), id: \.self) { index in
                HStack(alignment: .top, spacing: 8) {
                    listBullet(for: index)
                    TextField(
                        draft.type.placeholder,
                        text: Binding(
                            get: { draft.items[index] },
                            set: { draft.items[index] = $0 }
                        ),
                        axis: .vertical
                    )
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.primaryBlueDark)
                    .padding(11)
                    .background(Color.white.opacity(0.78))
                    .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                }
            }

            Button { draft.items.append("") } label: {
                Label("Add item", systemImage: "plus")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(tint)
            }
            .buttonStyle(.plain)
            .padding(.top, 3)
        }
    }

    @ViewBuilder
    private func listBullet(for index: Int) -> some View {
        switch draft.type {
        case .numberedList:
            Text("\(index + 1).")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(tint)
                .padding(.top, 12)
        case .checklist:
            Image(systemName: "square")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(tint)
                .padding(.top, 12)
        default:
            Text("•")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(tint)
                .padding(.top, 9)
        }
    }

    // MARK: - Image editor
    private var imageEditor: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let imageURL = draft.imageURL, !imageURL.isEmpty {
                AsyncImage(url: URL(string: imageURL)) { phase in
                    switch phase {
                    case .success(let image): image.resizable().scaledToFill()
                    default: placeholderImage
                    }
                }
                .frame(height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            } else {
                placeholderImage.frame(height: 150)
            }

            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                Label("Add / replace image", systemImage: "photo.fill")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(tint)
                    .clipShape(Capsule())
            }

            TextField(
                "Caption",
                text: Binding(
                    get: { draft.imageCaption ?? "" },
                    set: { draft.imageCaption = $0 }
                )
            )
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .padding(12)
            .background(Color.white.opacity(0.78))
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        }
    }

    private var placeholderImage: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(tint.opacity(0.12))
            Image(systemName: "photo")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(tint)
        }
    }

    // MARK: - Shared text editor
    private func editor(text: Binding<String>, minHeight: CGFloat) -> some View {
        TextEditor(text: text)
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .foregroundStyle(AppColors.primaryBlueDark)
            .tint(tint)
            .frame(minHeight: minHeight)
            .scrollContentBackground(.hidden)
            .padding(8)
            .background(Color.white.opacity(0.76))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Styling
    private var background: some View {
        let overlay = tint.opacity(draft.type == .paragraph ? 0.03 : 0.08)
        return Color.white.opacity(0.92).overlay(overlay)
    }

    private var tint: Color {
        switch draft.type {
        case .warning:            return CreateSetTheme.red.accent
        case .example, .exercise: return CreateSetTheme.green.accent
        case .comparison:         return CreateSetTheme.cyan.accent
        case .quote:              return CreateSetTheme.purple.accent
        default:                  return AppColors.primaryBlue
        }
    }
}

#Preview {
    ScrollView {
        VStack {
            GrammarNoteBlockEditorView(
                block: GrammarNoteBlock(type: .heading, text: "Ser vs Estar"),
                onChange: { _ in }, onDelete: {}
            )
            GrammarNoteBlockEditorView(
                block: GrammarNoteBlock(type: .comparison, text: "Ser", secondaryText: "Estar"),
                onChange: { _ in }, onDelete: {}
            )
            GrammarNoteBlockEditorView(
                block: GrammarNoteBlock(type: .checklist, items: ["Reviewed", "Practiced"]),
                onChange: { _ in }, onDelete: {}
            )
        }
        .padding()
    }
    .background(AppColors.appBackground)
}
