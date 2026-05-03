import SwiftUI

struct CreateSetSectionLabel: View {
    let text: String
    let theme: CreateSetTheme

    var body: some View {
        Text(text)
            .font(.system(size: Layout.createSetSectionLabelSize, weight: .bold))
            .foregroundStyle(theme.titleColor)
    }
}

#Preview {
    CreateSetSectionLabel(text: "Set title", theme: .blue)
        .padding()
        .background(CreateSetTheme.blue.screenBackground)
}
