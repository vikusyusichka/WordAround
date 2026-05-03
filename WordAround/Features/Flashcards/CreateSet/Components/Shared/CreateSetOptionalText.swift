import SwiftUI

struct CreateSetOptionalText: View {
    let theme: CreateSetTheme
    var fontSize: CGFloat = Layout.createSetOptionalTextSize

    var body: some View {
        Text("(optional)")
            .font(.system(size: fontSize, weight: .semibold))
            .foregroundStyle(theme.mutedTextColor)
    }
}

#Preview {
    CreateSetOptionalText(theme: .blue)
        .padding()
        .background(CreateSetTheme.blue.screenBackground)
}
