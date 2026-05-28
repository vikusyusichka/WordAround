import SwiftUI

struct WritingSetSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    @StateObject private var viewModel: WritingSetSelectionViewModel

    let onSelect: (FlashcardSet) -> Void

    @MainActor
    init(sets: [FlashcardSet], onSelect: @escaping (FlashcardSet) -> Void) {
        _viewModel = StateObject(wrappedValue: WritingSetSelectionViewModel(sets: sets))
        self.onSelect = onSelect
    }

    var body: some View {
        GeometryReader { proxy in
            let metrics = ScreenMetrics.current(
                horizontal: horizontalSizeClass,
                vertical: verticalSizeClass,
                containerWidth: proxy.size.width
            )

            ZStack {
                AppColors.appBackground
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        topBar(metrics)
                            .padding(.bottom, LayoutConstants.WritingSetSelection.headerBottomPadding(metrics))

                        if viewModel.isEmpty {
                            emptyState(metrics)
                        } else {
                            LazyVStack(spacing: LayoutConstants.WritingSetSelection.listSpacing(metrics)) {
                                ForEach(viewModel.items) { item in
                                    Button {
                                        onSelect(item.sourceSet)
                                        dismiss()
                                    } label: {
                                        WritingSetCardView(item: item, metrics: metrics)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .frame(
                        maxWidth: LayoutConstants.WritingSetSelection.contentMaxWidth(metrics),
                        alignment: .topLeading
                    )
                    .frame(maxWidth: .infinity, alignment: .top)
                    .padding(.horizontal, LayoutConstants.WritingSetSelection.horizontalPadding(metrics))
                    .padding(.top, LayoutConstants.WritingSetSelection.topPadding(metrics))
                    .padding(.bottom, LayoutConstants.WritingSetSelection.bottomPadding(metrics))
                }
            }
        }
        .presentationDetents([.fraction(0.68), .large])
        .presentationDragIndicator(.hidden)
    }

    private func topBar(_ metrics: ScreenMetrics) -> some View {
        ZStack {
            Text("Choose set")
                .font(.system(
                    size: LayoutConstants.WritingSetSelection.titleSize(metrics),
                    weight: .bold,
                    design: .rounded
                ))
                .foregroundColor(AppColors.primaryBlueDark)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .frame(maxWidth: .infinity)

            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(
                            size: LayoutConstants.WritingSetSelection.topBarIconSize(metrics),
                            weight: .bold
                        ))
                        .foregroundColor(AppColors.primaryBlueDark)
                        .frame(
                            width: LayoutConstants.WritingSetSelection.topBarButtonSize(metrics),
                            height: LayoutConstants.WritingSetSelection.topBarButtonSize(metrics)
                        )
                        .background(Color.white.opacity(0.86))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Spacer(minLength: 0)
            }
        }
    }

    private func emptyState(_ metrics: ScreenMetrics) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("No sets with words")
                .font(.system(
                    size: LayoutConstants.WritingSetSelection.emptyTitleSize(metrics),
                    weight: .bold,
                    design: .rounded
                ))
                .foregroundColor(AppColors.primaryBlueDark)

            Text("Create a set with at least one card before starting writing practice.")
                .font(.system(
                    size: LayoutConstants.WritingSetSelection.emptySubtitleSize(metrics),
                    weight: .medium,
                    design: .rounded
                ))
                .foregroundColor(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(LayoutConstants.WritingSetSelection.emptyPadding(metrics))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.92))
        .clipShape(
            RoundedRectangle(
                cornerRadius: LayoutConstants.WritingSetSelection.emptyCornerRadius(metrics),
                style: .continuous
            )
        )
        .shadow(color: Color.black.opacity(0.05), radius: 16, x: 0, y: 8)
    }
}

#Preview {
    WritingSetSelectionView(sets: [], onSelect: { _ in })
}
