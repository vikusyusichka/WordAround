import SwiftUI

struct DescribePictureImageCardView: View {
    let image: DescribePictureImage?
    let isLoading: Bool
    let errorMessage: String?
    let onRefresh: () -> Void

    private let orange = AppColors.orangeAccent

    var body: some View {
        VStack(spacing: 12) {
            imageSurface
                .frame(maxWidth: .infinity)
                .aspectRatio(16.0 / 10.0, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
                        .stroke(Color.white.opacity(0.9), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.10), radius: 18, x: 0, y: 10)
                .animation(.easeInOut(duration: 0.3), value: image?.id)

            HStack(spacing: 10) {
                if let image {
                    Text(image.attribution)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                Spacer(minLength: 0)

                refreshButton
            }
        }
    }

    @ViewBuilder
    private var imageSurface: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
                .fill(orange.opacity(0.08))

            if let url = image?.url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        loadingState
                    case .success(let img):
                        img
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        failureState("Could not load image.")
                    @unknown default:
                        loadingState
                    }
                }
            } else if let errorMessage {
                failureState(errorMessage)
            } else {
                loadingState
            }
        }
    }

    private var loadingState: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(orange)
            Text(isLoading ? "Loading picture…" : "Preparing picture…")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
        }
    }

    private func failureState(_ message: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "photo.badge.exclamationmark")
                .font(.system(size: 30, weight: .medium))
                .foregroundColor(orange)
            Text(message)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
    }

    private var refreshButton: some View {
        Button(action: onRefresh) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 13, weight: .bold))
                Text(L10n.string("spkNewPicture"))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                LinearGradient(
                    colors: [orange, AppColors.orangeTitle],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(Capsule())
            .shadow(color: orange.opacity(0.30), radius: 10, x: 0, y: 5)
            .opacity(isLoading ? 0.55 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }
}

#Preview {
    ZStack {
        AppColors.appBackground.ignoresSafeArea()
        DescribePictureImageCardView(
            image: DescribePictureImage(
                id: "x",
                imageURL: "https://images.unsplash.com/photo-1506744038136-46273834b3fb",
                authorName: "Jane Doe",
                authorURL: "https://unsplash.com"
            ),
            isLoading: false,
            errorMessage: nil,
            onRefresh: {}
        )
        .padding(20)
    }
}
