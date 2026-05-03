import SwiftUI
import PhotosUI

struct CreateSetCardsSectionView: View {
    @ObservedObject var viewModel: CreateSetViewModel

    var body: some View {
        CreateSetSectionContainer(
            theme: viewModel.theme,
            cornerRadius: Layout.createSetCardsSectionCornerRadius,
            padding: Layout.createSetCardsSectionPadding
        ) {
            VStack(alignment: .leading, spacing: Layout.createSetCardsSectionSpacing) {
                titleRow
                cardsList
                addCardButton
            }
        }
    }

    private var titleRow: some View {
        HStack(spacing: 6) {
            CreateSetSectionLabel(text: "Cards in this set", theme: viewModel.theme)

            Text("(\(viewModel.draft.cards.count))")
                .font(.system(size: Layout.createSetCardsTitleSize, weight: .bold))
                .foregroundStyle(viewModel.theme.mutedTextColor)
        }
    }

    private var cardsList: some View {
        ForEach($viewModel.draft.cards) { $card in
            CreateSetCardEditorView(card: $card, theme: viewModel.theme) { cardID, item in
                Task {
                    await viewModel.setImage(for: cardID, from: item)
                }
            }
        }
    }

    private var addCardButton: some View {
        Button {
            CreateSetKeyboard.dismiss()
            viewModel.addCard()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "plus")
                    .font(.system(size: Layout.createSetAddCardIconSize, weight: .medium))
                    .foregroundStyle(viewModel.theme.accent)
                    .frame(width: Layout.createSetAddCardIconFrame, height: Layout.createSetAddCardIconFrame)
                    .background(viewModel.theme.softAccent)
                    .clipShape(Circle())

                Text("Add another card")
                    .font(.system(size: Layout.createSetAddCardTextSize, weight: .bold))
                    .foregroundStyle(viewModel.theme.accent)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    let vm: CreateSetViewModel = {
        let vm = CreateSetViewModel()
        vm.selectColor(.blue)
        vm.draft.cards = [
            CreateFlashcardDraft(word: "Hola", translation: "Hello", example: "Hola, ¿cómo estás?"),
            CreateFlashcardDraft(word: "Gracias", translation: "Thank you", example: "Gracias por tu ayuda")
        ]
        return vm
    }()

    CreateSetCardsSectionView(viewModel: vm)
        .padding()
        .background(vm.theme.screenBackground)
}
