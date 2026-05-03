import SwiftUI

struct CreateSetCustomizationSectionView: View {
    @ObservedObject var viewModel: CreateSetViewModel

    var body: some View {
        CreateSetSectionContainer(theme: viewModel.theme) {
            VStack(alignment: .leading, spacing: Layout.createSetCustomizationSectionSpacing) {
                CreateSetFolderPickerView(
                    theme: viewModel.theme,
                    folders: viewModel.folders,
                    selectedFolderName: viewModel.draft.folderName,
                    isLoading: viewModel.isLoadingFolders,
                    onSelectFolder: viewModel.selectFolder
                )

                CreateSetColorPickerView(
                    theme: viewModel.theme,
                    colors: viewModel.availableColors,
                    selectedColor: viewModel.draft.selectedColor,
                    onSelectColor: viewModel.selectColor
                )
            }
        }
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
