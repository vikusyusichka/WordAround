import SwiftUI

struct FlashcardSetDetailAddButton: View {
    let theme: CreateSetTheme
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .bold))

                Text(L10n.string("flashcardAddCard"))
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(theme.titleColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(theme.sectionBackground)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(theme.borderColor.opacity(0.35), lineWidth: 1)
            }
            .shadow(color: theme.shadowColor, radius: 10, x: 0, y: 5)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    FlashcardSetDetailAddButton(theme: .purple, onTap: { })
        .padding()
        .background(CreateSetTheme.purple.screenBackground)
}
