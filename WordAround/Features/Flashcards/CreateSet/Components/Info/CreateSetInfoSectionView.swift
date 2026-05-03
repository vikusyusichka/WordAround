import SwiftUI

struct CreateSetInfoSectionView: View {
    @ObservedObject var viewModel: CreateSetViewModel

    var body: some View {
        CreateSetSectionContainer(theme: viewModel.theme) {
            VStack(alignment: .leading, spacing: Layout.createSetInfoSectionSpacing) {
                titleField
                descriptionField
            }
        }
    }

    private var titleField: some View {
        VStack(alignment: .leading, spacing: Layout.createSetSmallVerticalSpacing) {
            CreateSetSectionLabel(text: "Set title", theme: viewModel.theme)

            ZStack(alignment: .leading) {
                if viewModel.draft.title.isEmpty {
                    Text("e.g. Basic Spanish Words")
                        .foregroundColor(viewModel.theme.mutedTextColor.opacity(0.55))
                }

                TextField("", text: $viewModel.draft.title)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .submitLabel(.next)
            }
            .createSetFieldStyle(
                height: Layout.createSetTitleFieldHeight,
                fontSize: Layout.createSetTitleFieldFontSize,
                theme: viewModel.theme
            )
        }
    }

    private var descriptionField: some View {
        VStack(alignment: .leading, spacing: Layout.createSetSmallVerticalSpacing) {
            HStack(spacing: 4) {
                CreateSetSectionLabel(text: "Description", theme: viewModel.theme)
                CreateSetOptionalText(theme: viewModel.theme)
            }

            ZStack(alignment: .bottomTrailing) {
                descriptionTextField
                descriptionCounter
            }
        }
    }

    private var descriptionTextField: some View {
        ZStack(alignment: .topLeading) {
            if viewModel.draft.description.isEmpty {
                Text("What is this set about?")
                    .foregroundColor(viewModel.theme.mutedTextColor.opacity(0.55))
                    .font(.system(size: Layout.createSetDescriptionPlaceholderFontSize, weight: .semibold))
                    .padding(.top, 12)
                    .padding(.leading, 14)
            }

            TextField("", text: $viewModel.draft.description, axis: .vertical)
                .foregroundColor(viewModel.theme.textColor)
                .tint(viewModel.theme.accent)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .padding(.top, 12)
                .padding(.horizontal, 14)
                .padding(.bottom, 28)
                .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .frame(minHeight: Layout.createSetDescriptionMinHeight, alignment: .topLeading)
        .background(viewModel.theme.fieldBackground)
        .clipShape(RoundedRectangle(cornerRadius: Layout.createSetFolderCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Layout.createSetFolderCornerRadius, style: .continuous)
                .stroke(viewModel.theme.borderColor, lineWidth: 1)
        )
    }

    private var descriptionCounter: some View {
        Text("\(viewModel.draft.description.count)/200")
            .font(.system(size: Layout.createSetDescriptionCounterSize, weight: .semibold))
            .foregroundStyle(viewModel.draft.description.count > 200 ? Color.red : viewModel.theme.mutedTextColor)
            .padding(.trailing, 14)
            .padding(.bottom, 12)
    }
}

#Preview {
    let vm: CreateSetViewModel = {
        let vm = CreateSetViewModel()
        vm.draft.title = "Spanish Basics"
        vm.draft.description = "Simple words and phrases"
        vm.selectColor(.blue)
        return vm
    }()

    CreateSetInfoSectionView(viewModel: vm)
        .padding()
        .background(vm.theme.screenBackground)
}
