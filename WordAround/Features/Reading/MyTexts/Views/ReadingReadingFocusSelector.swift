import SwiftUI

struct ReadingReadingFocusSelector: View {
    @Binding var selection: String
    let accent: Color
    let accentDark: Color

    var body: some View {
        ReadingSetupSectionCard(title: L10n.string("readingFocusSection"), accentDark: accentDark) {
            ReadingSegmentedSelector(
                options: ReadingFocus.titles,
                selection: $selection,
                accent: accent,
                accentDark: accentDark,
                columns: Layout.isPadLike ? 2 : 1
            )
        }
    }
}
