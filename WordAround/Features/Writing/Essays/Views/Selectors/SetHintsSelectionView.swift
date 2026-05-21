import SwiftUI

struct EssaySetHintsSelectionView: View {
    @Environment(\.dismiss) private var dismiss

    let set: FlashcardSet
    let items: [EssaySetHintItem]
    let selectedItems: [EssaySetHintItem]
    let onToggle: (EssaySetHintItem) -> Void
    let onDone: () -> Void

    private var isPadLike: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    var body: some View {
        ZStack {
            AppColors.appBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: Layout.homeContentSpacing) {
                    topBar
                        .padding(.bottom, isPadLike ? 10 : 4)

                    header

                    if items.isEmpty {
                        emptyState
                    } else {
                        LazyVStack(spacing: Layout.homeSetsListSpacing) {
                            ForEach(items) { item in
                                EssaySetHintCardRowView(
                                    item: item,
                                    isSelected: selectedItems.contains { $0.id == item.id },
                                    onToggle: {
                                        onToggle(item)
                                    }
                                )
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Layout.homeHorizontalPadding)
                .padding(.top, Layout.homeTopSpacing)
                .padding(.bottom, Layout.homeBottomSafeSpacing)
            }
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: Layout.flashcardDetailTopButtonIconSize, weight: .bold))
                    .foregroundColor(AppColors.primaryBlueDark)
                    .frame(width: Layout.flashcardDetailTopButtonSize, height: Layout.flashcardDetailTopButtonSize)
                    .background(Color.white.opacity(0.82))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                onDone()
                dismiss()
            } label: {
                Text("Done")
                    .font(.system(size: Layout.essayButtonTextSize, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(AppColors.primaryBlue)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Text("Choose set")
                .font(.system(size: isPadLike ? 30 : 26, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.primaryBlueDark)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .center)

            Text("\(selectedItems.count) selected")
                .font(.system(size: Layout.essayHintsBadgeTextSize, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.primaryBlue)
                .padding(.horizontal, Layout.essayHintsBadgeHorizontalPadding)
                .padding(.vertical, Layout.essayHintsBadgeVerticalPadding)
                .background(AppColors.primaryBlue.opacity(0.08))
                .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, isPadLike ? 14 : 8)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("No words in this set")
                .font(.system(size: Layout.homeEmptySetTitleSize, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.primaryBlueDark)

            Text("Add cards to this set first.")
                .font(.system(size: Layout.homePlaceholderSubtitleSize, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(Layout.homePlaceholderPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: Layout.setItemCornerRadius, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 16, x: 0, y: 8)
    }
}
