import SwiftUI
import PhotosUI

struct CreateSetCardEditorView: View {
    @Binding var card: CreateFlashcardDraft
    let theme: CreateSetTheme
    let onPickImage: (UUID, PhotosPickerItem) -> Void

    var body: some View {
        if Layout.isPadLike {
            padLayout
        } else {
            phoneLayout
        }
    }

    private var padLayout: some View {
        VStack(alignment: .leading, spacing: Layout.createSetCardsEditorPhoneSpacing) {
            HStack(alignment: .top, spacing: Layout.createSetCardsEditorPadSpacing) {
                VStack(spacing: Layout.createSetCardsInputStackSpacing) {
                    wordField
                    translationField
                }

                imagePicker
            }

            exampleField
        }
    }

    private var phoneLayout: some View {
        VStack(alignment: .leading, spacing: Layout.createSetCardsEditorPhoneSpacing) {
            HStack(alignment: .top, spacing: Layout.createSetCardsPhoneInputImageSpacing) {
                VStack(spacing: Layout.createSetCardsInputStackSpacing) {
                    wordField
                    translationField
                }
                .frame(maxWidth: .infinity)

                imagePicker
                    .frame(width: Layout.createSetCardsImagePhoneWidth)
            }

            exampleField
        }
    }

    private var wordField: some View {
        CreateSetCardTextField(
            title: "Word",
            placeholder: "e.g. Hola",
            theme: theme,
            submitLabel: .next,
            text: $card.word
        )
    }

    private var translationField: some View {
        CreateSetCardTextField(
            title: "Translation",
            placeholder: "e.g. Hello",
            theme: theme,
            submitLabel: .next,
            text: $card.translation
        )
    }

    private var exampleField: some View {
        CreateSetCardExampleField(theme: theme, example: $card.example)
    }

    private var imagePicker: some View {
        CreateSetImagePickerView(theme: theme, image: card.selectedImage) { item in
            onPickImage(card.id, item)
        }
    }
}

#Preview {
    CreateSetCardEditorView(
        card: .constant(CreateFlashcardDraft(word: "Hola", translation: "Hello", example: "Hola, ¿cómo estás?")),
        theme: .blue,
        onPickImage: { _, _ in }
    )
    .padding()
    .background(CreateSetTheme.blue.screenBackground)
}
