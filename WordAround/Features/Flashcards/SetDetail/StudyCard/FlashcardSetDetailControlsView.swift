import SwiftUI

struct FlashcardSetDetailControlsView: View {
    let theme: CreateSetTheme
    @Binding var trackProgress: Bool
    let onShuffle: () -> Void
    let onEdit: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: Layout.flashcardDetailControlsInnerSpacing) {
                Text(L10n.string("flashcardTrackProgress"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Toggle("", isOn: $trackProgress)
                    .labelsHidden()
                    .tint(theme.accent)
                    .scaleEffect(Layout.flashcardDetailControlsToggleScale)
                    .frame(width: Layout.flashcardDetailControlsToggleWidth)
            }

            Spacer(minLength: 16)

            HStack(spacing: 0) {
                Button(action: onShuffle) {
                    Image(systemName: "shuffle")
                        .font(.system(size: Layout.flashcardDetailControlsMainIconSize, weight: .bold))
                }
                .buttonStyle(.plain)

                controlsDivider

                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: Layout.flashcardDetailControlsMainIconSize, weight: .bold))
                }
                .buttonStyle(.plain)
            }
        }
        .font(.system(size: Layout.flashcardDetailControlsTextSize, weight: .bold, design: .rounded))
        .foregroundStyle(theme.mutedTextColor)
    }

    private var controlsDivider: some View {
        Rectangle()
            .fill(theme.borderColor.opacity(0.4))
            .frame(width: 1, height: Layout.flashcardDetailControlsDividerHeight)
            .padding(.horizontal, Layout.flashcardDetailControlsDividerPadding)
    }
}

#Preview {
    ZStack {
        CreateSetTheme.yellow.screenBackground
            .ignoresSafeArea()

        FlashcardSetDetailControlsView(
            theme: .yellow,
            trackProgress: .constant(true),
            onShuffle: {},
            onEdit: {}
        )
        .padding(.horizontal, 20)
    }
}
