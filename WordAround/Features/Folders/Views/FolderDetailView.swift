import SwiftUI

struct FolderDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: FolderDetailViewModel

    @State private var selectedSetForDetails: FlashcardSet?
    @State private var isShowingEditFolderSheet = false

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

// MARK: - EditFolderSheet

private struct EditFolderSheet: View {
    @Environment(\.dismiss) private var dismiss

    let folder: Folder
    let theme: CreateSetTheme
    let isSaving: Bool
    let onSave: (String, String) async -> Bool

    @State private var title: String
    @State private var description: String
    @State private var validationMessage: String?

    init(
        folder: Folder,
        theme: CreateSetTheme,
        isSaving: Bool,
        onSave: @escaping (String, String) async -> Bool
    ) {
        self.folder = folder
        self.theme = theme
        self.isSaving = isSaving
        self.onSave = onSave

        _title = State(initialValue: folder.title)
        _description = State(initialValue: folder.description)
    }

    var body: some View {
        ZStack {
            theme.screenBackground
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 18) {
                sheetHeader

                VStack(alignment: .leading, spacing: 14) {
                    inputBlock(
                        title: "Folder name",
                        text: $title,
                        placeholder: "Spanish"
                    )

                    descriptionBlock
                }
                .padding(18)
                .background(theme.sectionBackground)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(theme.softBorderColor, lineWidth: 1)
                )
                .shadow(color: theme.shadowColor, radius: 18, x: 0, y: 10)

                if let validationMessage {
                    Text(validationMessage)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.red)
                }

                saveButton

                Spacer()
            }
            .padding(.horizontal, Layout.homeHorizontalPadding)
            .padding(.top, 24)
        }
    }

    private var sheetHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text("Edit folder")
                    .font(.system(size: Layout.isPadLike ? 30 : 26, weight: .bold, design: .rounded))
                    .foregroundColor(theme.titleColor)

                Text("Update the name and description.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(theme.mutedTextColor)
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(theme.titleColor)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.9))
                    .clipShape(Circle())
            }
        }
    }

    private func inputBlock(
        title: String,
        text: Binding<String>,
        placeholder: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(theme.titleColor)

            TextField(placeholder, text: text)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(theme.titleColor)
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(theme.fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(theme.softBorderColor, lineWidth: 1)
                )
        }
    }

    private var descriptionBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(theme.titleColor)

            TextEditor(text: $description)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(theme.titleColor)
                .scrollContentBackground(.hidden)
                .padding(10)
                .frame(height: 96)
                .background(theme.fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(theme.softBorderColor, lineWidth: 1)
                )
        }
    }

    private var saveButton: some View {
        Button {
            Task {
                let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

                guard !trimmedTitle.isEmpty else {
                    validationMessage = "Folder name cannot be empty."
                    return
                }

                validationMessage = nil

                let didSave = await onSave(title, description)

                if didSave {
                    dismiss()
                }
            }
        } label: {
            HStack(spacing: 8) {
                if isSaving {
                    ProgressView()
                        .tint(.white)
                }

                Text(isSaving ? "Saving..." : "Save changes")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(theme.accent)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: theme.shadowColor, radius: 16, x: 0, y: 8)
        }
        .disabled(isSaving)
        .opacity(isSaving ? 0.75 : 1)
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
