import SwiftUI

/// Quick "create a note" action — a compact horizontal card (chip → text →
/// chevron) so it reads as a dense, tappable row rather than a sparse tile.
struct HomeNoteCard: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Layout.homeDashboardCardPadding) {
                HomeDashboardIconChip(systemName: "square.and.pencil", accent: AppColors.notesAccent)

                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.string("homeNoteTitle"))
                        .font(.system(size: Layout.homeDashboardTitleSize, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.primaryBlueDark)
                        .lineLimit(1)

                    Text(L10n.string("homeNoteSubtitle"))
                        .font(.system(size: Layout.homeDashboardSubtitleSize, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 4)

                Image(systemName: "chevron.right")
                    .font(.system(size: Layout.homeDashboardChevronSize, weight: .bold))
                    .foregroundColor(AppColors.notesAccent.opacity(0.55))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(Layout.homeDashboardCardPadding)
            .homeDashboardSurface(accent: AppColors.notesAccent)
            .contentShape(RoundedRectangle(cornerRadius: Layout.homeDashboardCardCornerRadius, style: .continuous))
        }
        .buttonStyle(HomeCardPressStyle())
    }
}

#Preview {
    ZStack {
        AppColors.appBackground.ignoresSafeArea()
        HomeNoteCard(action: {})
            .frame(height: Layout.homeDashboardActionRowHeight)
            .padding()
    }
}
