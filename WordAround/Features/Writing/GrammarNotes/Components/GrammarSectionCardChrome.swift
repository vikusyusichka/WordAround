import SwiftUI

extension View {
    func grammarSectionCardChrome(theme: CreateSetTheme) -> some View {
        modifier(GrammarSectionCardChromeModifier(theme: theme))
    }
}

private struct GrammarSectionCardChromeModifier: ViewModifier {
    let theme: CreateSetTheme

    func body(content: Content) -> some View {
        content
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .shadow(color: theme.shadowColor, radius: 14, x: 0, y: 8)
    }
}
