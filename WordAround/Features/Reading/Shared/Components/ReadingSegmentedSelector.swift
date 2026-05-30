import SwiftUI

/// Renders a set of string options as themed pills and binds the selected one.
///
/// - `columns == 0` (default): a single horizontal row (good for short option
///   sets like levels / lengths).
/// - `columns > 0`: a wrapping grid with that many columns (good for longer
///   option sets like topics / sources).
struct ReadingSegmentedSelector: View {
    let options: [String]
    @Binding var selection: String
    var accent: Color
    var accentDark: Color
    var columns: Int = 0

    var body: some View {
        if columns <= 0 {
            HStack(spacing: Layout.convSetupGridSpacing) {
                ForEach(options, id: \.self) { pill($0) }
            }
        } else {
            LazyVGrid(columns: gridColumns, spacing: Layout.convSetupGridSpacing) {
                ForEach(options, id: \.self) { pill($0) }
            }
        }
    }

    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: Layout.convSetupGridSpacing), count: max(columns, 1))
    }

    private func pill(_ option: String) -> some View {
        ReadingOptionPill(
            title: option,
            isSelected: selection == option,
            accent: accent,
            accentDark: accentDark
        ) {
            withAnimation(.easeInOut(duration: 0.16)) { selection = option }
        }
    }
}

#Preview {
    ZStack {
        AppColors.appBackground.ignoresSafeArea()
        VStack(spacing: 16) {
            ReadingSegmentedSelector(
                options: ReadingLevel.titles,
                selection: .constant("B1"),
                accent: AppColors.primaryBlue,
                accentDark: AppColors.primaryBlueDark
            )
            ReadingSegmentedSelector(
                options: ReadingTopicOption.titles,
                selection: .constant("Random"),
                accent: AppColors.primaryBlue,
                accentDark: AppColors.primaryBlueDark,
                columns: 2
            )
        }
        .padding()
    }
}
