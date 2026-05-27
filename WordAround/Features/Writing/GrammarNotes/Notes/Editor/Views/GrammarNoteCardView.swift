import SwiftUI

struct GrammarNoteCardView: View {
    let note: GrammarNote
    var isCompact: Bool = false
    var onQuizTap: (() -> Void)? = nil
    /// Optional contextual snippet shown when the parent screen has an
    /// active search query and this note matched on inner content (not just
    /// the title/preview). Trimmed to ~120 chars by the indexer.
    var searchSnippet: String? = nil

    var body: some View {
        HStack(spacing: Layout.value(pad: 16, phone: 13)) {
            noteTypeIcon

            VStack(alignment: .leading, spacing: isCompact ? 6 : 8) {
                titleRow
                previewRow
                if let searchSnippet, !searchSnippet.isEmpty {
                    snippetRow(searchSnippet)
                }
                metaRow
            }

            Image(systemName: "chevron.right")
                .font(.system(size: Layout.grammarNoteCardChevronSize, weight: .semibold))
                .foregroundStyle(AppColors.textSecondary.opacity(0.7))
        }
        .padding(.horizontal, Layout.grammarNoteCardHorizontalPadding)
        .padding(.vertical, isCompact ? 13 : Layout.grammarNoteCardVerticalPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Layout.grammarNoteCardCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Layout.grammarNoteCardCornerRadius, style: .continuous)
                .stroke(Color.white.opacity(0.76), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.055), radius: 14, x: 0, y: 8)
    }

    // MARK: - Sub-views
    private var noteTypeIcon: some View {
        ZStack {
            Circle()
                .fill(note.noteType.tintColor.opacity(0.14))
                .frame(width: Layout.grammarNoteCardIconSize, height: Layout.grammarNoteCardIconSize)
            Image(systemName: note.noteType.systemImage)
                .font(.system(size: Layout.grammarNoteCardIconImageSize, weight: .bold))
                .foregroundStyle(note.noteType.tintColor)
        }
    }

    private var titleRow: some View {
        HStack(spacing: 7) {
            Text(note.title)
                .font(.system(size: Layout.grammarNoteCardTitleSize, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.primaryBlueDark)
                .lineLimit(1)

            if note.isPinned {
                Image(systemName: "pin.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(AppColors.primaryBlue)
            }
            if note.isFavorite {
                Image(systemName: "heart.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(note.noteType.tintColor)
            }
        }
    }

    @ViewBuilder
    private var previewRow: some View {
        if !note.previewText.isEmpty {
            Text(note.previewText)
                .font(.system(size: Layout.grammarNoteCardPreviewSize, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
                .lineLimit(isCompact ? 1 : 2)
                .lineSpacing(2)
        }
    }

    /// Matched-content snippet shown under the preview when the parent
    /// screen has an active search query. Uses a soft accented background
    /// so the match is visible at-a-glance without overpowering the card.
    private func snippetRow(_ snippet: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: "text.magnifyingglass")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(AppColors.primaryBlue)
                .padding(.top, 1)
            Text(snippet)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.primaryBlueDark)
                .lineLimit(2)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.primaryBlue.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var metaRow: some View {
        HStack(spacing: 7) {
            metaPill(note.noteType.title, systemImage: note.noteType.systemImage)

            if note.hasQuiz {
                if let onQuizTap {
                    Button(action: onQuizTap) {
                        metaPill("Quiz", systemImage: "questionmark.circle.fill")
                    }
                    .buttonStyle(.plain)
                } else {
                    metaPill("Quiz", systemImage: "questionmark.circle.fill")
                }
            }

            ForEach(note.tags.prefix(isCompact ? 1 : 2), id: \.self) { tag in
                Text("#\(tag)")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.72))
                    .clipShape(Capsule())
            }

            Spacer(minLength: 0)

            Text(updatedText)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.textSecondary.opacity(0.82))
                .lineLimit(1)
        }
    }

    private var cardBackground: some View {
        ZStack(alignment: .topTrailing) {
            Color.white.opacity(0.92)
            Circle()
                .fill(note.noteType.tintColor.opacity(0.10))
                .frame(
                    width:  Layout.value(pad: 120, phone: 98),
                    height: Layout.value(pad: 120, phone: 98)
                )
                .offset(
                    x: Layout.value(pad: 46, phone: 38),
                    y: Layout.value(pad: -54, phone: -45)
                )
        }
    }

    private func metaPill(_ text: String, systemImage: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage).font(.system(size: 9, weight: .bold))
            Text(text).lineLimit(1)
        }
        .font(.system(size: 10, weight: .bold, design: .rounded))
        .foregroundStyle(note.noteType.tintColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(note.noteType.tintColor.opacity(0.11))
        .clipShape(Capsule())
    }

    private var updatedText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: note.updatedAt, relativeTo: Date())
    }
}

#Preview("Default") {
    VStack(spacing: 12) {
        GrammarNoteCardView(note: .preview(isPinned: true, isFavorite: true, hasQuiz: true), onQuizTap: {})
        GrammarNoteCardView(note: .preview(hasQuiz: false))
    }
    .padding()
    .background(AppColors.appBackground)
}

#Preview("With search snippet") {
    VStack(spacing: 12) {
        GrammarNoteCardView(
            note: .preview(),
            onQuizTap: nil,
            searchSnippet: "…Use ser for identity and estar for temporary state…"
        )
        GrammarNoteCardView(
            note: .preview(title: "Por vs Para", isFavorite: true, hasQuiz: false),
            onQuizTap: nil,
            searchSnippet: "…Use 'por' for cause and 'para' for purpose…"
        )
    }
    .padding()
    .background(AppColors.appBackground)
}
