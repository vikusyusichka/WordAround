import SwiftUI

struct FlashcardSetDetailTopBarView: View {
    let theme: CreateSetTheme
    let onBack: () -> Void
    let onMore: () -> Void

    var body: some View {
        HStack {
            Button(action: onBack) {
                Circle()
                    .fill(theme.fieldBackground)
                    .frame(width: Layout.flashcardDetailTopButtonSize,
                           height: Layout.flashcardDetailTopButtonSize)
                    .overlay(
                        Image(systemName: "chevron.left")
                            .font(.system(size: Layout.flashcardDetailTopButtonIconSize, weight: .semibold))
                            .foregroundStyle(theme.mutedTextColor)
                    )
            }

            Spacer()

            Button(action: onMore) {
                Circle()
                    .fill(theme.fieldBackground)
                    .frame(width: Layout.flashcardDetailTopButtonSize,
                           height: Layout.flashcardDetailTopButtonSize)
                    .overlay(
                        Image(systemName: "ellipsis")
                            .font(.system(size: Layout.flashcardDetailTopButtonIconSize, weight: .semibold))
                            .foregroundStyle(theme.mutedTextColor)
                    )
            }
        }
        .padding(.horizontal, 0)
        .padding(.top, 4)
    }
}

#Preview {
    ZStack {
        CreateSetTheme.yellow.screenBackground
            .ignoresSafeArea()

        FlashcardSetDetailTopBarView(
            theme: .yellow,
            onBack: {},
            onMore: {}
        )
    }
}
