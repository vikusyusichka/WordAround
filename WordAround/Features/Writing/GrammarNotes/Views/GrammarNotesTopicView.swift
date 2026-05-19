import SwiftUI

struct GrammarNotesTopicView: View {
    let topic: GrammarNoteTopic

    private var isPadLike: Bool {
        UIDevice.current.userInterfaceIdiom == .pad || UIScreen.main.bounds.width >= 700
    }

    var body: some View {
        ZStack {
            AppColors.appBackground.ignoresSafeArea()

            VStack(alignment: .leading, spacing: isPadLike ? 18 : 14) {
                VStack(alignment: .leading, spacing: 10) {
                    Image(systemName: topic.icon)
                        .font(.system(size: isPadLike ? 34 : 28, weight: .semibold))
                        .foregroundColor(AppColors.primaryBlue)
                        .frame(width: isPadLike ? 68 : 58, height: isPadLike ? 68 : 58)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 8)

                    Text(topic.title)
                        .font(.system(size: isPadLike ? 30 : 25, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.primaryBlueDark)

                    Text(topic.description)
                        .font(.system(size: isPadLike ? 16 : 14, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                        .lineSpacing(3)
                }
                .padding(isPadLike ? 24 : 20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.94))
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                .shadow(color: Color.black.opacity(0.055), radius: 18, x: 0, y: 10)

                Text("Notes will be added here later.")
                    .font(.system(size: isPadLike ? 16 : 14, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
                    .padding(isPadLike ? 22 : 18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.82))
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

                Spacer()
            }
            .padding(isPadLike ? 28 : 20)
        }
        .navigationTitle("Grammar Notes")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        GrammarNotesTopicView(topic: .commonMistakes(ownerUID: "preview"))
    }
}
