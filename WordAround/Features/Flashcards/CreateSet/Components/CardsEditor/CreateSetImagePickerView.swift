import SwiftUI
import PhotosUI

struct CreateSetImagePickerView: View {
    let theme: CreateSetTheme
    let image: UIImage?
    let onPickImage: (PhotosPickerItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.createSetCardsFieldSpacing) {
            HStack(spacing: 4) {
                CreateSetSectionLabel(text: "Image", theme: theme)
                CreateSetOptionalText(theme: theme, fontSize: Layout.createSetCardsOptionalTextSize)
            }

            PhotosPicker(
                selection: Binding<PhotosPickerItem?>(
                    get: { nil },
                    set: { item in
                        guard let item else { return }
                        onPickImage(item)
                    }
                ),
                matching: .images
            ) {
                VStack(spacing: Layout.createSetCardsImageContentSpacing) {
                    if let image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(
                                maxWidth: Layout.createSetCardsImageMaxWidth,
                                minHeight: Layout.createSetCardsImageMinHeight
                            )
                            .clipped()
                    } else {
                        Image(systemName: "photo.fill")
                            .font(.system(size: Layout.createSetCardsImageIconSize))
                            .foregroundStyle(theme.accent)

                        Text("Add image")
                            .font(.system(size: Layout.createSetCardsImageTitleSize, weight: .bold))
                            .foregroundStyle(theme.textColor)
                            .lineLimit(1)

                        Text(Layout.isPadLike ? "Tap to upload or choose from gallery" : "Upload")
                            .font(.system(size: Layout.createSetCardsImageSubtitleSize, weight: .semibold))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(theme.mutedTextColor)
                            .lineLimit(Layout.createSetCardsImageLineLimit)
                    }
                }
                .frame(maxWidth: Layout.createSetCardsImageMaxWidth, minHeight: Layout.createSetCardsImageMinHeight)
                .background(theme.imageBackground)
                .clipShape(RoundedRectangle(cornerRadius: Layout.createSetCardsImageCornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Layout.createSetCardsImageCornerRadius, style: .continuous)
                        .stroke(theme.accent.opacity(0.45), style: StrokeStyle(lineWidth: 1, dash: [5]))
                )
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    CreateSetImagePickerView(theme: .blue, image: nil, onPickImage: { _ in })
        .padding()
        .background(CreateSetTheme.blue.screenBackground)
}
