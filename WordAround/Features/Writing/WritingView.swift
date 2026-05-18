import SwiftUI

struct WritingView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @StateObject private var viewModel = WritingViewModel()

    var onOpenWriteSets: () -> Void = {}

    private var metrics: ScreenMetrics {
        ScreenMetrics.current(horizontal: horizontalSizeClass, vertical: verticalSizeClass)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: LayoutConstants.Common.sectionSpacing(metrics)) {
            header

            WritingGoalCardView(goal: viewModel.goal)

            VStack(spacing: LayoutConstants.Common.itemSpacing(metrics)) {
                ForEach(viewModel.menuItems) { item in
                    Button {
                        handle(item.action)
                    } label: {
                        WritingMenuCardView(item: item)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: LayoutConstants.Writing.contentMaxWidth(metrics), alignment: .leading)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: LayoutConstants.Writing.headerSpacing(metrics)) {
            Text("Writing")
                .font(.system(size: LayoutConstants.Typography.writingTitle(metrics), weight: .bold, design: .rounded))
                .foregroundColor(AppColors.primaryBlueDark)

            Text("Practice your language actively.")
                .font(.system(size: LayoutConstants.Typography.body(metrics), weight: .medium, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(.top, LayoutConstants.Writing.topPadding(metrics))
    }

    private func handle(_ action: WritingMenuAction) {
        switch action {
        case .writeFromSets:
            onOpenWriteSets()
        case .essays, .grammarNotes:
            break
        }
    }
}

#Preview {
    ZStack {
        AppColors.appBackground.ignoresSafeArea()
        ScrollView { WritingView().padding(LayoutConstants.Common.screenHorizontalPadding(.current(horizontal: .regular, vertical: .regular))) }
    }
}
