import SwiftUI

struct WritingView: View {
    @StateObject private var viewModel = WritingViewModel()

    var onOpenWriteSets: () -> Void = {}

    private var isPadLike: Bool {
        UIDevice.current.userInterfaceIdiom == .pad || UIScreen.main.bounds.width >= 700
    }

    var body: some View {
        VStack(alignment: .leading, spacing: isPadLike ? 24 : 18) {
            WritingGoalCardView(goal: viewModel.goal)

            VStack(spacing: isPadLike ? 16 : 12) {
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
        .frame(maxWidth: .infinity, alignment: .leading)
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
        ScrollView { WritingView().padding(24) }
    }
}
