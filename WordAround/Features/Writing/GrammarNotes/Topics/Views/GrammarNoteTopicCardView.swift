import SwiftUI

struct GrammarNoteTopicCardView: View {
    let topic: GrammarNoteTopic

    private var isPadLike: Bool {
        UIDevice.current.userInterfaceIdiom == .pad || UIScreen.main.bounds.width >= 700
    }

    private var theme: CreateSetTheme {
        CreateSetTheme.theme(forHex: topic.colorHex)
    }

    var body: some View {
        HStack(spacing: isPadLike ? 18 : 14) {
            iconView

            VStack(alignment: .leading, spacing: 7) {
                titleRow

                Text(topic.description)
                    .font(.system(size: isPadLike ? 14 : 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(theme.mutedTextColor)
                    .lineLimit(2)
                    .lineSpacing(2)

                HStack(spacing: 8) {
                    metaPill(text: "\(topic.notesCount) notes", systemImage: "doc.text.fill")
                    metaPill(text: topic.languageName, systemImage: "globe")
                }
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.system(size: isPadLike ? 16 : 14, weight: .semibold))
                .foregroundStyle(theme.mutedTextColor.opacity(0.78))
        }
        .padding(.horizontal, isPadLike ? 22 : 18)
        .padding(.vertical, isPadLike ? 18 : 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: isPadLike ? 28 : 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: isPadLike ? 28 : 24, style: .continuous)
                .stroke(topic.isMistakesTopic ? theme.borderColor : theme.softBorderColor, lineWidth: 1)
        )
        .shadow(color: theme.shadowColor, radius: 18, x: 0, y: 10)
    }

    private var titleRow: some View {
        HStack(spacing: 7) {
            Text(topic.title)
                .font(.system(size: isPadLike ? 18 : 16, weight: .bold, design: .rounded))
                .foregroundStyle(theme.titleColor)
                .lineLimit(1)

            if topic.isPinned {
                Image(systemName: "pin.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(theme.accent)
            }

            if topic.isMistakesTopic {
                badgeView
            }
        }
    }

    private var iconView: some View {
        ZStack {
            Circle()
                .fill(theme.softAccent)
                .frame(width: isPadLike ? 58 : 50, height: isPadLike ? 58 : 50)

            Image(systemName: topic.icon)
                .font(.system(size: isPadLike ? 23 : 20, weight: .bold))
                .foregroundStyle(theme.accent)
        }
    }

    private var cardBackground: some View {
        ZStack(alignment: .topTrailing) {
            topic.isMistakesTopic ? theme.previewBackground : theme.sectionBackground

            Circle()
                .fill(theme.softAccent)
                .frame(width: isPadLike ? 132 : 112, height: isPadLike ? 132 : 112)
                .offset(x: isPadLike ? 54 : 46, y: isPadLike ? -58 : -50)
                .opacity(topic.isMistakesTopic ? 1 : 0.55)
        }
    }

    private var badgeView: some View {
        Text("Mistakes")
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundStyle(theme.accent)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(theme.softAccent)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(theme.softBorderColor, lineWidth: 1)
            )
    }

    private func metaPill(text: String, systemImage: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: systemImage)
                .font(.system(size: 10, weight: .bold))

            Text(text)
                .lineLimit(1)
        }
        .font(.system(size: isPadLike ? 12 : 10, weight: .bold, design: .rounded))
        .foregroundStyle(theme.mutedTextColor)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(theme.fieldBackground)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(theme.softBorderColor, lineWidth: 1)
        )
    }
}

#Preview {
    GrammarNoteTopicCardView(
        topic: GrammarNoteTopic(
            id: "preview",
            ownerUID: "preview",
            title: "Spanish Tenses",
            description: "Rules, examples and useful patterns for past and present tenses.",
            languageCode: "es",
            languageName: "Spanish",
            icon: "text.book.closed.fill",
            colorHex: SetColor.blue.hex,
            notesCount: 12,
            isPinned: true,
            isMistakesTopic: false,
            createdAt: Date(),
            updatedAt: Date()
        )
    )
    .padding()
    .background(CreateSetTheme.blue.screenBackground)
}
