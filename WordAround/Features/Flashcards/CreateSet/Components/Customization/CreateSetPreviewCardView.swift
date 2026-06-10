import SwiftUI

struct CreateSetPreviewCardView: View {
    @ObservedObject var viewModel: CreateSetViewModel

    @State private var isSymbolPickerPresented = false

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.createSetPreviewSectionSpacing) {
            sectionLabel(L10n.string("commonPreview"))

            HStack(spacing: Layout.createSetPreviewCardSpacing) {
                iconView

                VStack(alignment: .leading, spacing: Layout.createSetPreviewTitleStackSpacing) {
                    Text(viewModel.draft.title.isEmpty ? L10n.string("setsListNewSet") : viewModel.draft.title)
                        .font(.system(
                            size: Layout.createSetPreviewTitleSize,
                            weight: .bold,
                            design: .rounded
                        ))
                        .foregroundStyle(viewModel.theme.titleColor)
                        .lineLimit(1)

                    Text(L10n.cardsCount(viewModel.draft.cards.count))
                        .font(.system(size: Layout.createSetPreviewSubtitleSize, weight: .semibold))
                        .foregroundStyle(viewModel.theme.mutedTextColor)
                }

                Spacer()
            }
            .padding(Layout.createSetPreviewPadding)
            .background(
                RoundedRectangle(
                    cornerRadius: Layout.createSetPreviewCornerRadius,
                    style: .continuous
                )
                .fill(viewModel.theme.previewBackground)
            )
            .shadow(color: viewModel.theme.shadowColor, radius: 12, x: 0, y: 6)
        }
    }

    private var iconView: some View {
        Button {
            isSymbolPickerPresented = true
        } label: {
            ZStack {
                Circle()
                    .fill(viewModel.theme.softAccent)
                    .frame(
                        width: Layout.createSetPreviewIconCircleSize,
                        height: Layout.createSetPreviewIconCircleSize
                    )

                Image(systemName: viewModel.draft.selectedIcon)
                    .font(.system(size: Layout.createSetPreviewIconSize, weight: .bold))
                    .foregroundStyle(viewModel.theme.accent)
            }
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $isSymbolPickerPresented) {
            SFSymbolPickerView(
                selectedSymbol: $viewModel.draft.selectedIcon,
                theme: viewModel.theme
            )
            .presentationDetents([.medium, .large])
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: Layout.createSetSectionLabelSize, weight: .bold))
            .foregroundStyle(viewModel.theme.titleColor)
    }
}

#Preview("Create Set Preview Card") {
    let vm: CreateSetViewModel = {
        let vm = CreateSetViewModel()
        vm.draft.title = "French B1"
        vm.draft.cards = [
            CreateFlashcardDraft(),
            CreateFlashcardDraft()
        ]
        vm.draft.selectedIcon = "book.closed.fill"
        vm.selectColor(.blue)
        return vm
    }()

    CreateSetPreviewCardView(viewModel: vm)
        .padding()
        .background(vm.theme.screenBackground)
}
