import SwiftUI

struct FolderDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: FolderDetailViewModel

    @State private var selectedSetForDetails: FlashcardSet?
    @State private var isShowingEditFolderSheet = false

    @MainActor
    init(folder: Folder) {
        _viewModel = StateObject(wrappedValue: FolderDetailViewModel(folder: folder))
    }

    var body: some View {
        ZStack {
            theme.screenBackground
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 18) {
                header

                if viewModel.isLoading {
                    placeholderCard(title: L10n.string("homeLoadingTitle"), subtitle: L10n.string("folderLoadingSets"))
                } else if let errorMessage = viewModel.errorMessage {
                    placeholderCard(title: L10n.string("commonError"), subtitle: errorMessage)
                } else if viewModel.sets.isEmpty {
                    placeholderCard(title: L10n.string("folderNoSets"), subtitle: L10n.string("folderEmptySubtitle"))
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
            FlashcardSetDetailView(
                set: set,
                onSetChanged: { updatedSet in
                    viewModel.applyUpdatedSet(updatedSet)
                    selectedSetForDetails = updatedSet
                }
            )
        }
        .sheet(isPresented: $isShowingEditFolderSheet) {
            EditFolderSheet(
                folder: viewModel.folder,
                theme: theme,
                isSaving: viewModel.isSavingFolder
            ) { title, description in
                await viewModel.updateFolder(
                    title: title,
                    description: description
                )
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }

    private var theme: CreateSetTheme {
        CreateSetTheme.theme(forHex: viewModel.folder.colorHex)
    }

    private var folderColor: Color {
        Color(hex: viewModel.folder.colorHex) ?? theme.accent
    }

    private var header: some View {
        HStack(spacing: 14) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(folderColor)
                    .frame(width: 38, height: 38)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: theme.shadowColor, radius: 12, x: 0, y: 6)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.folder.title)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(folderColor)

                if !viewModel.folder.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(viewModel.folder.description)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(theme.mutedTextColor)
                        .lineLimit(1)
                } else {
                    Text("\(viewModel.sets.count) sets")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(theme.mutedTextColor)
                }
            }

            Spacer()

            Button {
                isShowingEditFolderSheet = true
            } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(folderColor)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.92))
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(theme.softBorderColor, lineWidth: 1)
                    )
                    .shadow(color: theme.shadowColor, radius: 12, x: 0, y: 6)
            }
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
                            trailingText: L10n.string("commonReview"),
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
            .fill(theme.sectionBackground)
            .overlay(
                VStack(alignment: .leading, spacing: 10) {
                    Text(title)
                        .font(.system(size: Layout.homeEmptySetTitleSize, weight: .bold, design: .rounded))
                        .foregroundColor(theme.titleColor)

                    Text(subtitle)
                        .font(.system(size: Layout.homePlaceholderSubtitleSize, weight: .medium, design: .rounded))
                        .foregroundColor(theme.mutedTextColor)
                }
                .padding(Layout.homePlaceholderPadding),
                alignment: .topLeading
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(theme.softBorderColor, lineWidth: 1)
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
