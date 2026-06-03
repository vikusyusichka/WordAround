import SwiftUI

struct SetsListScreen: View {
    @ObservedObject var viewModel: SetsListViewModel

    let onCreate: () -> Void
    let onSelect: (HomeSetPreviewItem) -> Void

    var body: some View {
        SetsListView(
            title: "Your sets",
            actionTitle: "Create",
            sets: viewModel.userSets,
            isLoading: viewModel.isLoadingSets,
            errorMessage: viewModel.errorMessage,
            showsEditButton: true,
            onAction: onCreate,
            onSelect: onSelect,
            onDelete: { set in
                await viewModel.deleteSet(set)
            },
            onMove: { source, destination in
                viewModel.moveSets(from: source, to: destination)
            },
            onUpdate: { set, title, description in
                await viewModel.updateSet(set, title: title, description: description)
            },
            showsLayoutToggle: true
        )
    }
}

#Preview {
    SetsListScreen(
        viewModel: SetsListViewModel(),
        onCreate: {},
        onSelect: { _ in }
    )
    .padding()
    .background(AppColors.appBackground)
}
