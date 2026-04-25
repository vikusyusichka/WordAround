import SwiftUI

struct FlashcardSetDetailHeaderView: View {
    let theme: CreateSetTheme
    let title: String
    let description: String
    let ownerEmail: String
    @Binding var isDescriptionExpanded: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {

            HStack(alignment: .center) {
                Text(title)
                    .font(.system(size: Layout.flashcardDetailHeaderTitleSize, weight: .bold))
                    .foregroundStyle(theme.titleColor)

                Spacer()

                avatars
            }

            HStack(alignment: .bottom, spacing: 6) {
                Text(description)
                    .font(.system(size: Layout.flashcardDetailHeaderDescriptionSize))
                    .foregroundStyle(theme.mutedTextColor)
                    .lineLimit(isDescriptionExpanded ? nil : 1)

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isDescriptionExpanded.toggle()
                    }
                } label: {
                    Text(isDescriptionExpanded ? "Show less" : "Show more")
                        .font(.system(size: Layout.flashcardDetailDescriptionButtonSize, weight: .semibold))
                        .foregroundStyle(theme.accent)
                }
            }
        }
        .padding(.top, 10)
        .padding(.bottom, 10)
    }
}

private extension FlashcardSetDetailHeaderView {
    var avatars: some View {
        HStack(spacing: -8) {
            avatar("V")
            avatar("U")
        }
    }

    func avatar(_ letter: String) -> some View {
        ZStack {
            Circle()
                .fill(theme.fieldBackground.opacity(0.8))
                .frame(width: Layout.flashcardDetailAvatarSize,
                       height: Layout.flashcardDetailAvatarSize)

            Text(letter)
                .font(.system(size: Layout.flashcardDetailAvatarTextSize, weight: .semibold))
                .foregroundStyle(theme.titleColor)
        }
    }
}

#Preview {
    ZStack {
        CreateSetTheme.yellow.screenBackground
            .ignoresSafeArea()

        FlashcardSetDetailHeaderView(
            theme: .yellow,
            title: "Daily Conversation",
            description: "A collection of useful phrases for everyday conversations.",
            ownerEmail: "vika@example.com",
            isDescriptionExpanded: .constant(false)
        )
        .padding(.horizontal, 20)
    }
}
