import SwiftUI

struct CreateSetCardExampleField: View {
    let theme: CreateSetTheme
    @Binding var example: String

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.createSetCardsFieldSpacing) {
            HStack(spacing: 4) {
                CreateSetSectionLabel(text: "Example", theme: theme)
                CreateSetOptionalText(theme: theme, fontSize: Layout.createSetCardsOptionalTextSize)
            }

            ZStack(alignment: .bottomTrailing) {
                ZStack(alignment: .topLeading) {
                    if example.isEmpty {
                        Text("e.g. Hola, ¿cómo estás?")
                            .foregroundColor(theme.mutedTextColor.opacity(0.55))
                            .padding(.top, 12)
                            .padding(.leading, 14)
                    }

                    TextField("", text: $example, axis: .vertical)
                        .foregroundColor(theme.textColor)
                        .tint(theme.accent)
                        .submitLabel(.done)
                        .padding(.top, 12)
                        .padding(.horizontal, 14)
                        .padding(.bottom, 26)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                }
                .frame(minHeight: Layout.createSetCardsExampleMinHeight, alignment: .topLeading)
                .background(theme.fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: Layout.createSetCardsFieldCornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Layout.createSetCardsFieldCornerRadius, style: .continuous)
                        .stroke(theme.borderColor, lineWidth: 1)
                )

                Text("\(example.count)/150")
                    .font(.system(size: Layout.createSetCardsCounterSize, weight: .semibold))
                    .foregroundStyle(example.count > 150 ? Color.red : theme.mutedTextColor)
                    .padding(.trailing, 14)
                    .padding(.bottom, 10)
            }
        }
    }
}

#Preview {
    CreateSetCardExampleField(theme: .blue, example: .constant("Hola, ¿cómo estás?"))
        .padding()
        .background(CreateSetTheme.blue.screenBackground)
}
