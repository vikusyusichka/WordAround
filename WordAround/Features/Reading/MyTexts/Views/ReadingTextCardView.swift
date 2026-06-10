import SwiftUI

struct ReadingTextCardView: View {
    let title: String
    let preview: String
    let languageTitle: String
    let levelTitle: String
    let wordCount: Int
    let progress: Double
    var statusLabel: String? = nil
    let dateText: String
    let actionTitle: String
    let onAction: () -> Void
    var onDelete: (() -> Void)? = nil
    var onRename: (() -> Void)? = nil
    var onMarkCompleted: (() -> Void)? = nil

    private let accent = ReadingMyTextsTheme.accent
    private let accentDark = ReadingMyTextsTheme.accentDark

    private var progressPercent: Int { Int((progress * 100).rounded()) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: Layout.isPadLike ? 17 : 15, weight: .bold, design: .rounded))
                    .foregroundColor(accentDark)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(preview)
                    .font(.system(size: Layout.isPadLike ? 14 : 13, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 6) {
                ReadingMetadataChip(text: languageTitle, accent: accent)
                ReadingMetadataChip(text: levelTitle, accent: accent)
                ReadingMetadataChip(text: String(format: L10n.string("readingWordsCountFmt"), wordCount), accent: accent)
                if let statusLabel {
                    ReadingMetadataChip(text: statusLabel, accent: accent)
                }
                Spacer(minLength: 0)
            }

            if progress > 0 {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("\(progressPercent)%")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(accent)
                        Spacer()
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(accent.opacity(0.12))
                                .frame(height: 4)
                            Capsule()
                                .fill(accent)
                                .frame(width: max(4, geo.size.width * min(progress, 1)), height: 4)
                        }
                    }
                    .frame(height: 4)
                }
            }

            Text(dateText)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.mutedText)

            HStack(spacing: 10) {
                Button(action: onAction) {
                    Text(actionTitle)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(accentDark)
                        .padding(.horizontal, 14)
                        .frame(height: 34)
                        .background(accent.opacity(0.12))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Spacer(minLength: 0)

                if onDelete != nil || onRename != nil || onMarkCompleted != nil {
                    Menu {
                        if let onRename {
                            Button(action: onRename) {
                                Label(L10n.string("commonRename"), systemImage: "pencil")
                            }
                        }
                        if let onMarkCompleted {
                            Button(action: onMarkCompleted) {
                                Label(L10n.string("readingMarkCompleted"), systemImage: "checkmark.circle")
                            }
                        }
                        if let onDelete {
                            Button(role: .destructive, action: onDelete) {
                                Label(L10n.localized(.commonDelete), systemImage: "trash")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AppColors.mutedText)
                            .frame(width: 34, height: 34)
                            .background(AppColors.mutedText.opacity(0.10))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(L10n.string("readingMoreOptions"))
                }
            }
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
}

#Preview {
    ZStack {
        AppColors.appBackground.ignoresSafeArea()
        ReadingTextCardView(
            title: ReadingMyTextsPreviewData.mediumText.title,
            preview: ReadingMyTextsPreviewData.mediumText.preview,
            languageTitle: "English",
            levelTitle: "B1",
            wordCount: 142,
            progress: 0.65,
            dateText: "Opened Yesterday",
            actionTitle: "Continue",
            onAction: {},
            onDelete: {}
        )
        .padding()
    }
}
