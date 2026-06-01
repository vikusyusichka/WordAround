import SwiftUI

struct ReadingLibraryItemCardView: View {
    let item: ReadingLibraryItem
    let accent: Color
    let accentDark: Color
    var systemImage: String = "book.fill"
    let onOpen: () -> Void
    var onDelete: (() -> Void)? = nil
    var onRename: (() -> Void)? = nil
    var onOpenSourceSet: (() -> Void)? = nil

    var body: some View {
        Button(action: onOpen) {
            VStack(alignment: .leading, spacing: 12) {
                header

                if !item.preview.isEmpty {
                    Text(item.preview)
                        .font(.system(size: Layout.isPadLike ? 14 : 13, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                chips

                if item.progress > 0 && !item.isCompleted { progressBar }

                footer
            }
            .padding(Layout.isPadLike ? 16 : 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
                    .fill(Color.white.opacity(0.94))
                    .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.92), lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(action: onOpen) { Label("Open", systemImage: "book") }
            if let onOpenSourceSet {
                Button(action: onOpenSourceSet) {
                    Label("View flashcard set", systemImage: "rectangle.stack")
                }
            }
            if let onRename {
                Button(action: onRename) { Label("Rename", systemImage: "pencil") }
            }
            if let onDelete {
                Button(role: .destructive, action: onDelete) { Label("Delete", systemImage: "trash") }
            }
        }
    }

    // MARK: - Pieces

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(accent.opacity(0.14))
                    .frame(width: 40, height: 40)
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(accent)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.system(size: Layout.isPadLike ? 17 : 15, weight: .bold, design: .rounded))
                    .foregroundColor(accentDark)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                statusBadge
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var statusBadge: some View {
        Text(item.status.label)
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundColor(item.isCompleted ? accent : AppColors.mutedText)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background((item.isCompleted ? accent : AppColors.mutedText).opacity(0.12))
            .clipShape(Capsule())
    }

    private var chips: some View {
        HStack(spacing: 6) {
            if !item.difficulty.isEmpty {
                ReadingMetadataChip(text: item.difficulty, accent: accent)
            }
            ReadingMetadataChip(text: item.minutesText, accent: accent)
            if let scoreText = item.scoreText {
                ReadingMetadataChip(text: scoreText, accent: accent)
            } else if let firstTag = item.tags.first {
                ReadingMetadataChip(text: firstTag, accent: accent)
            }
            Spacer(minLength: 0)
        }
    }

    private var progressBar: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(item.progressPercent)%")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(accent)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(accent.opacity(0.12))
                        .frame(height: 4)
                    Capsule()
                        .fill(accent)
                        .frame(width: max(4, geo.size.width * min(item.progress, 1)), height: 4)
                }
            }
            .frame(height: 4)
        }
    }

    private var footer: some View {
        HStack(spacing: 10) {
            Text(item.dateText)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.mutedText)

            Spacer(minLength: 0)

            Text(item.actionTitle)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(accentDark)
                .padding(.horizontal, 14)
                .frame(height: 32)
                .background(accent.opacity(0.12))
                .clipShape(Capsule())

            if let onDelete {
                Menu {
                    Button(action: onOpen) { Label("Open", systemImage: "book") }
                    if let onRename {
                        Button(action: onRename) { Label("Rename", systemImage: "pencil") }
                    }
                    Button(role: .destructive, action: onDelete) { Label("Delete", systemImage: "trash") }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(AppColors.mutedText)
                        .frame(width: 32, height: 32)
                        .background(AppColors.mutedText.opacity(0.10))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("More options")
            }
        }
    }
}

#Preview {
    ZStack {
        AppColors.appBackground.ignoresSafeArea()
        ReadingLibraryItemCardView(
            item: ReadingLibraryItem(
                userId: "preview",
                modeID: ReadingMode.myTextsID,
                title: "A Morning in the City",
                preview: "The streets were quiet as the first light touched the rooftops…",
                difficulty: "B1",
                estimatedMinutes: 4,
                lastOpenedAt: Date(),
                progress: 0.45,
                comprehensionScore: 0.8,
                tags: ["Travel"],
                status: .inProgress
            ),
            accent: ReadingMyTextsTheme.accent,
            accentDark: ReadingMyTextsTheme.accentDark,
            systemImage: "doc.text.fill",
            onOpen: {},
            onDelete: {}
        )
        .padding()
    }
}
