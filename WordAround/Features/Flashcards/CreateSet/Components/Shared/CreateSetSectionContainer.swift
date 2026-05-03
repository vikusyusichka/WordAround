import SwiftUI

struct CreateSetSectionContainer<Content: View>: View {
    let theme: CreateSetTheme
    let cornerRadius: CGFloat
    let padding: CGFloat
    let content: Content

    init(
        theme: CreateSetTheme,
        cornerRadius: CGFloat = Layout.createSetSectionCornerRadius,
        padding: CGFloat = Layout.createSetSectionPadding,
        @ViewBuilder content: () -> Content
    ) {
        self.theme = theme
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(theme.sectionBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(theme.softBorderColor, lineWidth: 1)
                    )
            )
    }
}

#Preview {
    CreateSetSectionContainer(theme: .blue) {
        Text("Content")
            .foregroundStyle(CreateSetTheme.blue.titleColor)
    }
    .padding()
    .background(CreateSetTheme.blue.screenBackground)
}
