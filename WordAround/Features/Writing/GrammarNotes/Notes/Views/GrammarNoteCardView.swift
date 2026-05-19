import SwiftUI

struct GrammarNoteCardView: View {
    let note: GrammarNote
    var isCompact: Bool = false

    private var isPadLike: Bool {
        UIDevice.current.userInterfaceIdiom == .pad || UIScreen.main.bounds.width >= 700
    }

    var body: some View {
        HStack(spacing: isPadLike ? 16 : 13) {
            noteTypeIcon

            VStack(alignment: .leading, spacing: isCompact ? 6 : 8) {
                HStack(spacing: 7) {
                    Text(note.title)
                        .font(.system(size: isPadLike ? 17 : 15, weight: .bold, design: .rounded))
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

                if !note.previewText.isEmpty {
                    Text(note.previewText)
                        .font(.system(size: isPadLike ? 14 : 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppColors.textSecondary)
                        .lineLimit(isCompact ? 1 : 2)
                        .lineSpacing(2)
                }

                HStack(spacing: 7) {
                    metaPill(note.noteType.title, systemImage: note.noteType.systemImage)

                    if note.hasQuiz {
                        metaPill("Quiz", systemImage: "questionmark.circle.fill")
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

            Image(systemName: "chevron.right")
                .font(.system(size: isPadLike ? 15 : 13, weight: .semibold))
                .foregroundStyle(AppColors.textSecondary.opacity(0.7))
        }
        .padding(.horizontal, isPadLike ? 18 : 15)
        .padding(.vertical, isCompact ? 13 : (isPadLike ? 17 : 15))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: isPadLike ? 25 : 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: isPadLike ? 25 : 22, style: .continuous)
                .stroke(Color.white.opacity(0.76), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.055), radius: 14, x: 0, y: 8)
    }

    private var noteTypeIcon: some View {
        ZStack {
            Circle()
                .fill(note.noteType.tintColor.opacity(0.14))
                .frame(width: isPadLike ? 52 : 46, height: isPadLike ? 52 : 46)

            Image(systemName: note.noteType.systemImage)
                .font(.system(size: isPadLike ? 21 : 18, weight: .bold))
                .foregroundStyle(note.noteType.tintColor)
        }
    }

    private var cardBackground: some View {
        ZStack(alignment: .topTrailing) {
            Color.white.opacity(0.92)

            Circle()
                .fill(note.noteType.tintColor.opacity(0.10))
                .frame(width: isPadLike ? 120 : 98, height: isPadLike ? 120 : 98)
                .offset(x: isPadLike ? 46 : 38, y: isPadLike ? -54 : -45)
        }
    }

    private func metaPill(_ text: String, systemImage: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
                .font(.system(size: 9, weight: .bold))
            Text(text)
                .lineLimit(1)
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

#Preview {
    GrammarNoteCardView(note: .preview(isPinned: true, isFavorite: true, hasQuiz: true))
        .padding()
        .background(AppColors.appBackground)
}
