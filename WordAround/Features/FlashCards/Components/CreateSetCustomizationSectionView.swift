import SwiftUI

struct CreateSetCustomizationSectionView: View {
    @ObservedObject var viewModel: CreateSetViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.createSetCustomizationSectionSpacing) {
            folderPicker
            colorPicker
        }
        .padding(Layout.createSetSectionPadding)
        .background(sectionBackground)
    }

    private var folderPicker: some View {
        VStack(alignment: .leading, spacing: Layout.isPadLike ? 12 : 10) {
            Text("Choose folder")
                .font(.system(size: Layout.isPadLike ? 18 : 16, weight: .bold, design: .rounded))
                .foregroundColor(viewModel.theme.titleColor)

            Menu {
                Button {
                    viewModel.selectFolder(nil)
                } label: {
                    Label("No folder", systemImage: "folder")
                }

                ForEach(viewModel.folders) { folder in
                    Button {
                        viewModel.selectFolder(folder)
                    } label: {
                        Label(folder.title, systemImage: "folder.fill")
                    }
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "folder.fill")
                        .font(.system(size: Layout.isPadLike ? 22 : 19, weight: .semibold))
                        .foregroundColor(viewModel.theme.mutedTextColor)

                    Text(viewModel.draft.folderName ?? "No folder")
                        .font(.system(size: Layout.isPadLike ? 18 : 16, weight: .semibold, design: .rounded))
                        .foregroundColor(viewModel.theme.mutedTextColor)

                    Spacer()

                    if viewModel.isLoadingFolders {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "chevron.down")
                            .font(.system(size: Layout.isPadLike ? 17 : 15, weight: .bold))
                            .foregroundColor(viewModel.theme.mutedTextColor)
                    }
                }
                .padding(.horizontal, Layout.isPadLike ? 18 : 14)
                .frame(height: Layout.isPadLike ? 64 : 56)
                .background(viewModel.theme.fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: Layout.isPadLike ? 20 : 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Layout.isPadLike ? 20 : 16, style: .continuous)
                        .stroke(viewModel.theme.softBorderColor, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isLoadingFolders)
        }
    }

    private var colorPicker: some View {
        VStack(alignment: .leading, spacing: Layout.createSetColorPickerSpacing) {
            sectionLabel("Choose color")

            HStack {
                ForEach(viewModel.availableColors) { setColor in
                    Button {
                        viewModel.selectColor(setColor)
                    } label: {
                        Circle()
                            .fill(setColor.color.opacity(0.75))
                            .frame(
                                width: Layout.createSetColorCircleSize,
                                height: Layout.createSetColorCircleSize
                            )
                            .overlay {
                                if viewModel.draft.selectedColor == setColor {
                                    Circle()
                                        .stroke(
                                            Color.white,
                                            lineWidth: Layout.createSetSelectedColorStrokeWidth
                                        )

                                    Circle()
                                        .stroke(setColor.color, lineWidth: 2)
                                        .frame(
                                            width: Layout.createSetSelectedColorOuterCircleSize,
                                            height: Layout.createSetSelectedColorOuterCircleSize
                                        )
                                }
                            }
                    }
                    .buttonStyle(.plain)

                    if setColor != viewModel.availableColors.last {
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, Layout.createSetColorPickerHorizontalPadding)
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: Layout.createSetSectionLabelSize, weight: .bold))
            .foregroundStyle(viewModel.theme.titleColor)
    }

    private var sectionBackground: some View {
        RoundedRectangle(
            cornerRadius: Layout.createSetSectionCornerRadius,
            style: .continuous
        )
        .fill(viewModel.theme.sectionBackground)
        .overlay(
            RoundedRectangle(
                cornerRadius: Layout.createSetSectionCornerRadius,
                style: .continuous
            )
            .stroke(viewModel.theme.softBorderColor, lineWidth: 1)
        )
    }
}

#Preview {
    let vm: CreateSetViewModel = {
        let vm = CreateSetViewModel()
        vm.selectColor(.blue)
        return vm
    }()

    CreateSetCustomizationSectionView(viewModel: vm)
        .padding()
        .background(vm.theme.screenBackground)
}
