import SwiftUI

struct FlashcardSetDetailBottomCover: View {
    let theme: CreateSetTheme

    var body: some View {
        LinearGradient(
            colors: [
                theme.screenBackground.opacity(0),
                theme.screenBackground.opacity(0.96),
                theme.screenBackground
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(maxWidth: .infinity)
        .frame(height: Layout.flashcardDetailBottomCoverHeight)
        .ignoresSafeArea(edges: .bottom)
        .allowsHitTesting(false)
    }
}

#Preview {
    ZStack(alignment: .bottom) {
        CreateSetTheme.yellow.screenBackground
            .ignoresSafeArea()

        VStack(spacing: 12) {
            Spacer()

            Text("Hola")
            Text("Gracias")
            Text("Buenos días")
            Text("Buenas noches")
        }
        .font(.system(size: 22, weight: .bold))
        .foregroundStyle(CreateSetTheme.yellow.titleColor)

        FlashcardSetDetailBottomCover(theme: .yellow)
    }
}
