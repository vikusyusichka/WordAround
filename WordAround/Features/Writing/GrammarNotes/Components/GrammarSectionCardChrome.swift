import SwiftUI

/// Centralises the `clipShape(RoundedRectangle 26) + shadow(theme.shadowColor,
/// radius 14, y 8)` envelope used by every `loadingCard` / `errorCard` /
/// `emptyState` card across `GrammarNotesHomeView` and `GrammarNotesTopicView`
/// (6 sites total).
///
/// Backgrounds intentionally stay at the call site — Home uses a stroked
/// `RoundedRectangle`, Topic uses a flat `theme.sectionBackground` color. The
/// modifier only owns the parts that are byte-equivalent across all 6 sites.
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
