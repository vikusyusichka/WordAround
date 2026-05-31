import SwiftUI

struct ReadingImportSourceSelector: View {
    @Binding var selection: String
    let accent: Color
    let accentDark: Color

    var body: some View {
        ReadingSetupSectionCard(title: "Input source", accentDark: accentDark) {
            ReadingSegmentedSelector(
                options: ReadingTextImportSource.segmentTitles,
                selection: $selection,
                accent: accent,
                accentDark: accentDark,
                columns: Layout.isPadLike ? 3 : 0
            )
        }
    }
}
