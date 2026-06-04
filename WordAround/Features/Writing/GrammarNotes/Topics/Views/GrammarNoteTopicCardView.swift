import SwiftUI

struct GrammarNoteTopicCardView: View {
    let topic: GrammarNoteTopic
    var isEditing: Bool = false

    private var isPadLike: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    private let theme: CreateSetTheme

    init(topic: GrammarNoteTopic, isEditing: Bool = false) {
        self.topic = topic
        self.isEditing = isEditing
        self.theme = CreateSetTheme.theme(forHex: topic.colorHex)
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

            if !isEditing {
                Image(systemName: "chevron.right")
                    .font(.system(size: isPadLike ? 16 : 14, weight: .semibold))
                    .foregroundStyle(theme.mutedTextColor.opacity(0.78))
            }
        }
        .padding(Layout.grammarSettingsCardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
        .clipShape(
            RoundedRectangle(
                cornerRadius: Layout.grammarSettingsCardCornerRadius,
                style: .continuous
            )
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: Layout.grammarSettingsCardCornerRadius,
                style: .continuous
            )
            .stroke(Color.white.opacity(0.62), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.045), radius: 18, x: 0, y: 10)
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
            Color.white.opacity(0.84)

            BlobShape()
                .fill(theme.accent.opacity(topic.isMistakesTopic ? 0.14 : 0.09))
                .frame(
                    width: Layout.isPadLike ? 150 : 110,
                    height: Layout.isPadLike ? 120 : 90
                )
                .rotationEffect(.degrees(-9))
                .offset(
                    x: Layout.isPadLike ? 48 : 36,
                    y: Layout.isPadLike ? -40 : -28
                )
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
