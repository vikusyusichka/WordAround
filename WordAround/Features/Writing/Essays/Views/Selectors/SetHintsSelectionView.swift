import SwiftUI

struct EssaySetHintsSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    let set: FlashcardSet
    let items: [EssaySetHintItem]
    let selectedItems: [EssaySetHintItem]
    let onToggle: (EssaySetHintItem) -> Void
    let onDone: () -> Void

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

                        if items.isEmpty {
                            emptyState(metrics)
                        } else {
                            LazyVStack(spacing: LayoutConstants.WritingSetSelection.listSpacing(metrics)) {
                                ForEach(items) { item in
                                    EssaySetHintCardRowView(
                                        item: item,
                                        isSelected: selectedItems.contains { $0.id == item.id },
                                        metrics: metrics,
                                        onToggle: {
                                            onToggle(item)
                                        }
                                    )
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
        VStack(spacing: 10) {
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
                    .frame(maxWidth: .infinity, alignment: .center)

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

                    Button {
                        onDone()
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(.system(
                                size: LayoutConstants.WritingSetSelection.doneTextSize(metrics),
                                weight: .bold,
                                design: .rounded
                            ))
                            .foregroundColor(.white)
                            .padding(.horizontal, LayoutConstants.WritingSetSelection.doneHorizontalPadding(metrics))
                            .padding(.vertical, LayoutConstants.WritingSetSelection.doneVerticalPadding(metrics))
                            .background(AppColors.primaryBlue)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }

            Text("\(selectedItems.count) selected")
                .font(.system(
                    size: LayoutConstants.WritingSetSelection.subtitleBadgeSize(metrics),
                    weight: .bold,
                    design: .rounded
                ))
                .foregroundColor(AppColors.primaryBlue)
                .padding(.horizontal, LayoutConstants.WritingSetSelection.reviewHorizontalPadding(metrics))
                .padding(.vertical, LayoutConstants.WritingSetSelection.reviewVerticalPadding(metrics))
                .background(AppColors.primaryBlue.opacity(0.08))
                .clipShape(Capsule())
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(maxWidth: .infinity)
    }

    private func emptyState(_ metrics: ScreenMetrics) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("No words in this set")
                .font(.system(
                    size: LayoutConstants.WritingSetSelection.emptyTitleSize(metrics),
                    weight: .bold,
                    design: .rounded
                ))
                .foregroundColor(AppColors.primaryBlueDark)

            Text("Add cards to this set first.")
                .font(.system(
                    size: LayoutConstants.WritingSetSelection.emptySubtitleSize(metrics),
                    weight: .medium,
                    design: .rounded
                ))
                .foregroundColor(AppColors.textSecondary)
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
    EssaySetHintsSelectionView(
        set: FlashcardSet(
            id: UUID().uuidString,
            ownerUID: "preview-user",
            ownerEmail: "vika@example.com",
            title: "Spanish A1",
            description: "Basic daily words",
            privacy: "private",
            folderName: nil,
            colorHex: "#2F5BFF",
            icon: .systemName("star.fill"),
            cards: [],
            createdAt: Date(),
            updatedAt: Date()
        ),
        items: [
            EssaySetHintItem(
                id: UUID().uuidString,
                word: "Word",
                translation: "Translate",
                example: "FFFF",
                imageURL: nil
            ),
            EssaySetHintItem(
                id: UUID().uuidString,
                word: "Word 2",
                translation: "Translate 2",
                example: nil,
                imageURL: nil
            ),
            EssaySetHintItem(
                id: UUID().uuidString,
                word: "Word 3",
                translation: "Translate 3",
                example: nil,
                imageURL: nil
            )
        ],
        selectedItems: [
            EssaySetHintItem(
                id: UUID().uuidString,
                word: "Word",
                translation: "Translate",
                example: "FFFF",
                imageURL: nil
            )
        ],
        onToggle: { _ in },
        onDone: {}
    )
}
