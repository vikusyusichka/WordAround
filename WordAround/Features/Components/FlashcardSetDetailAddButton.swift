import SwiftUI

struct FlashcardSetDetailAddButton: View {
    let theme: CreateSetTheme
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "plus")
                    .font(.system(size: Layout.flashcardDetailAddButtonIconSize, weight: .bold))

                Text("Add card")
                    .font(.system(size: Layout.flashcardDetailAddButtonTextSize, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(theme.accent)
            .frame(maxWidth: .infinity)
            .frame(height: Layout.flashcardDetailAddButtonHeight)
            .background(theme.fieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: Layout.flashcardDetailAddButtonCornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Layout.flashcardDetailAddButtonCornerRadius, style: .continuous)
                    .stroke(theme.borderColor, lineWidth: 1)
            }
            .shadow(color: theme.shadowColor, radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        CreateSetTheme.yellow.screenBackground
            .ignoresSafeArea()

        FlashcardSetDetailAddButton(
            theme: .yellow,
            onTap: {}
        )
        .padding(.horizontal, 20)
    }
}
