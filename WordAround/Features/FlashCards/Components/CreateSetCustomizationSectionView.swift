import SwiftUI

struct CreateSetCustomizationSectionView: View {
    @ObservedObject var viewModel: CreateSetViewModel

    private var isPadLike: Bool {
        UIDevice.current.userInterfaceIdiom == .pad || UIScreen.main.bounds.width >= 700
    }

    var body: some View {
        VStack(alignment: .leading, spacing: isPadLike ? 22 : 16) {
            folderPicker
            colorPicker
        }
        .padding(isPadLike ? 22 : 14)
        .background(sectionBackground)
    }

    private var folderPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Choose folder")

            HStack {
                Image(systemName: "folder.fill")
                    .foregroundStyle(AppColors.createSetTextMuted)

                Text(viewModel.draft.folderName ?? "No folder")
                    .font(.system(size: isPadLike ? 16 : 14, weight: .semibold))
                    .foregroundStyle(AppColors.createSetTextMuted)

                Spacer()

                Image(systemName: "chevron.down")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppColors.createSetTextMuted)
            }
            .padding(.horizontal, 14)
            .frame(height: isPadLike ? 50 : 46)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(AppColors.createSetBorder, lineWidth: 1)
            )
        }
    }

    private var colorPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Choose color")

            HStack {
                ForEach(viewModel.availableColors, id: \.self) { color in
                    Button {
                        viewModel.selectColor(color)
                    } label: {
                        Circle()
                            .fill(color.opacity(0.75))
                            .frame(width: isPadLike ? 36 : 28, height: isPadLike ? 36 : 28)
                            .overlay {
                                if viewModel.draft.selectedColor == color {
                                    Circle()
                                        .stroke(Color.white, lineWidth: isPadLike ? 4 : 3)

                                    Circle()
                                        .stroke(AppColors.createSetRed, lineWidth: 2)
                                        .frame(
                                            width: isPadLike ? 44 : 34,
                                            height: isPadLike ? 44 : 34
                                        )
                                }
                            }
                    }
                    .buttonStyle(.plain)

                    if color != viewModel.availableColors.last {
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, isPadLike ? 20 : 8)
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: isPadLike ? 16 : 13, weight: .bold))
            .foregroundStyle(AppColors.createSetDarkRed)
    }

    private var sectionBackground: some View {
        RoundedRectangle(cornerRadius: isPadLike ? 26 : 22, style: .continuous)
            .fill(Color.white.opacity(0.72))
            .overlay(
                RoundedRectangle(cornerRadius: isPadLike ? 26 : 22, style: .continuous)
                    .stroke(AppColors.createSetSoftBorder, lineWidth: 1)
            )
    }
}

#Preview {
    let vm = CreateSetViewModel()
    vm.draft.selectedColor = AppColors.createSetBlue

    return CreateSetCustomizationSectionView(viewModel: vm)
        .padding()
        .background(AppColors.createSetBackground)
}
