import SwiftUI

struct ProfileDashboardCardChrome: ViewModifier {
    var accent: Color = AppColors.primaryBlue
    var blobOpacity: Double = 0.09

    func body(content: Content) -> some View {
        content
            .background(
                ZStack(alignment: .topTrailing) {
                    Color.white.opacity(0.88)

                    BlobShape()
                        .fill(accent.opacity(blobOpacity))
                        .frame(
                            width: Layout.isPadLike ? 150 : 110,
                            height: Layout.isPadLike ? 120 : 90
                        )
                        .rotationEffect(.degrees(-9))
                        .offset(
                            x: Layout.isPadLike ? 48 : 36,
                            y: Layout.isPadLike ? -40 : -28
                        )
                }
            )
            .clipShape(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.white.opacity(0.62), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.045), radius: 18, x: 0, y: 10)
    }
}

extension View {
    func profileDashboardCard(
        accent: Color = AppColors.primaryBlue,
        blobOpacity: Double = 0.09
    ) -> some View {
        modifier(ProfileDashboardCardChrome(accent: accent, blobOpacity: blobOpacity))
    }
}

// MARK: - Header

struct ProfileSubScreenHeader: View {
    let title: String
    let subtitle: String?
    let onBack: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 13) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .black))
                    .foregroundStyle(AppColors.primaryBlueDark)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.88))
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 5)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(AppColors.primaryBlueDark)

                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.textSecondary)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 0)
        }
    }
}
