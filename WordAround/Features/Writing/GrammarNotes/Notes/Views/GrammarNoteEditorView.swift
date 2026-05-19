import SwiftUI

struct GrammarNoteEditorView: View {
    let note: GrammarNote

    private var isPadLike: Bool {
        UIDevice.current.userInterfaceIdiom == .pad || UIScreen.main.bounds.width >= 700
    }

    var body: some View {
        ZStack {
            AppColors.appBackground.ignoresSafeArea()

            VStack(alignment: .leading, spacing: isPadLike ? 18 : 14) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(note.noteType.tintColor.opacity(0.14))
                            .frame(width: isPadLike ? 58 : 50, height: isPadLike ? 58 : 50)

                        Image(systemName: note.noteType.systemImage)
                            .font(.system(size: isPadLike ? 24 : 21, weight: .bold))
                            .foregroundStyle(note.noteType.tintColor)
                    }

                    VStack(alignment: .leading, spacing: 5) {
                        Text(note.title)
                            .font(.system(size: isPadLike ? 28 : 23, weight: .bold, design: .rounded))
                            .foregroundStyle(AppColors.primaryBlueDark)
                            .lineLimit(2)

                        Text(note.noteType.title)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(note.noteType.tintColor)
                    }
                }

                if !note.previewText.isEmpty {
                    Text(note.previewText)
                        .font(.system(size: isPadLike ? 16 : 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppColors.textSecondary)
                        .lineSpacing(3)
                }

                Text("Rich editor will be added in the next step.")
                    .font(.system(size: isPadLike ? 17 : 15, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.primaryBlueDark)
                    .padding(isPadLike ? 22 : 18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.92))
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .shadow(color: Color.black.opacity(0.055), radius: 16, x: 0, y: 8)

                Spacer()
            }
            .padding(isPadLike ? 28 : 20)
        }
        .navigationTitle("Grammar Note")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        GrammarNoteEditorView(note: .preview(isPinned: true, isFavorite: true, hasQuiz: true))
    }
}
