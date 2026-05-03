import SwiftUI

struct CreateSetCardTextField: View {
    let title: String
    let placeholder: String
    let theme: CreateSetTheme
    var submitLabel: SubmitLabel = .done

    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.createSetCardsFieldSpacing) {
            CreateSetSectionLabel(text: title, theme: theme)

            HStack {
                ZStack(alignment: .leading) {
                    if text.isEmpty {
                        Text(placeholder)
                            .foregroundColor(theme.mutedTextColor.opacity(0.55))
                    }

                    TextField("", text: $text)
                        .foregroundColor(theme.textColor)
                        .tint(theme.accent)
                        .submitLabel(submitLabel)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }

                Image(systemName: "mic.fill")
                    .font(.system(size: Layout.createSetCardsMicIconSize, weight: .bold))
                    .foregroundStyle(theme.accent)
            }
            .font(.system(size: Layout.createSetCardsFieldFontSize, weight: .semibold))
            .padding(.horizontal, Layout.createSetCardsFieldHorizontalPadding)
            .frame(height: Layout.createSetCardsFieldHeight)
            .background(theme.fieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: Layout.createSetCardsFieldCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Layout.createSetCardsFieldCornerRadius, style: .continuous)
                    .stroke(theme.borderColor, lineWidth: 1)
            )
        }
    }
}

#Preview {
    CreateSetCardTextField(
        title: "Word",
        placeholder: "e.g. Hola",
        theme: .blue,
        submitLabel: .next,
        text: .constant("")
    )
    .padding()
    .background(CreateSetTheme.blue.screenBackground)
}
