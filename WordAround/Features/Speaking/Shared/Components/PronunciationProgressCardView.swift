import SwiftUI

/// Slim session-progress bar: "Item X of Y" plus a fill bar. Presentation only.
struct PronunciationProgressCardView: View {
    let currentIndex: Int
    let total: Int
    let progress: Double

    private let accent = PronunciationTrainerTheme.accent
    private let accentDark = PronunciationTrainerTheme.accentDark

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Item \(min(currentIndex + 1, max(total, 1))) of \(total)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(accentDark)
                Spacer()
                Text("\(Int((progress * 100).rounded()))%")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(accent)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(accent.opacity(0.14)).frame(height: 8)
                    Capsule()
                        .fill(LinearGradient(colors: [accent, accentDark], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(8, geo.size.width * progress), height: 8)
                        .animation(.easeInOut(duration: 0.25), value: progress)
                }
            }
            .frame(height: 8)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.94))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
    }
}

#Preview {
    ZStack {
        AppColors.appBackground.ignoresSafeArea()
        PronunciationProgressCardView(currentIndex: 2, total: 10, progress: 0.3).padding()
    }
}
