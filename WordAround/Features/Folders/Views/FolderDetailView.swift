import SwiftUI

struct FolderDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: FolderDetailViewModel

    @State private var selectedSetForDetails: FlashcardSet?

    init(folder: Folder) {
        _viewModel = StateObject(wrappedValue: FolderDetailViewModel(folder: folder))
    }

    var body: some View {
        ZStack {
            AppColors.appBackground
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 18) {
                header

                if viewModel.isLoading {
                    placeholderCard(title: "Loading", subtitle: "Loading folder sets...")
                } else if let errorMessage = viewModel.errorMessage {
                    placeholderCard(title: "Error", subtitle: errorMessage)
                } else if viewModel.sets.isEmpty {
                    placeholderCard(title: "No sets", subtitle: "This folder does not contain any sets yet.")
                } else {
                    setsList
                }

                Spacer()
            }
            .padding(.horizontal, Layout.homeHorizontalPadding)
            .padding(.top, Layout.homeTopSpacing)
        }
        .task {
            await viewModel.loadSets()
        }
        .fullScreenCover(item: $selectedSetForDetails) { set in
            FlashcardSetDetailView(set: set)
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppColors.primaryBlue)
                    .frame(width: 38, height: 38)
                    .background(Color.white)
                    .clipShape(Circle())
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.folder.title)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: viewModel.folder.colorHex) ?? AppColors.primaryBlue)

                Text("\(viewModel.sets.count) sets")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer()
        }
    }

    private var setsList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: Layout.homeSetsListSpacing) {
                ForEach(viewModel.sets) { set in
                    Button {
                        selectedSetForDetails = set.sourceSet
                    } label: {
                        SetItemView(
                            title: set.title,
                            subtitle: set.subtitle,
                            iconSystemName: set.iconSystemName,
                            accentColor: set.accentColor,
                            titleColor: set.titleColor,
                            backgroundColor: set.backgroundColor,
                            trailingText: "Review",
                            blobColor: set.blobColor
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, Layout.homeScrollBottomPadding)
        }
    }

    private func placeholderCard(title: String, subtitle: String) -> some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(Color.white.opacity(0.92))
            .overlay(
                VStack(alignment: .leading, spacing: 10) {
                    Text(title)
                        .font(.system(size: Layout.homeEmptySetTitleSize, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.primaryBlueDark)

                    Text(subtitle)
                        .font(.system(size: Layout.homePlaceholderSubtitleSize, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                }
                .padding(Layout.homePlaceholderPadding),
                alignment: .topLeading
            )
            .frame(height: Layout.homeEmptySetHeight)
    }
}

#Preview {
    FolderDetailView(
        folder: Folder(
            id: "preview-folder-id",
            ownerUID: "preview-user-id",
            title: "Spanish",
            description: "A1 vocabulary and grammar",
            colorHex: "#4169F5",
            createdAt: Date(),
            updatedAt: Date()
        )
    )
}
