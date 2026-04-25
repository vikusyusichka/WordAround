import SwiftUI

struct FlashcardSetDetailFilterTabsView: View {
    let theme: CreateSetTheme
    @Binding var selectedFilter: FlashcardSetDetailCardFilter
    let count: (FlashcardSetDetailCardFilter) -> Int

    var body: some View {
        HStack(spacing: 0) {
            ForEach(FlashcardSetDetailCardFilter.allCases) { filter in
                Button {
                    withAnimation(.easeInOut(duration: 0.22)) {
                        selectedFilter = filter
                    }
                } label: {
                    tabItem(filter)
                }
                .buttonStyle(.plain)

                if filter != FlashcardSetDetailCardFilter.allCases.last {
                    Rectangle()
                        .fill(theme.borderColor.opacity(0.4))
                        .frame(width: 1, height: Layout.flashcardDetailTabDividerHeight)
                }
            }
        }
        .frame(height: Layout.flashcardDetailTabsHeight)
        .background(theme.fieldBackground)
        .clipShape(RoundedRectangle(cornerRadius: Layout.flashcardDetailTabsCornerRadius, style: .continuous))
        .shadow(color: theme.shadowColor, radius: 12, x: 0, y: 6)
    }

    private func tabItem(_ filter: FlashcardSetDetailCardFilter) -> some View {
        VStack(spacing: Layout.flashcardDetailTabUnderlineSpacing) {
            HStack(spacing: Layout.flashcardDetailTabBadgeSpacing) {
                Text(filter.title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.56)

                Text("\(count(filter))")
                    .font(.system(
                        size: Layout.flashcardDetailTabBadgeTextSize,
                        weight: .bold,
                        design: .rounded
                    ))
                    .lineLimit(1)
                    .foregroundStyle(selectedFilter == filter ? theme.accent : theme.mutedTextColor)
                    .padding(.horizontal, Layout.flashcardDetailTabBadgeHorizontalPadding)
                    .padding(.vertical, Layout.flashcardDetailTabBadgeVerticalPadding)
                    .background(
                        Capsule()
                            .fill(selectedFilter == filter ? theme.accent.opacity(0.12) : theme.softAccent)
                    )
            }

            Capsule()
                .fill(selectedFilter == filter ? theme.accent : Color.clear)
                .frame(height: Layout.flashcardDetailTabUnderlineHeight)
                .padding(.horizontal, Layout.flashcardDetailTabUnderlineHorizontalPadding)
        }
        .font(.system(size: Layout.flashcardDetailTabTextSize, weight: .semibold, design: .rounded))
        .foregroundStyle(selectedFilter == filter ? theme.accent : theme.mutedTextColor)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, Layout.flashcardDetailTabHorizontalPadding)
    }
}

#Preview {
    ZStack {
        CreateSetTheme.yellow.screenBackground
            .ignoresSafeArea()

        FlashcardSetDetailFilterTabsView(
            theme: .yellow,
            selectedFilter: .constant(.all),
            count: { filter in
                switch filter {
                case .all: return 15
                case .studied: return 6
                case .remaining: return 9
                case .mastered: return 3
                }
            }
        )
        .padding(.horizontal, 20)
    }
}
