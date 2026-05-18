import SwiftUI

struct WritingMenuCardView: View {
    let item: WritingMenuItem

    private var isPadLike: Bool {
        UIDevice.current.userInterfaceIdiom == .pad || UIScreen.main.bounds.width >= 700
    }

    var body: some View {
        HStack(spacing: isPadLike ? 18 : 14) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(LinearGradient(colors: item.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: isPadLike ? 62 : 50, height: isPadLike ? 62 : 50)
                .overlay(
                    Image(systemName: item.systemImage)
                        .font(.system(size: isPadLike ? 25 : 21, weight: .semibold))
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 5) {
                Text(item.title)
                    .font(.system(size: isPadLike ? 18 : 16, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primaryBlueDark)

                Text(item.subtitle)
                    .font(.system(size: isPadLike ? 14 : 12, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
                    .lineSpacing(2)
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.system(size: isPadLike ? 16 : 14, weight: .semibold))
                .foregroundColor(AppColors.textSecondary.opacity(0.75))
        }
        .padding(.horizontal, isPadLike ? 22 : 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: isPadLike ? 94 : 80)
        .background(Color.white.opacity(0.94))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: Color.black.opacity(0.055), radius: 18, x: 0, y: 10)
    }
}

#Preview {
    WritingMenuCardView(item: WritingViewModel().menuItems[0])
        .padding()
        .background(AppColors.appBackground)
}
