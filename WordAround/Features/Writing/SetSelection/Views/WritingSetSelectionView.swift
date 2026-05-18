import SwiftUI

struct WritingSetSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: WritingSetSelectionViewModel

    let onSelect: (FlashcardSet) -> Void

    private var isPadLike: Bool {
        UIDevice.current.userInterfaceIdiom == .pad || UIScreen.main.bounds.width >= 700
    }

    init(sets: [FlashcardSet], onSelect: @escaping (FlashcardSet) -> Void) {
        _viewModel = StateObject(wrappedValue: WritingSetSelectionViewModel(sets: sets))
        self.onSelect = onSelect
    }

    var body: some View {
        ZStack {
            AppColors.appBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: Layout.homeContentSpacing) {
                    topBar
                        .padding(.bottom, isPadLike ? 10 : 4)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Choose set")
                            .font(.system(size: Layout.homePlaceholderTitleSize, weight: .bold, design: .rounded))
                            .foregroundColor(AppColors.primaryBlueDark)

                        Text("Select the set whose words you want to write.")
                            .font(.system(size: Layout.homePlaceholderSubtitleSize, weight: .medium, design: .rounded))
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .padding(.bottom, isPadLike ? 14 : 8)

                    if viewModel.isEmpty {
                        emptyState
                    } else {
                        LazyVStack(spacing: Layout.homeSetsListSpacing) {
                            ForEach(viewModel.items) { item in
                                Button {
                                    onSelect(item.sourceSet)
                                } label: {
                                    WritingSetCardView(item: item)
                                }
                                .buttonStyle(.plain)
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
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: Layout.flashcardDetailTopButtonIconSize, weight: .bold))
                    .foregroundColor(AppColors.primaryBlueDark)
                    .frame(width: Layout.flashcardDetailTopButtonSize, height: Layout.flashcardDetailTopButtonSize)
                    .background(Color.white.opacity(0.82))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Spacer()
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("No sets with words")
                .font(.system(size: Layout.homeEmptySetTitleSize, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.primaryBlueDark)

            Text("Create a set with at least one card before starting writing practice.")
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

#Preview {
    WritingSetSelectionView(sets: [], onSelect: { _ in })
}
