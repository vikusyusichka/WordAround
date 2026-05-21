import SwiftUI

struct AddGrammarNoteBlockSheet: View {
    let allowsQuiz: Bool
    let onSelect: (GrammarNoteBlockType) -> Void
    let onCancel: () -> Void

    private var blockTypes: [GrammarNoteBlockType] {
        GrammarNoteBlockType.allCases.filter { allowsQuiz || $0 != .quiz }
    }

    private var isPadLike: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.appBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: isPadLike ? 220 : 150), spacing: 12)], spacing: 12) {
                        ForEach(blockTypes) { type in
                            Button {
                                onSelect(type)
                            } label: {
                                VStack(alignment: .leading, spacing: 10) {
                                    Image(systemName: type.systemImage)
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundStyle(AppColors.primaryBlue)
                                        .frame(width: 42, height: 42)
                                        .background(AppColors.primaryBlue.opacity(0.11))
                                        .clipShape(Circle())

                                    Text(type.title)
                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                        .foregroundStyle(AppColors.primaryBlueDark)

                                    Text(type.subtitle)
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                        .foregroundStyle(AppColors.textSecondary)
                                        .lineLimit(2)
                                }
                                .padding(16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.white.opacity(0.92))
                                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                                        .stroke(Color.white.opacity(0.72), lineWidth: 1)
                                )
                                .shadow(color: Color.black.opacity(0.045), radius: 12, x: 0, y: 7)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(isPadLike ? 28 : 20)
                }
            }
            .navigationTitle("Add Block")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done", action: onCancel)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    AddGrammarNoteBlockSheet(allowsQuiz: true, onSelect: { _ in }, onCancel: {})
}
