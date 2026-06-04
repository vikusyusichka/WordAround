import SwiftUI

struct GrammarNoteBlockEditorView: View {
    @Environment(\.horizontalSizeClass) private var hSizeClass
    let block: GrammarNoteBlock
    @Binding var isActive: Bool
    let onChange: (GrammarNoteBlock) -> Void
    let onDelete: () -> Void
    var onMoveUp: (() -> Void)?
    var onMoveDown: (() -> Void)?
    var onDuplicate: (() -> Void)?

    @State private var draft: GrammarNoteBlock

    private var isRegular: Bool { hSizeClass == .regular }
    private var headingSize: CGFloat { isRegular ? 26 : 22 }
    private var subheadingSize: CGFloat { isRegular ? 20 : 18 }

    init(
        block: GrammarNoteBlock,
        isActive: Binding<Bool>,
        onChange: @escaping (GrammarNoteBlock) -> Void,
        onDelete: @escaping () -> Void,
        onMoveUp: (() -> Void)? = nil,
        onMoveDown: (() -> Void)? = nil,
        onDuplicate: (() -> Void)? = nil
    ) {
        self.block = block
        self._isActive = isActive
        self.onChange = onChange
        self.onDelete = onDelete
        self.onMoveUp = onMoveUp
        self.onMoveDown = onMoveDown
        self.onDuplicate = onDuplicate
        _draft = State(initialValue: block)
    }

