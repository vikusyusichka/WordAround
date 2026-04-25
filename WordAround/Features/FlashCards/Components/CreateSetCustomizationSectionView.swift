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
        VStack(alignment: .leading, spacing: Layout.createSetSmallVerticalSpacing) {
            sectionLabel("Choose folder")

            HStack {
                Image(systemName: "folder.fill")
                    .foregroundStyle(viewModel.theme.mutedTextColor)

                Text(viewModel.draft.folderName ?? "No folder")
                    .font(.system(size: Layout.createSetFolderTextSize, weight: .semibold))
                    .foregroundStyle(viewModel.theme.mutedTextColor)

                Spacer()

                Image(systemName: "chevron.down")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(viewModel.theme.mutedTextColor)
            }
            .padding(.horizontal, 14)
            .frame(height: Layout.createSetFolderHeight)
            .background(viewModel.theme.fieldBackground)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: Layout.createSetFolderCornerRadius,
                    style: .continuous
                )
            )
            .overlay(
                RoundedRectangle(
                    cornerRadius: Layout.createSetFolderCornerRadius,
                    style: .continuous
                )
                .stroke(viewModel.theme.borderColor, lineWidth: 1)
            )
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
