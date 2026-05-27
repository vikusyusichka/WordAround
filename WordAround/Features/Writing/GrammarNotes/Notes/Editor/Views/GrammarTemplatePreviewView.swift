import SwiftUI

/// Detail preview shown after a template is selected from
/// `GrammarTemplateLibraryView`. Displays included blocks (note template)
/// or included notes (topic template), plus a single "Use Template" CTA.
struct GrammarTemplatePreviewView: View {

    enum PreviewKind {
        case note(GrammarNoteTemplate)
        case topic(GrammarTopicTemplate)
    }

    let kind: PreviewKind
    let onUse: () -> Void
    let onCancel: () -> Void

    var body: some View {
        ZStack {
            AppColors.appBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    metaRow
                    if case .topic(let topic) = kind, !topic.noteTemplates.isEmpty {
                        includedNotesSection(topic.noteTemplates)
                    } else if case .note(let note) = kind {
                        includedBlocksSection(note.blocks)
                    }
                }
                .padding(20)
            }

            VStack {
                Spacer()
                useTemplateButton
                    .padding(.horizontal, 20)
                    .padding(.bottom, 18)
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle().fill(tint.opacity(0.16))
                Image(systemName: iconName)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(tint)
            }
            .frame(width: 60, height: 60)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(AppColors.primaryBlueDark)
                Text(description)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            Button(action: onCancel) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(width: 38, height: 38)
                    .background(Color.white.opacity(0.9))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Meta

    private var metaRow: some View {
        HStack(spacing: 8) {
            badge(text: difficulty, systemImage: "graduationcap.fill", tint: tint)
            badge(text: "\(estimatedMinutes) min", systemImage: "clock.fill", tint: AppColors.textSecondary)
            if case .topic(let topic) = kind {
                badge(text: "\(topic.noteTemplates.count) notes", systemImage: "doc.text.fill", tint: AppColors.primaryBlue)
            }
            Spacer(minLength: 0)
        }
    }

    private func badge(text: String, systemImage: String, tint: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
                .font(.system(size: 9, weight: .bold))
            Text(text)
        }
        .font(.system(size: 11, weight: .bold, design: .rounded))
        .foregroundStyle(tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(tint.opacity(0.10))
        .clipShape(Capsule())
    }

    // MARK: - Included blocks (note template)

    private func includedBlocksSection(_ blocks: [GrammarNoteBlock]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Included blocks (\(blocks.count))")
            ForEach(blocks, id: \.id) { block in
                blockRow(block)
            }
        }
    }

    private func blockRow(_ block: GrammarNoteBlock) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: block.type.systemImage)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(AppColors.primaryBlue)
                .frame(width: 28, height: 28)
                .background(AppColors.primaryBlue.opacity(0.10))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(block.type.title)
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)
                Text(blockPreview(block))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.primaryBlueDark)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func blockPreview(_ block: GrammarNoteBlock) -> String {
        if !block.text.isEmpty { return block.text }
        if let s = block.secondaryText, !s.isEmpty { return s }
        if !block.items.isEmpty { return block.items.joined(separator: " • ") }
        return block.type.subtitle
    }

    // MARK: - Included notes (topic template)

    private func includedNotesSection(_ notes: [GrammarNoteTemplate]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Included notes (\(notes.count))")
            ForEach(notes) { note in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: note.noteType.systemImage)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(note.noteType.tintColor)
                        .frame(width: 32, height: 32)
                        .background(note.noteType.tintColor.opacity(0.12))
                        .clipShape(Circle())
                    VStack(alignment: .leading, spacing: 3) {
                        Text(note.title)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(AppColors.primaryBlueDark)
                        Text(note.description)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppColors.textSecondary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.92))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
    }

    // MARK: - CTA

    private var useTemplateButton: some View {
        Button(action: onUse) {
            Text("Use Template")
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(tint)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .black, design: .rounded))
            .foregroundStyle(AppColors.textSecondary)
            .textCase(.uppercase)
            .tracking(0.6)
    }

    private var title: String {
        switch kind {
        case .note(let n):  return n.title
        case .topic(let t): return t.title
        }
    }
    private var description: String {
        switch kind {
        case .note(let n):  return n.description
        case .topic(let t): return t.description
        }
    }
    private var iconName: String {
        switch kind {
        case .note(let n):  return n.noteType.systemImage
        case .topic(let t): return t.icon
        }
    }
    private var tint: Color {
        switch kind {
        case .note(let n):  return n.noteType.tintColor
        case .topic(let t): return CreateSetTheme.theme(forHex: t.colorHex).accent
        }
    }
    private var difficulty: String {
        switch kind {
        case .note(let n):  return n.difficulty
        case .topic(let t): return t.difficulty
        }
    }
    private var estimatedMinutes: Int {
        switch kind {
        case .note(let n):  return n.estimatedMinutes
        case .topic(let t): return t.estimatedMinutes
        }
    }
}

#Preview("Topic preview") {
    GrammarTemplatePreviewView(
        kind: .topic(GrammarTemplateProvider.shared.topicTemplates.first!),
        onUse: {},
        onCancel: {}
    )
}

#Preview("Note preview") {
    GrammarTemplatePreviewView(
        kind: .note(GrammarNoteTemplateProvider.shared.templates.first!),
        onUse: {},
        onCancel: {}
    )
}