    private let cornerRadius: CGFloat = 16

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            blockHeader
            content
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .background(blockBackground)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(
                    isActive ? AppColors.primaryBlue.opacity(0.30) : Color.white.opacity(0.5),
                    lineWidth: isActive ? 1.5 : 1
                )
        )
        .shadow(
            color: isActive ? AppColors.primaryBlue.opacity(0.07) : Color.clear,
            radius: 8,
            x: 0,
            y: 3
        )
        .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .simultaneousGesture(TapGesture().onEnded {
            withAnimation(.easeInOut(duration: 0.15)) { isActive = true }
        })
        .contextMenu {
            if let onMoveUp {
                Button { onMoveUp() } label: {
                    Label("Move Up", systemImage: "arrow.up")
                }
            }
            if let onMoveDown {
                Button { onMoveDown() } label: {
                    Label("Move Down", systemImage: "arrow.down")
                }
            }
            if let onDuplicate {
                Button { onDuplicate() } label: {
                    Label("Duplicate Block", systemImage: "plus.square.on.square")
                }
            }
            Divider()
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete Block", systemImage: "trash")
            }
        }
        .onChange(of: draft) { _, newDraft in
            if newDraft != block { onChange(newDraft) }
            withAnimation(.easeIn(duration: 0.1)) { isActive = true }
        }
        .onChange(of: block) { _, newBlock in
            if newBlock != draft { draft = newBlock }
        }
        .animation(.easeInOut(duration: 0.15), value: isActive)
    }

    private var blockHeader: some View {
        HStack(spacing: 6) {
            Image(systemName: draft.type.systemImage)
                .font(.system(size: 9.5, weight: .bold))
            Text(draft.type.title.uppercased())
                .font(.system(size: 9.5, weight: .black, design: .rounded))
                .tracking(0.5)
                .foregroundStyle(tint.opacity(isActive ? 0.9 : 0.55))

            Spacer()

            blockActionsMenu
                .opacity(isActive ? 1 : 0)
                .allowsHitTesting(isActive)
        }
        .foregroundStyle(tint.opacity(isActive ? 0.9 : 0.55))
    }

    private var blockActionsMenu: some View {
        Menu {
            if let onMoveUp {
                Button { onMoveUp() } label: { Label("Move Up", systemImage: "arrow.up") }
            }
            if let onMoveDown {
                Button { onMoveDown() } label: { Label("Move Down", systemImage: "arrow.down") }
            }
            if let onDuplicate {
                Button { onDuplicate() } label: { Label("Duplicate Block", systemImage: "plus.square.on.square") }
            }
            Divider()
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete Block", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(AppColors.textSecondary)
                .frame(width: 26, height: 20)
                .contentShape(Rectangle())
        }
    }

    @ViewBuilder
    private var content: some View {
        switch draft.type {
        case .heading:
            TextField(draft.type.placeholder, text: $draft.text, axis: .vertical)
                .font(.system(size: headingSize, weight: .black, design: .rounded))
                .foregroundStyle(AppColors.primaryBlueDark)
                .textFieldStyle(.plain)

        case .subheading:
            TextField(draft.type.placeholder, text: $draft.text, axis: .vertical)
                .font(.system(size: subheadingSize, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.primaryBlueDark)
                .textFieldStyle(.plain)

        case .paragraph:
            editor(text: $draft.text, minHeight: 88, placeholder: draft.type.placeholder)

        case .bulletList, .numberedList, .checklist:
            listEditor

        case .quote:
            editor(text: $draft.text, minHeight: 60, placeholder: draft.type.placeholder)
                .padding(.leading, 12)
                .overlay(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(tint).frame(width: 4)
                }

        case .rule, .example, .warning, .exercise:
            VStack(spacing: 8) {
                editor(text: $draft.text, minHeight: 52, placeholder: draft.type.placeholder)
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
                .tint(tint)
                .lineLimit(1...4)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.72))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

        case .quiz:
            VStack(spacing: 8) {
                editor(text: $draft.text, minHeight: 52, placeholder: draft.type.placeholder)
                TextField(
                    "Answer",
                    text: Binding(
                        get: { draft.secondaryText ?? "" },
                        set: { draft.secondaryText = $0 }
                    ),
                    axis: .vertical
                )
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
                .tint(tint)
                .lineLimit(1...4)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.72))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

        case .comparison:
            HStack(spacing: 10) {
                editor(text: $draft.text, minHeight: 88, placeholder: draft.type.placeholder)
                editor(
                    text: Binding(
                        get: { draft.secondaryText ?? "" },
                        set: { draft.secondaryText = $0 }
                    ),
                    minHeight: 88,
                    placeholder: "Second side"
                )
            }

        case .image:
            imageEditor

        case .divider:
            Rectangle()
                .fill(AppColors.primaryBlue.opacity(0.18))
                .frame(height: 2)
                .clipShape(Capsule())
                .padding(.vertical, 6)
        }
    }

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
                placeholderImage.frame(height: 140)
            }

            HStack(spacing: 8) {
                Label("Image upload coming soon", systemImage: "photo.fill")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(AppColors.textSecondary.opacity(0.10))
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
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(tint)
        }
    }

    private func editor(
        text: Binding<String>,
        minHeight: CGFloat,
        placeholder: String? = nil
    ) -> some View {
        ZStack(alignment: .topLeading) {
            if let placeholder, text.wrappedValue.isEmpty {
                Text(placeholder)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary.opacity(0.55))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 14)
                    .allowsHitTesting(false)
            }
            TextEditor(text: text)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.primaryBlueDark)
                .tint(tint)
                .frame(minHeight: minHeight)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 4)
                .padding(.vertical, 6)
        }
        .background(Color.white.opacity(0.76))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    @ViewBuilder
    private var blockBackground: some View {
        ZStack {
            switch draft.type {
            case .rule, .example, .warning, .comparison, .exercise, .quiz:
                tint.opacity(0.07)
            default:
                Color.white.opacity(0.45)
            }
            if isActive {
                AppColors.primaryBlue.opacity(0.05)
            }
        }
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
                isActive: .constant(false),
                onChange: { _ in }, onDelete: {}
            )
            GrammarNoteBlockEditorView(
                block: GrammarNoteBlock(type: .comparison, text: "Ser", secondaryText: "Estar"),
                isActive: .constant(true),
                onChange: { _ in }, onDelete: {}
            )
            GrammarNoteBlockEditorView(
                block: GrammarNoteBlock(type: .checklist, items: ["Reviewed", "Practiced"]),
                isActive: .constant(false),
                onChange: { _ in }, onDelete: {}
            )
        }
        .padding()
    }
    .background(AppColors.appBackground)
}
