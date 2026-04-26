import SwiftUI

struct CreateSetInfoSectionView: View {
    @ObservedObject var viewModel: CreateSetViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.createSetInfoSectionSpacing) {
            titleField
            descriptionField
        }
        .padding(Layout.createSetSectionPadding)
        .background(sectionBackground)
    }

    private var titleField: some View {
        VStack(alignment: .leading, spacing: Layout.createSetSmallVerticalSpacing) {
            sectionLabel("Set title")

            ZStack(alignment: .leading) {
                if viewModel.draft.title.isEmpty {
                    Text("e.g. Basic Spanish Words")
                        .foregroundColor(viewModel.theme.mutedTextColor.opacity(0.55))
                }

                TextField("", text: $viewModel.draft.title)
                    // Фікс: не автокапіталізуємо, менше роботи для клавіатури
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    // Фікс: "next" замість "return" — клавіатура не закривається
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
                sectionLabel("Description")
                optionalText
            }

            ZStack(alignment: .bottomTrailing) {
                ZStack(alignment: .topLeading) {
                    if viewModel.draft.description.isEmpty {
                        Text("What is this set about?")
                            .foregroundColor(viewModel.theme.mutedTextColor.opacity(0.55))
                            .font(.system(
                                size: Layout.createSetDescriptionPlaceholderFontSize,
                                weight: .semibold
                            ))
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
                .clipShape(
                    RoundedRectangle(cornerRadius: Layout.createSetFolderCornerRadius, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Layout.createSetFolderCornerRadius, style: .continuous)
                        .stroke(viewModel.theme.borderColor, lineWidth: 1)
                )

                Text("\(viewModel.draft.description.count)/200")
                    .font(.system(size: Layout.createSetDescriptionCounterSize, weight: .semibold))
                    .foregroundStyle(
                        viewModel.draft.description.count > 200
                        ? Color.red
                        : viewModel.theme.mutedTextColor
                    )
                    .padding(.trailing, 14)
                    .padding(.bottom, 12)
            }
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: Layout.createSetSectionLabelSize, weight: .bold))
            .foregroundStyle(viewModel.theme.titleColor)
    }

    private var optionalText: some View {
        Text("(optional)")
            .font(.system(size: Layout.createSetOptionalTextSize, weight: .semibold))
            .foregroundStyle(viewModel.theme.mutedTextColor)
    }

    private var sectionBackground: some View {
        RoundedRectangle(cornerRadius: Layout.createSetSectionCornerRadius, style: .continuous)
            .fill(viewModel.theme.sectionBackground)
            .overlay(
                RoundedRectangle(cornerRadius: Layout.createSetSectionCornerRadius, style: .continuous)
                    .stroke(viewModel.theme.softBorderColor, lineWidth: 1)
            )
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
